using System;
using CargoV2.Data;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_MissionCompletionHandoffBridge : MonoBehaviour
    {
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private const string CompletionStarsKey = "cargo_v2_completed_mission_stars";
        private const string CompletionDeliveryRunKey = "cargo_v2_completed_delivery_run_id";
        private const string ActiveDeliveryRunKey = "cargo_v2_active_delivery_run_id_v1";
        private const float PollIntervalSeconds = 0.2f;
        private static bool sceneHookRegistered;

        private SCR_WorldMapRouteController routeController;
        private float nextPollTime;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void RegisterSceneHook()
        {
            if (sceneHookRegistered) SceneManager.sceneLoaded -= OnSceneLoaded;
            SceneManager.sceneLoaded += OnSceneLoaded;
            sceneHookRegistered = true;
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void InstallInitialScene() => TryInstall();

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode) => TryInstall();

        private static void TryInstall()
        {
            SCR_WorldMapRouteController controller = FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null || controller.GetComponent<SCR_MissionCompletionHandoffBridge>() != null) return;
            SCR_MissionCompletionHandoffBridge bridge = controller.gameObject.AddComponent<SCR_MissionCompletionHandoffBridge>();
            bridge.routeController = controller;
        }

        private void Awake()
        {
            if (routeController == null) routeController = GetComponent<SCR_WorldMapRouteController>();
        }

        private void Start() => ConsumePendingHandoff();

        private void Update()
        {
            if (Time.unscaledTime < nextPollTime) return;
            nextPollTime = Time.unscaledTime + PollIntervalSeconds;
            ConsumePendingHandoff();
        }

        internal bool ConsumePendingHandoff()
        {
            if (routeController == null || !PlayerPrefs.HasKey(CompletionHandoffKey)) return false;

            int missionCount = routeController.MissionCount;
            int missionId = PlayerPrefs.GetInt(CompletionHandoffKey, 0);
            int stars = Mathf.Clamp(PlayerPrefs.GetInt(CompletionStarsKey, 1), 1, 3);
            string deliveryRunId = PlayerPrefs.GetString(CompletionDeliveryRunKey, string.Empty);
            bool hasDeliveryRun = Guid.TryParseExact(deliveryRunId, "N", out _);

            if (missionCount <= 0) return false;
            if (!WorldMapProgression.IsValidMissionId(missionId, missionCount))
            {
                ClearHandoff();
                Debug.LogWarning($"[CARGO V2][LOGIC] Rejected invalid mission completion handoff {missionId}; valid range is 1..{missionCount}.");
                return false;
            }

            SO_GameBalance.MissionBalance mission = routeController.GetMission(missionId);
            if (mission == null)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Mission {missionId} has no authoritative balance record; handoff retained for retry.");
                return false;
            }

            bool accepted;
            try
            {
                accepted = routeController.TryCompleteMission(missionId);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Mission completion handoff failed safely: {exception.Message}");
                return false;
            }

            if (!accepted)
            {
                ClearHandoff();
                Debug.LogWarning($"[CARGO V2][LOGIC] Rejected non-sequential mission completion {missionId}; progression and reward were not advanced.");
                return false;
            }

            bool settled = hasDeliveryRun
                ? SCR_MissionRewardStore.TrySettleDelivery(
                    mission,
                    stars,
                    deliveryRunId,
                    out bool rewardGranted,
                    out SCR_MissionRewardStore.Snapshot economy)
                : SCR_MissionRewardStore.TrySettleMission(
                    mission,
                    stars,
                    out rewardGranted,
                    out economy);

            if (!settled)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Mission {missionId} progression was accepted but settlement did not persist; handoff retained for idempotent retry.");
                return false;
            }

            ClearHandoff();
            if (rewardGranted)
            {
                long coins = SCR_MissionRewardStore.GetCoinReward(mission, stars);
                string mode = hasDeliveryRun ? "delivery" : "legacy mission";
                Debug.Log($"[CARGO V2][LOGIC] {mode} {missionId} settled at {stars} star(s): +{coins} coins, +{mission.xp} XP. Totals {economy.Coins} coins / {economy.Xp} XP.");
            }
            else
            {
                Debug.Log($"[CARGO V2][LOGIC] Mission {missionId} completion consumed with this settlement already applied; totals remain {economy.Coins} coins / {economy.Xp} XP.");
            }
            return true;
        }

        private static void ClearHandoff()
        {
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.DeleteKey(CompletionDeliveryRunKey);
            PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);
            PlayerPrefs.Save();
        }
    }
}
