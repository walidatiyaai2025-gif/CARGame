using System;
using System.Collections;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.QA
{
    /// <summary>
    /// Opt-in PlayMode regression. Set CARGO_V2_RUN_COMPLETION_RECOVERY_PROBE=1
    /// before launching PlayMode. The probe creates completion before persistence,
    /// lets Unity invoke Start on the next frame, and verifies durable progression
    /// is committed before settlement. Normal player/editor sessions are untouched.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class SCR_CargoV2CompletionRecoveryPlayModeProbe : MonoBehaviour
    {
        private const string ProbeEnvironment = "CARGO_V2_RUN_COMPLETION_RECOVERY_PROBE";
        private const string ProgressKey = "cargo_v2.progress.v1";
        private const string EconomyKey = "cargo_v2_mission_economy_v1";
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private const string CompletionStarsKey = "cargo_v2_completed_mission_stars";
        private const string CompletionDeliveryRunKey = "cargo_v2_completed_delivery_run_id";
        private const string ActiveDeliveryRunKey = "cargo_v2_active_delivery_run_id_v1";

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void InstallOptInProbe()
        {
            if (!string.Equals(Environment.GetEnvironmentVariable(ProbeEnvironment), "1", StringComparison.Ordinal)) return;
            if (FindObjectOfType<SCR_CargoV2CompletionRecoveryPlayModeProbe>() != null) return;
            new GameObject("CARGO_V2_CompletionRecovery_PlayModeProbe")
                .AddComponent<SCR_CargoV2CompletionRecoveryPlayModeProbe>();
        }

        private IEnumerator Start()
        {
            PrefSnapshot snapshot = PrefSnapshot.Capture();
            GameObject root = null;
            try
            {
                if (FindObjectOfType<SCR_WorldMapRouteController>() != null)
                {
                    throw new InvalidOperationException(
                        "Completion recovery PlayMode probe requires a scene without an existing WorldMap controller (use Splash/Loading)."
                    );
                }

                ClearScenarioKeys();
                root = new GameObject("CARGO_V2_PlayMode_CompletionRecoveryScenario");
                SCR_SaveManager save = root.AddComponent<SCR_SaveManager>();
                SCR_WorldMapRouteController route = root.AddComponent<SCR_WorldMapRouteController>();

                if (!save.SaveProgress(0, 1, route.MissionCount))
                {
                    throw new InvalidOperationException("Could not seed PlayMode pre-crash progress.");
                }

                string runId = Guid.NewGuid().ToString("N");
                SeedCompletion(runId);

                // Completion exists first; no persistence bridge is manually added.
                // Yielding gives Unity the exact Start-order opportunity that caused
                // the historical reward-paid/progression-rollback race.
                root.AddComponent<SCR_MissionCompletionHandoffBridge>();
                yield return null;

                SCR_SaveManager.ProgressPayload progress = save.LoadProgress(route.MissionCount);
                if (progress.highestCompletedMissionId != 1 || progress.selectedMissionId != 2)
                {
                    throw new InvalidOperationException(
                        $"PlayMode completion did not durably advance progression: completed={progress.highestCompletedMissionId}, selected={progress.selectedMissionId}."
                    );
                }
                if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy) ||
                    economy.Coins <= 0 || economy.Xp <= 0)
                {
                    throw new InvalidOperationException("PlayMode completion did not persist settlement.");
                }
                if (PlayerPrefs.HasKey(CompletionHandoffKey))
                {
                    throw new InvalidOperationException("PlayMode completion handoff remained after successful settlement.");
                }

                Debug.Log("[CARGO V2][QA][PLAYMODE][PASS] completion recovery commits progression before settlement under reversed bridge ordering.");
            }
            catch (Exception exception)
            {
                Debug.LogError($"[CARGO V2][QA][PLAYMODE][FAIL] {exception}");
                if (Application.isBatchMode) Application.Quit(86);
            }
            finally
            {
                if (root != null) Destroy(root);
                snapshot.Restore();
                Destroy(gameObject);
            }
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
            private readonly StringState progress = StringState.Capture(ProgressKey);
            private readonly StringState economy = StringState.Capture(EconomyKey);
            private readonly IntState completion = IntState.Capture(CompletionHandoffKey);
            private readonly IntState stars = IntState.Capture(CompletionStarsKey);
            private readonly StringState completionRun = StringState.Capture(CompletionDeliveryRunKey);
            private readonly StringState activeRun = StringState.Capture(ActiveDeliveryRunKey);

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
