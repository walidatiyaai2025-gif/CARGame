using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapPersistenceBridge : MonoBehaviour
    {
        [SerializeField] private SCR_WorldMapRouteController routeController;
        [SerializeField] private SCR_SaveManager saveManager;

        private bool initialized;

        public bool IsInitialized => initialized;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void RegisterSceneInstall()
        {
            // Domain reload can be disabled in the Editor. Remove first so repeated
            // play sessions never accumulate duplicate static sceneLoaded handlers.
            SceneManager.sceneLoaded -= HandleSceneLoaded;
            SceneManager.sceneLoaded += HandleSceneLoaded;
        }

        private static void HandleSceneLoaded(Scene _, LoadSceneMode __)
        {
            InstallInLoadedScene();
        }

        private static void InstallInLoadedScene()
        {
            SCR_WorldMapRouteController controller = FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null) return;
            if (controller.GetComponent<SCR_WorldMapPersistenceBridge>() != null) return;

            SCR_WorldMapPersistenceBridge bridge =
                controller.gameObject.AddComponent<SCR_WorldMapPersistenceBridge>();
            bridge.routeController = controller;
        }

        private void Awake()
        {
            if (routeController == null)
            {
                routeController = GetComponent<SCR_WorldMapRouteController>() ??
                                  FindObjectOfType<SCR_WorldMapRouteController>();
            }

            if (saveManager == null)
            {
                saveManager = GetComponent<SCR_SaveManager>() ?? FindObjectOfType<SCR_SaveManager>();
            }

            if (saveManager == null)
            {
                saveManager = gameObject.AddComponent<SCR_SaveManager>();
            }
        }

        private void Start()
        {
            Initialize();
        }

        private void OnEnable()
        {
            if (initialized) Subscribe();
        }

        private void OnDisable()
        {
            Unsubscribe();
        }

        private void OnApplicationPause(bool paused)
        {
            if (paused) PersistCurrentState();
        }

        private void OnApplicationQuit()
        {
            PersistCurrentState();
        }

        public bool Initialize()
        {
            if (initialized) return true;
            if (routeController == null || saveManager == null) return false;

            SCR_SaveManager.ProgressPayload payload = saveManager.LoadProgress(routeController.MissionCount);
            routeController.SetProgress(payload.highestCompletedMissionId);
            if (payload.selectedMissionId > 0)
            {
                routeController.TrySelectMission(payload.selectedMissionId);
            }

            initialized = true;
            Subscribe();
            if (PersistCurrentState()) return true;

            // Never advertise durable readiness when the canonical progress snapshot
            // could not be written. A completion handoff must remain pending instead
            // of paying against progression that may roll back after a crash.
            initialized = false;
            Unsubscribe();
            Debug.LogWarning("[CARGO V2][LOGIC] WorldMap persistence initialization could not durably save the normalized progress snapshot.");
            return false;
        }

        public bool PersistCurrentState()
        {
            if (!initialized || routeController == null || saveManager == null) return false;
            return saveManager.SaveProgress(
                routeController.HighestCompletedMissionId,
                routeController.SelectedMissionId,
                routeController.MissionCount);
        }

        private void Subscribe()
        {
            if (routeController == null) return;
            routeController.ProgressChanged -= HandleProgressChanged;
            routeController.SelectionChanged -= HandleSelectionChanged;
            routeController.ProgressChanged += HandleProgressChanged;
            routeController.SelectionChanged += HandleSelectionChanged;
        }

        private void Unsubscribe()
        {
            if (routeController == null) return;
            routeController.ProgressChanged -= HandleProgressChanged;
            routeController.SelectionChanged -= HandleSelectionChanged;
        }

        private void HandleProgressChanged(int _)
        {
            PersistCurrentState();
        }

        private void HandleSelectionChanged(int _)
        {
            PersistCurrentState();
        }
    }
}
