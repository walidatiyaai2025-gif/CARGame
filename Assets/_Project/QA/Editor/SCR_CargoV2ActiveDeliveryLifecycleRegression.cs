#if UNITY_EDITOR
using System;
using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.QA.EditorTools
{
    public static class SCR_CargoV2ActiveDeliveryLifecycleRegression
    {
        public static void ValidateOrThrow()
        {
            StringState active = StringState.Capture(SCR_ActiveDeliveryStore.ActiveDeliveryKey);
            StringState corrupt = StringState.Capture(SCR_ActiveDeliveryStore.CorruptBackupKey);
            StringState unsupported = StringState.Capture(SCR_ActiveDeliveryStore.UnsupportedBackupKey);
            try
            {
                PlayerPrefs.DeleteKey(SCR_ActiveDeliveryStore.ActiveDeliveryKey);
                ValidateState(false, 0, 1002f, "pre-pickup");
                ValidateState(true, 0, 1002f, "post-pickup");
                ValidateState(true, 1, 1060f, "checkpoint-1");
                ValidateState(true, 2, 1110f, "checkpoint-2");
                ValidateState(true, 3, 1155f, "checkpoint-3");
            }
            finally
            {
                active.Restore(SCR_ActiveDeliveryStore.ActiveDeliveryKey);
                corrupt.Restore(SCR_ActiveDeliveryStore.CorruptBackupKey);
                unsupported.Restore(SCR_ActiveDeliveryStore.UnsupportedBackupKey);
                PlayerPrefs.Save();
            }
        }

        private static void ValidateState(bool cargoLoaded, int checkpoint, float z, string label)
        {
            Vector3 position = new Vector3(1000f, 0.7f, z);
            Require(SCR_ActiveDeliveryStore.TrySave(
                    1,
                    CargoV2LogisticsCatalog.StarterTruckId,
                    position,
                    12f,
                    137f,
                    14f,
                    cargoLoaded,
                    checkpoint),
                $"{label} active delivery must save before process recreation.");

            // The store has no process-local cache: this load is the exact durable
            // boundary used after Android process recreation or scene reconstruction.
            Require(SCR_ActiveDeliveryStore.TryLoadAny(out SCR_ActiveDeliveryStore.Snapshot resumed),
                $"{label} must resume from persisted state.");
            Require(resumed.MissionId == 1 && resumed.TruckId == CargoV2LogisticsCatalog.StarterTruckId,
                $"{label} must preserve mission/truck identity.");
            Require(resumed.CargoLoaded == cargoLoaded && resumed.CheckpointIndex == checkpoint,
                $"{label} must preserve cargo/checkpoint ordering.");
            Require(Mathf.Abs(resumed.RemainingSeconds - 137f) < 0.01f && Mathf.Abs(resumed.Damage - 14f) < 0.01f,
                $"{label} must preserve timer/damage.");
            Require(Vector3.Distance(resumed.Position, position) < 0.01f,
                $"{label} must preserve safe truck position.");
        }

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
        }

        private readonly struct StringState
        {
            private readonly bool exists;
            private readonly string value;
            private StringState(bool exists, string value) { this.exists = exists; this.value = value; }
            public static StringState Capture(string key) => new StringState(PlayerPrefs.HasKey(key), PlayerPrefs.GetString(key, string.Empty));
            public void Restore(string key) { if (exists) PlayerPrefs.SetString(key, value); else PlayerPrefs.DeleteKey(key); }
        }
    }
}
#endif
