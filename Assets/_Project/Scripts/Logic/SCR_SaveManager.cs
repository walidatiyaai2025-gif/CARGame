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

        public const int CurrentSchemaVersion = 1;
        private const string ProgressKey = "cargo_v2.progress.v1";

        public ProgressPayload LoadProgress(int missionCount)
        {
            ProgressPayload fallback = CreateSafePayload(0, 1, missionCount);

            try
            {
                string raw = PlayerPrefs.GetString(ProgressKey, string.Empty);
                if (string.IsNullOrWhiteSpace(raw)) return fallback;

                ProgressPayload payload = JsonUtility.FromJson<ProgressPayload>(raw);
                if (payload == null || payload.schemaVersion != CurrentSchemaVersion)
                {
                    Debug.LogWarning("[CARGO V2][LOGIC_TEAM] Unsupported/corrupt progress payload; using safe defaults.");
                    return fallback;
                }

                return CreateSafePayload(
                    payload.highestCompletedMissionId,
                    payload.selectedMissionId,
                    missionCount);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Progress load failed safely: {exception.Message}");
                return fallback;
            }
        }

        public bool SaveProgress(int highestCompletedMissionId, int selectedMissionId, int missionCount)
        {
            try
            {
                ProgressPayload payload = CreateSafePayload(
                    highestCompletedMissionId,
                    selectedMissionId,
                    missionCount);
                string raw = JsonUtility.ToJson(payload);
                PlayerPrefs.SetString(ProgressKey, raw);
                PlayerPrefs.Save();
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
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Progress clear failed safely: {exception.Message}");
            }
        }

        private static ProgressPayload CreateSafePayload(
            int highestCompletedMissionId,
            int selectedMissionId,
            int missionCount)
        {
            int boundedCompleted = WorldMapProgression.ClampHighestCompleted(
                highestCompletedMissionId,
                missionCount);

            int boundedSelected = selectedMissionId;
            if (!WorldMapProgression.CanSelect(
                    boundedSelected,
                    boundedCompleted,
                    missionCount))
            {
                boundedSelected = WorldMapProgression.GetHighestUnlockedMissionId(
                    boundedCompleted,
                    missionCount);
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
