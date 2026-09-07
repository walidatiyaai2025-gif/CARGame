using System;
using CargoV2.Data;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_MissionCompletionHandoffBridge : MonoBehaviour
    {
        public const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        public const string CompletionStarsKey = "cargo_v2_completed_mission_stars";
        public const string CompletionDeliveryRunKey = "cargo_v2_completed_delivery_run_id";
        public const string ActiveDeliveryRunKey = "cargo_v2_active_delivery_run_id_v1";
        private const float PollIntervalSeconds = 0.2f;
        private static bool sceneHookRegistered;

        private SCR_WorldMapRouteController routeController;
        private SCR_WorldMapPersistenceBridge persistenceBridge;
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

        private bool EnsurePersistenceReady()
        {
            if (routeController == null) return false;

            if (persistenceBridge == null)
            {
                persistenceBridge = routeController.GetComponent<SCR_WorldMapPersistenceBridge>();
                if (persistenceBridge == null)
                {
                    persistenceBridge = routeController.gameObject.AddComponent<SCR_WorldMapPersistenceBridge>();
                }
            }

            if (persistenceBridge.Initialize() && persistenceBridge.IsInitialized) return true;

            Debug.LogWarning(
                "[CARGO V2][LOGIC] Completion handoff retained because WorldMap persistence is not durably initialized yet.");
            return false;
        }

        internal bool ConsumePendingHandoff()
        {
            if (routeController == null || !PlayerPrefs.HasKey(CompletionHandoffKey)) return false;

            // Unity does not guarantee Start ordering between independently installed
            // bridges. Load and normalize the durable progression snapshot first so a
            // crash-recovered completion can never pay and then be overwritten by an
            // older progress payload later in the same frame.
            if (!EnsurePersistenceReady()) return false;

            int missionCount = routeController.MissionCount;
            int missionId = PlayerPrefs.GetInt(CompletionHandoffKey, 0);
            int stars = Mathf.Clamp(PlayerPrefs.GetInt(CompletionStarsKey, 1), 1, 3);
            string deliveryRunId = PlayerPrefs.GetString(CompletionDeliveryRunKey, string.Empty);
            bool hasDeliveryRun = Guid.TryParseExact(deliveryRunId, "N", out _);

            if (missionCount <= 0) return false;
            if (!WorldMapProgression.IsValidMissionId(missionId, missionCount))
            {
                ClearCompletionKeysOnly();
                Debug.LogWarning($"[CARGO V2][LOGIC] Rejected invalid mission completion handoff {missionId}; active delivery identity was preserved.");
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
                ClearCompletionKeysOnly();
                Debug.LogWarning($"[CARGO V2][LOGIC] Rejected non-sequential mission completion {missionId}; active delivery identity was preserved and no reward advanced.");
                return false;
            }

            // Progression persistence is the commit-before-pay boundary. If the
            // normalized/completed WorldMap state cannot be durably written, keep the
            // handoff and retry later; never settle economy first.
            if (persistenceBridge == null || !persistenceBridge.PersistCurrentState())
            {
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC] Mission {missionId} completion is in memory but durable progression save failed; settlement deferred and handoff retained.");
                return false;
            }

            bool rewardGranted;
            SCR_MissionRewardStore.Snapshot economy;
            bool settled;
            if (hasDeliveryRun)
            {
                settled = SCR_MissionRewardStore.TrySettleDelivery(
                    mission,
                    stars,
                    deliveryRunId,
                    out rewardGranted,
                    out economy);
            }
            else
            {
                settled = SCR_MissionRewardStore.TrySettleMission(
                    mission,
                    stars,
                    out rewardGranted,
                    out economy);
            }

            if (!settled)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Mission {missionId} progression was accepted but settlement did not persist; handoff retained for idempotent retry.");
                return false;
            }

            // Only a fully committed progression+settlement may retire the delivery
            // session. A process kill after mission-side handoff creation but before
            // its local active-store clear therefore converges here without exposing
            // a stale Resume button or minting a second delivery identity.
            SCR_ActiveDeliveryStore.Clear();
            ClearSettledDeliveryKeys();

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

        private static void ClearCompletionKeysOnly()
        {
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.DeleteKey(CompletionDeliveryRunKey);
            PlayerPrefs.Save();
        }

        private static void ClearSettledDeliveryKeys()
        {
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.DeleteKey(CompletionDeliveryRunKey);
            PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);
            PlayerPrefs.Save();
        }
    }
}
