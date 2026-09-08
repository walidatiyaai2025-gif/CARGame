using System;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_ActiveDeliveryStore
    {
        public const string ActiveDeliveryKey = "cargo_v2_active_delivery_v1";
        public const string CorruptBackupKey = "cargo_v2_active_delivery_corrupt_v1";
        public const string UnsupportedBackupKey = "cargo_v2_active_delivery_unsupported_v1";
        public const int SchemaVersion = 1;
        private const int MaxCheckpointIndex = 3;
        private static readonly Vector3 MissionOrigin = new Vector3(1000f, 0f, 1000f);

        [Serializable]
        private sealed class SchemaProbe
        {
            public int schemaVersion;
        }

        [Serializable]
        private sealed class Payload
        {
            public int schemaVersion = SchemaVersion;
            public int missionId;
            public string truckId;
            public float x;
            public float y;
            public float z;
            public float yaw;
            public float remainingSeconds;
            public float damage;
            public bool cargoLoaded;
            public int checkpointIndex;
            public long savedUtcTicks;
        }

        public readonly struct Snapshot
        {
            public Snapshot(
                int missionId,
                string truckId,
                Vector3 position,
                float yaw,
                float remainingSeconds,
                float damage,
                bool cargoLoaded,
                int checkpointIndex,
                long savedUtcTicks)
            {
                MissionId = missionId;
                TruckId = truckId;
                Position = position;
                Yaw = yaw;
                RemainingSeconds = remainingSeconds;
                Damage = damage;
                CargoLoaded = cargoLoaded;
                CheckpointIndex = checkpointIndex;
                SavedUtcTicks = savedUtcTicks;
            }

            public int MissionId { get; }
            public string TruckId { get; }
            public Vector3 Position { get; }
            public float Yaw { get; }
            public float RemainingSeconds { get; }
            public float Damage { get; }
            public bool CargoLoaded { get; }
            public int CheckpointIndex { get; }
            public long SavedUtcTicks { get; }
        }

        public static bool HasActiveDelivery => PlayerPrefs.HasKey(ActiveDeliveryKey);

        public static bool TryLoadAny(out Snapshot snapshot)
        {
            return TryLoadInternal(0, false, out snapshot);
        }

        public static bool TryLoad(int missionId, out Snapshot snapshot)
        {
            return TryLoadInternal(missionId, true, out snapshot);
        }

        public static bool TrySave(
            int missionId,
            string truckId,
            Vector3 position,
            float yaw,
            float remainingSeconds,
            float damage,
            bool cargoLoaded,
            int checkpointIndex)
        {
            if (missionId < 1 || missionId > 20 || CargoV2LogisticsCatalog.GetTruck(truckId) == null ||
                !Finite(position.x) || !Finite(position.y) || !Finite(position.z) || !Finite(yaw) ||
                !Finite(remainingSeconds) || !Finite(damage) ||
                remainingSeconds < 0f || remainingSeconds > 3600f || damage < 0f || damage > 100f ||
                checkpointIndex < 0 || checkpointIndex > MaxCheckpointIndex ||
                (!cargoLoaded && checkpointIndex != 0) ||
                Vector3.Distance(position, MissionOrigin) > 650f)
            {
                return false;
            }

            var payload = new Payload
            {
                schemaVersion = SchemaVersion,
                missionId = missionId,
                truckId = truckId,
                x = position.x,
                y = position.y,
                z = position.z,
                yaw = NormalizeYaw(yaw),
                remainingSeconds = remainingSeconds,
                damage = damage,
                cargoLoaded = cargoLoaded,
                checkpointIndex = checkpointIndex,
                savedUtcTicks = DateTime.UtcNow.Ticks,
            };

            try
            {
                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;
                PlayerPrefs.SetString(ActiveDeliveryKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery save failed safely: {exception.Message}");
                return false;
            }
        }

        public static void Clear()
        {
            try
            {
                PlayerPrefs.DeleteKey(ActiveDeliveryKey);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery clear failed safely: {exception.Message}");
            }
        }

        private static bool TryLoadInternal(int expectedMissionId, bool requireMission, out Snapshot snapshot)
        {
            snapshot = default;
            if (!PlayerPrefs.HasKey(ActiveDeliveryKey)) return false;

            string json = string.Empty;
            try
            {
                json = PlayerPrefs.GetString(ActiveDeliveryKey, string.Empty);
                if (!TryReadSchema(json, out int schemaVersion))
                {
                    QuarantineAndClear(json, CorruptBackupKey, "malformed");
                    return false;
                }

                if (schemaVersion != SchemaVersion)
                {
                    QuarantineAndClear(json, UnsupportedBackupKey, $"unsupported schema {schemaVersion}");
                    return false;
                }

                Payload payload = JsonUtility.FromJson<Payload>(json);
                if (!Validate(payload))
                {
                    QuarantineAndClear(json, CorruptBackupKey, "impossible current-schema state");
                    return false;
                }

                if (requireMission && payload.missionId != expectedMissionId) return false;
                snapshot = new Snapshot(
                    payload.missionId,
                    payload.truckId,
                    new Vector3(payload.x, payload.y, payload.z),
                    NormalizeYaw(payload.yaw),
                    payload.remainingSeconds,
                    payload.damage,
                    payload.cargoLoaded,
                    payload.checkpointIndex,
                    payload.savedUtcTicks);
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery read failed safely: {exception.Message}");
                QuarantineAndClear(json, CorruptBackupKey, "read failure");
                return false;
            }
        }

        private static bool Validate(Payload payload)
        {
            if (payload == null || payload.schemaVersion != SchemaVersion || payload.missionId < 1 || payload.missionId > 20) return false;
            if (CargoV2LogisticsCatalog.GetTruck(payload.truckId) == null) return false;
            if (!Finite(payload.x) || !Finite(payload.y) || !Finite(payload.z) || !Finite(payload.yaw) ||
                !Finite(payload.remainingSeconds) || !Finite(payload.damage)) return false;
            if (payload.remainingSeconds < 0f || payload.remainingSeconds > 3600f || payload.damage < 0f || payload.damage > 100f) return false;
            if (payload.checkpointIndex < 0 || payload.checkpointIndex > MaxCheckpointIndex) return false;
            if (!payload.cargoLoaded && payload.checkpointIndex != 0) return false;

            Vector3 position = new Vector3(payload.x, payload.y, payload.z);
            if (Vector3.Distance(position, MissionOrigin) > 650f) return false;
            if (payload.savedUtcTicks <= 0 || payload.savedUtcTicks > DateTime.MaxValue.Ticks) return false;
            return true;
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

        private static float NormalizeYaw(float value)
        {
            float yaw = value % 360f;
            return yaw < 0f ? yaw + 360f : yaw;
        }

        private static bool Finite(float value)
        {
            return !float.IsNaN(value) && !float.IsInfinity(value);
        }

        private static void QuarantineAndClear(string json, string backupKey, string reason)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(json)) PlayerPrefs.SetString(backupKey, json);
                PlayerPrefs.DeleteKey(ActiveDeliveryKey);
                PlayerPrefs.Save();
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery quarantined ({reason}); progression/economy remain untouched and the impossible run cannot resume.");
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery quarantine failed safely: {exception.Message}");
            }
        }
    }
}
