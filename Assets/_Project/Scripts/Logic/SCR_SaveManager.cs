using System;
using UnityEngine;

namespace CargoV2.Logic
{
    public sealed class SCR_SaveManager : MonoBehaviour
    {
        [Serializable]
        public sealed class ProgressPayload
        {
            public int schemaVersion = CurrentSchemaVersion;
            public int highestCompletedMissionId;
            public int selectedMissionId = 1;
        }

        [Serializable]
        private sealed class SchemaProbe
        {
            public int schemaVersion;
        }

        public enum ProgressLoadState
        {
            Fresh = 0,
            Current = 1,
            RecoveredBackup = 2,
            CorruptBlocked = 3,
            FutureSchemaBlocked = 4,
            UnsupportedLegacyBlocked = 5,
        }

        public const int CurrentSchemaVersion = 1;
        public const string ProgressKey = "cargo_v2.progress.v1";
        public const string ProgressBackupKey = "cargo_v2.progress.v1.lkg";
        public const string CorruptBackupKey = "cargo_v2.progress.v1.corrupt";

        public ProgressLoadState LastLoadState { get; private set; } = ProgressLoadState.Fresh;
        public bool CanPersistLoadedState =>
            LastLoadState == ProgressLoadState.Fresh ||
            LastLoadState == ProgressLoadState.Current ||
            LastLoadState == ProgressLoadState.RecoveredBackup;

        public ProgressPayload LoadProgress(int missionCount)
        {
            ProgressPayload fallback = CreateSafePayload(0, 1, missionCount);

            try
            {
                if (!PlayerPrefs.HasKey(ProgressKey))
                {
                    LastLoadState = ProgressLoadState.Fresh;
                    return fallback;
                }

                string raw = PlayerPrefs.GetString(ProgressKey, string.Empty);
                if (!TryReadSchema(raw, out int schemaVersion))
                {
                    PreserveCorrupt(raw);
                    if (TryLoadBackup(missionCount, out ProgressPayload recovered, out string backupRaw))
                    {
                        RestorePrimaryBestEffort(backupRaw);
                        LastLoadState = ProgressLoadState.RecoveredBackup;
                        return recovered;
                    }

                    LastLoadState = ProgressLoadState.CorruptBlocked;
                    Debug.LogWarning("[CARGO V2][LOGIC_TEAM] Progress is corrupt and no valid last-known-good snapshot exists; raw data is preserved and write-back is blocked.");
                    return fallback;
                }

                if (schemaVersion > CurrentSchemaVersion)
                {
                    LastLoadState = ProgressLoadState.FutureSchemaBlocked;
                    Debug.LogWarning(
                        $"[CARGO V2][LOGIC_TEAM] Progress schema {schemaVersion} is newer than supported {CurrentSchemaVersion}; preserving it untouched and blocking write-back.");
                    return fallback;
                }

                if (schemaVersion < CurrentSchemaVersion)
                {
                    LastLoadState = ProgressLoadState.UnsupportedLegacyBlocked;
                    Debug.LogWarning(
                        $"[CARGO V2][LOGIC_TEAM] Progress schema {schemaVersion} has no registered migration to {CurrentSchemaVersion}; preserving it untouched and blocking write-back.");
                    return fallback;
                }

                ProgressPayload payload = JsonUtility.FromJson<ProgressPayload>(raw);
                if (payload == null)
                {
                    PreserveCorrupt(raw);
                    if (TryLoadBackup(missionCount, out ProgressPayload recovered, out string backupRaw))
                    {
                        RestorePrimaryBestEffort(backupRaw);
                        LastLoadState = ProgressLoadState.RecoveredBackup;
                        return recovered;
                    }

                    LastLoadState = ProgressLoadState.CorruptBlocked;
                    return fallback;
                }

                LastLoadState = ProgressLoadState.Current;
                return CreateSafePayload(
                    payload.highestCompletedMissionId,
                    payload.selectedMissionId,
                    missionCount);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Progress load failed safely: {exception.Message}");
                string raw = SafeRead(ProgressKey);
                PreserveCorrupt(raw);
                if (TryLoadBackup(missionCount, out ProgressPayload recovered, out string backupRaw))
                {
                    RestorePrimaryBestEffort(backupRaw);
                    LastLoadState = ProgressLoadState.RecoveredBackup;
                    return recovered;
                }

                LastLoadState = ProgressLoadState.CorruptBlocked;
                return fallback;
            }
        }

