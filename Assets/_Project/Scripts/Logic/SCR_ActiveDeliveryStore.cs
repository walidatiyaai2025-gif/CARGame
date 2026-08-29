using System;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_ActiveDeliveryStore
    {
        private const string ActiveDeliveryKey = "cargo_v2_active_delivery_v1";
        private const string CorruptBackupKey = "cargo_v2_active_delivery_corrupt_v1";
        private const int SchemaVersion = 1;
        private const int MaxCheckpointIndex = 3;
        private static readonly Vector3 MissionOrigin = new Vector3(1000f, 0f, 1000f);

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
                !Finite(remainingSeconds) || !Finite(damage) || checkpointIndex < 0 || checkpointIndex > MaxCheckpointIndex ||
                (!cargoLoaded && checkpointIndex != 0))
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
                yaw = yaw,
                remainingSeconds = Mathf.Clamp(remainingSeconds, 0f, 3600f),
                damage = Mathf.Clamp(damage, 0f, 100f),
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
                Payload payload = string.IsNullOrWhiteSpace(json) ? null : JsonUtility.FromJson<Payload>(json);
                if (!Validate(payload))
                {
                    BackupAndClear(json);
                    return false;
                }

                if (requireMission && payload.missionId != expectedMissionId) return false;
                snapshot = new Snapshot(
                    payload.missionId,
                    payload.truckId,
                    new Vector3(payload.x, payload.y, payload.z),
                    payload.yaw,
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
                BackupAndClear(json);
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
            if (payload.savedUtcTicks <= 0) return false;
            return true;
        }

        private static bool Finite(float value)
        {
            return !float.IsNaN(value) && !float.IsInfinity(value);
        }

        private static void BackupAndClear(string json)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(json)) PlayerPrefs.SetString(CorruptBackupKey, json);
                PlayerPrefs.DeleteKey(ActiveDeliveryKey);
                PlayerPrefs.Save();
                Debug.LogWarning("[CARGO V2][LOGIC] Invalid active delivery was quarantined to prevent a resume softlock.");
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Active delivery quarantine failed safely: {exception.Message}");
            }
        }
    }
}
