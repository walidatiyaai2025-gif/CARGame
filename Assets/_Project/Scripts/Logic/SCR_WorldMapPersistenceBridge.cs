using UnityEngine;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapPersistenceBridge : MonoBehaviour
    {
        [SerializeField] private SCR_WorldMapRouteController routeController;
        [SerializeField] private SCR_SaveManager saveManager;

        private bool initialized;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
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
                routeController = FindObjectOfType<SCR_WorldMapRouteController>();
            }

            if (saveManager == null)
            {
                saveManager = FindObjectOfType<SCR_SaveManager>();
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
            if (paused) Persist();
        }

        private void OnApplicationQuit()
        {
            Persist();
        }

        public void Initialize()
        {
            if (initialized || routeController == null || saveManager == null) return;

            SCR_SaveManager.ProgressPayload payload = saveManager.LoadProgress(routeController.MissionCount);
            routeController.SetProgress(payload.highestCompletedMissionId);
            if (payload.selectedMissionId > 0)
            {
                routeController.TrySelectMission(payload.selectedMissionId);
            }

            initialized = true;
            Subscribe();
            Persist();
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
            Persist();
        }

        private void HandleSelectionChanged(int _)
        {
            Persist();
        }

        private void Persist()
        {
            if (!initialized || routeController == null || saveManager == null) return;
            saveManager.SaveProgress(
                routeController.HighestCompletedMissionId,
                routeController.SelectedMissionId,
                routeController.MissionCount);
        }
    }
}
