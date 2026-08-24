using System;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapTouchInputBridge : MonoBehaviour
    {
        private const float RayDistance = 250f;
        private const string DeployButtonName = "DeployMissionButton";
        private const string MissionNodePrefix = "MissionNode_";
        private static bool sceneHookRegistered;

        private SCR_WorldMapRuntimeDirector runtimeDirector;
        private SCR_WorldMapMissionDeploy deployGateway;

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
            TryInstall(SceneManager.GetActiveScene());
        }

        private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            TryInstall(scene);
        }

        private static void TryInstall(Scene scene)
        {
            if (!scene.IsValid() || !scene.isLoaded || !IsWorldMapScene(scene.name)) return;
            if (FindObjectOfType<SCR_WorldMapTouchInputBridge>() != null) return;
            new GameObject("CARGO_V2_WorldMapTouchInput").AddComponent<SCR_WorldMapTouchInputBridge>();
        }

        private static bool IsWorldMapScene(string sceneName)
        {
            if (string.IsNullOrWhiteSpace(sceneName)) return false;
            return sceneName.IndexOf("WorldMap", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   sceneName.IndexOf("04_", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private void Update()
        {
            if (SCR_MissionRuntimeDirector.IsRunning || Input.touchCount <= 0) return;

            Touch touch = Input.GetTouch(0);
            if (touch.phase != TouchPhase.Ended) return;

            Camera camera = ResolveCamera();
            if (camera == null) return;

            Ray ray = camera.ScreenPointToRay(touch.position);
            if (!Physics.Raycast(ray, out RaycastHit hit, RayDistance)) return;

            Transform target = hit.collider == null ? null : hit.collider.transform;
            if (target == null) return;

            if (MatchesObjectOrParent(target, DeployButtonName))
            {
                ResolveDeployGateway()?.TryDeploy();
                return;
            }

            int missionId = ResolveMissionNodeId(target);
            if (missionId <= 0) return;
            ResolveRuntimeDirector()?.SelectMission(missionId);
        }

        private Camera ResolveCamera()
        {
            Camera main = Camera.main;
            if (main != null && main.isActiveAndEnabled) return main;

            Camera[] cameras = FindObjectsOfType<Camera>();
            for (int i = 0; i < cameras.Length; i++)
            {
                if (cameras[i] != null && cameras[i].isActiveAndEnabled) return cameras[i];
            }
            return null;
        }

        private SCR_WorldMapRuntimeDirector ResolveRuntimeDirector()
        {
            if (runtimeDirector == null) runtimeDirector = FindObjectOfType<SCR_WorldMapRuntimeDirector>();
            return runtimeDirector;
        }

        private SCR_WorldMapMissionDeploy ResolveDeployGateway()
        {
            if (deployGateway == null) deployGateway = FindObjectOfType<SCR_WorldMapMissionDeploy>();
            return deployGateway;
        }

        private static bool MatchesObjectOrParent(Transform target, string objectName)
        {
            for (Transform current = target; current != null; current = current.parent)
            {
                if (string.Equals(current.name, objectName, StringComparison.Ordinal)) return true;
            }
            return false;
        }

        private static int ResolveMissionNodeId(Transform target)
        {
            for (Transform current = target; current != null; current = current.parent)
            {
                string objectName = current.name;
                if (string.IsNullOrEmpty(objectName) || !objectName.StartsWith(MissionNodePrefix, StringComparison.Ordinal)) continue;
                string suffix = objectName.Substring(MissionNodePrefix.Length);
                if (int.TryParse(suffix, out int missionId) && missionId >= 1 && missionId <= 20) return missionId;
            }
            return 0;
        }
    }
}
