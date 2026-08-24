using System;
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

            int missionId = PlayerPrefs.GetInt(CompletionHandoffKey, 0);
            int missionCount = routeController.MissionCount;
            if (!WorldMapProgression.IsValidMissionId(missionId, missionCount))
            {
                ClearHandoff();
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC_TEAM] Rejected invalid mission completion handoff {missionId}; valid range is 1..{missionCount}.");
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
                    $"[CARGO V2][LOGIC_TEAM] Rejected non-sequential mission completion handoff {missionId}; progression was not advanced.");
                return false;
            }

            ClearHandoff();
            Debug.Log($"[CARGO V2][LOGIC_TEAM] Consumed mission completion handoff {missionId} through authoritative progression.");
            return true;
        }

        private static void ClearHandoff()
        {
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.Save();
        }
    }
}
