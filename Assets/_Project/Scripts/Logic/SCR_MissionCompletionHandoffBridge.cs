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
        private static void InstallInitialScene()
        {
            TryInstall();
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            TryInstall();
        }

        private static void TryInstall()
        {
            SCR_WorldMapRouteController controller = FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null) return;

            SCR_MissionCompletionHandoffBridge existing = controller.GetComponent<SCR_MissionCompletionHandoffBridge>();
            if (existing != null) return;

            SCR_MissionCompletionHandoffBridge bridge = controller.gameObject.AddComponent<SCR_MissionCompletionHandoffBridge>();
            bridge.routeController = controller;
        }

        private void Awake()
        {
            if (routeController == null)
            {
                routeController = GetComponent<SCR_WorldMapRouteController>();
            }
        }

        private void Start()
        {
            ConsumePendingHandoff();
        }

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
            if (missionCount <= 0) return false;

            int missionId = PlayerPrefs.GetInt(CompletionHandoffKey, 0);
            if (!WorldMapProgression.IsValidMissionId(missionId, missionCount))
            {
                ClearHandoff();
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Rejected invalid mission completion handoff {missionId}; valid range is 1..{missionCount}.");
                return false;
            }

            SO_GameBalance.MissionBalance mission = routeController.GetMission(missionId);
            if (mission == null)
            {
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Mission {missionId} has no authoritative balance record; completion handoff retained for retry.");
                return false;
            }

            bool accepted;
            try
            {
                accepted = routeController.TryCompleteMission(missionId);
            }
            catch (Exception exception)
            {
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Mission completion handoff failed safely: {exception.Message}");
                return false;
            }

            if (!accepted)
            {
                ClearHandoff();
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Rejected non-sequential mission completion handoff {missionId}; progression was not advanced and no reward was granted.");
                return false;
            }

            if (!SCR_MissionRewardStore.TrySettleMission(
                    mission,
                    out bool rewardGranted,
                    out SCR_MissionRewardStore.Snapshot economy))
            {
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Progression accepted mission {missionId}, but reward settlement did not persist safely; handoff retained for idempotent retry.");
                return false;
            }

            ClearHandoff();
            if (rewardGranted)
            {
                Debug.Log(
                    $"[CARGO V2][LOGIC_TEAM] Mission {missionId} settled approved completion reward: +{mission.coin1Star} coins, +{mission.xp} XP. Totals: {economy.Coins} coins / {economy.Xp} XP.");
            }
            else
            {
                Debug.Log(
                    $"[CARGO V2][LOGIC_TEAM] Mission {missionId} completion consumed with reward already settled; totals remain {economy.Coins} coins / {economy.Xp} XP.");
            }
            return true;
        }

        private static void ClearHandoff()
        {
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.Save();
        }
    }
}
