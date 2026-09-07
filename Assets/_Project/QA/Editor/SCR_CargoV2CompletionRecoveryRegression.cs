#if UNITY_EDITOR
using System;
using System.Reflection;
using CargoV2.Logic;
using UnityEditor;
using UnityEngine;

namespace CargoV2.QA.EditorTools
{
    /// <summary>
    /// Deterministic EditMode regression for the crash-return ordering boundary.
    /// It deliberately invokes completion before a persistence bridge exists, which
    /// reproduces the unsafe Unity Start ordering that previously allowed payout
    /// before the older progress snapshot was loaded.
    /// </summary>
    public static class SCR_CargoV2CompletionRecoveryRegression
    {
        private const string ProgressKey = "cargo_v2.progress.v1";
        private const string EconomyKey = "cargo_v2_mission_economy_v1";
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private const string CompletionStarsKey = "cargo_v2_completed_mission_stars";
        private const string CompletionDeliveryRunKey = "cargo_v2_completed_delivery_run_id";
        private const string ActiveDeliveryRunKey = "cargo_v2_active_delivery_run_id_v1";

        [MenuItem("CARGO V2/QA/Run Completion Recovery Ordering Regression")]
        public static void RunMenu()
        {
            ValidateOrThrow();
            Debug.Log("[CARGO V2][QA][EDITMODE][PASS] Completion recovery ordering regression passed.");
        }

        public static void ValidateOrThrow()
        {
            PrefSnapshot snapshot = PrefSnapshot.Capture();
            GameObject root = null;
            try
            {
                ClearScenarioKeys();
                root = new GameObject("CARGO_V2_EditMode_CompletionRecoveryRegression");
                SCR_SaveManager save = root.AddComponent<SCR_SaveManager>();
                SCR_WorldMapRouteController route = root.AddComponent<SCR_WorldMapRouteController>();
                SCR_MissionCompletionHandoffBridge completion =
                    root.AddComponent<SCR_MissionCompletionHandoffBridge>();

                if (route.MissionCount != 20)
                {
                    throw new InvalidOperationException($"Expected canonical 20-mission balance, got {route.MissionCount}.");
                }
                if (!save.SaveProgress(0, 1, route.MissionCount))
                {
                    throw new InvalidOperationException("Could not seed the pre-crash progress snapshot.");
                }

                string runId = Guid.NewGuid().ToString("N");
                SeedCompletion(runId);
                if (!InvokeConsume(completion))
                {
                    throw new InvalidOperationException("Crash-recovered completion handoff was not consumed.");
                }

                SCR_SaveManager.ProgressPayload progress = save.LoadProgress(route.MissionCount);
                if (progress.highestCompletedMissionId != 1 || progress.selectedMissionId != 2)
                {
                    throw new InvalidOperationException(
                        $"Completion paid without durable progression. Saved completed={progress.highestCompletedMissionId}, selected={progress.selectedMissionId}.");
                }
                if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot firstEconomy) ||
                    firstEconomy.Coins <= 0 || firstEconomy.Xp <= 0)
                {
                    throw new InvalidOperationException("Expected first delivery settlement was not persisted.");
                }
                if (PlayerPrefs.HasKey(CompletionHandoffKey))
                {
                    throw new InvalidOperationException("Successful completion handoff was not cleared.");
                }

                // Re-deliver the exact same handoff/run identity. Progress must stay
                // complete and economy must remain byte-for-byte idempotent.
                SeedCompletion(runId);
                if (!InvokeConsume(completion))
                {
                    throw new InvalidOperationException("Idempotent duplicate completion handoff was not consumed.");
                }
                if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot secondEconomy) ||
                    secondEconomy.Coins != firstEconomy.Coins || secondEconomy.Xp != firstEconomy.Xp)
                {
                    throw new InvalidOperationException("Duplicate delivery run changed economy totals.");
                }

                progress = save.LoadProgress(route.MissionCount);
                if (progress.highestCompletedMissionId != 1 || progress.selectedMissionId != 2)
                {
                    throw new InvalidOperationException("Duplicate recovery changed durable progression.");
                }
            }
            finally
            {
                if (root != null) UnityEngine.Object.DestroyImmediate(root);
                snapshot.Restore();
            }
        }

        private static bool InvokeConsume(SCR_MissionCompletionHandoffBridge completion)
        {
            MethodInfo consume = typeof(SCR_MissionCompletionHandoffBridge).GetMethod(
                "ConsumePendingHandoff",
                BindingFlags.Instance | BindingFlags.NonPublic);
            if (consume == null) throw new MissingMethodException("ConsumePendingHandoff");
            object value = consume.Invoke(completion, null);
            return value is bool accepted && accepted;
        }

        private static void SeedCompletion(string runId)
        {
            PlayerPrefs.SetInt(CompletionHandoffKey, 1);
            PlayerPrefs.SetInt(CompletionStarsKey, 1);
            PlayerPrefs.SetString(CompletionDeliveryRunKey, runId);
            PlayerPrefs.SetString(ActiveDeliveryRunKey, runId);
            PlayerPrefs.Save();
        }

        private static void ClearScenarioKeys()
        {
            PlayerPrefs.DeleteKey(ProgressKey);
            PlayerPrefs.DeleteKey(EconomyKey);
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.DeleteKey(CompletionDeliveryRunKey);
            PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);
            PlayerPrefs.Save();
        }

        private sealed class PrefSnapshot
        {
            private readonly StringState progress;
            private readonly StringState economy;
            private readonly IntState completion;
            private readonly IntState stars;
            private readonly StringState completionRun;
            private readonly StringState activeRun;

            private PrefSnapshot()
            {
                progress = StringState.Capture(ProgressKey);
                economy = StringState.Capture(EconomyKey);
                completion = IntState.Capture(CompletionHandoffKey);
                stars = IntState.Capture(CompletionStarsKey);
                completionRun = StringState.Capture(CompletionDeliveryRunKey);
                activeRun = StringState.Capture(ActiveDeliveryRunKey);
            }

            public static PrefSnapshot Capture() => new PrefSnapshot();

            public void Restore()
            {
                progress.Restore(ProgressKey);
                economy.Restore(EconomyKey);
                completion.Restore(CompletionHandoffKey);
                stars.Restore(CompletionStarsKey);
                completionRun.Restore(CompletionDeliveryRunKey);
                activeRun.Restore(ActiveDeliveryRunKey);
                PlayerPrefs.Save();
            }
        }

        private readonly struct StringState
        {
            private readonly bool exists;
            private readonly string value;

            private StringState(bool exists, string value)
            {
                this.exists = exists;
                this.value = value;
            }

            public static StringState Capture(string key) =>
                new StringState(PlayerPrefs.HasKey(key), PlayerPrefs.GetString(key, string.Empty));

            public void Restore(string key)
            {
                if (exists) PlayerPrefs.SetString(key, value);
                else PlayerPrefs.DeleteKey(key);
            }
        }

        private readonly struct IntState
        {
            private readonly bool exists;
            private readonly int value;

            private IntState(bool exists, int value)
            {
                this.exists = exists;
                this.value = value;
            }

            public static IntState Capture(string key) =>
                new IntState(PlayerPrefs.HasKey(key), PlayerPrefs.GetInt(key, 0));

            public void Restore(string key)
            {
                if (exists) PlayerPrefs.SetInt(key, value);
                else PlayerPrefs.DeleteKey(key);
            }
        }
    }
}
#endif