        public bool SaveProgress(int highestCompletedMissionId, int selectedMissionId, int missionCount)
        {
            if (!CanPersistLoadedState) return false;

            try
            {
                ProgressPayload payload = CreateSafePayload(
                    highestCompletedMissionId,
                    selectedMissionId,
                    missionCount);
                string raw = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(raw)) return false;

                string currentRaw = SafeRead(ProgressKey);
                if (IsCurrentSchemaPayload(currentRaw))
                {
                    PlayerPrefs.SetString(ProgressBackupKey, currentRaw);
                    PlayerPrefs.Save();
                }
                else if (!PlayerPrefs.HasKey(ProgressBackupKey))
                {
                    PlayerPrefs.SetString(
                        ProgressBackupKey,
                        JsonUtility.ToJson(CreateSafePayload(0, 1, missionCount)));
                    PlayerPrefs.Save();
                }

                PlayerPrefs.SetString(ProgressKey, raw);
                PlayerPrefs.Save();
                PlayerPrefs.SetString(ProgressBackupKey, raw);
                PlayerPrefs.Save();
                LastLoadState = ProgressLoadState.Current;
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Progress save failed safely: {exception.Message}");
                return false;
            }
        }

        public void ClearProgress()
        {
            try
            {
                PlayerPrefs.DeleteKey(ProgressKey);
                PlayerPrefs.DeleteKey(ProgressBackupKey);
                PlayerPrefs.DeleteKey(CorruptBackupKey);
                PlayerPrefs.Save();
                LastLoadState = ProgressLoadState.Fresh;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Progress clear failed safely: {exception.Message}");
            }
        }

        private static bool TryLoadBackup(int missionCount, out ProgressPayload payload, out string raw)
        {
            payload = null;
            raw = SafeRead(ProgressBackupKey);
            if (!IsCurrentSchemaPayload(raw)) return false;

            try
            {
                ProgressPayload parsed = JsonUtility.FromJson<ProgressPayload>(raw);
                if (parsed == null) return false;
                payload = CreateSafePayload(parsed.highestCompletedMissionId, parsed.selectedMissionId, missionCount);
                return true;
            }
            catch (Exception)
            {
                payload = null;
                return false;
            }
        }

        private static bool IsCurrentSchemaPayload(string raw)
        {
            if (!TryReadSchema(raw, out int schemaVersion) || schemaVersion != CurrentSchemaVersion) return false;
            try { return JsonUtility.FromJson<ProgressPayload>(raw) != null; }
            catch (Exception) { return false; }
        }

        private static bool TryReadSchema(string raw, out int schemaVersion)
        {
            schemaVersion = 0;
            if (string.IsNullOrWhiteSpace(raw)) return false;
            try
            {
                SchemaProbe probe = JsonUtility.FromJson<SchemaProbe>(raw);
                if (probe == null) return false;
                schemaVersion = probe.schemaVersion;
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        private static string SafeRead(string key)
        {
            try { return PlayerPrefs.HasKey(key) ? PlayerPrefs.GetString(key, string.Empty) : string.Empty; }
            catch (Exception) { return string.Empty; }
        }

        private static void PreserveCorrupt(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            try
            {
                PlayerPrefs.SetString(CorruptBackupKey, raw);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Could not preserve corrupt progress payload: {exception.Message}");
            }
        }

        private static void RestorePrimaryBestEffort(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            try
            {
                PlayerPrefs.SetString(ProgressKey, raw);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Recovered progress is usable in memory but primary restore failed: {exception.Message}");
            }
        }

        private static ProgressPayload CreateSafePayload(
            int highestCompletedMissionId,
            int selectedMissionId,
            int missionCount)
        {
            int boundedCompleted = WorldMapProgression.ClampHighestCompleted(highestCompletedMissionId, missionCount);
            int boundedSelected = selectedMissionId;
            if (!WorldMapProgression.CanSelect(boundedSelected, boundedCompleted, missionCount))
            {
                boundedSelected = WorldMapProgression.GetHighestUnlockedMissionId(boundedCompleted, missionCount);
            }
            if (missionCount <= 0) boundedSelected = 0;

            return new ProgressPayload
            {
                schemaVersion = CurrentSchemaVersion,
                highestCompletedMissionId = boundedCompleted,
                selectedMissionId = boundedSelected,
            };
        }
    }
}
