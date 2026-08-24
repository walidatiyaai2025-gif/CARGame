using System;
using System.Reflection;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapMissionDeploy : MonoBehaviour
    {
        private const string PendingMissionKey = "cargo_v2_pending_mission_id";
        private object routeController;
        private Type routeControllerType;
        private PropertyInfo selectedMissionIdProperty;
        private MethodInfo getNodeStateMethod;
        private TextMesh statusText;
        private bool transitionBusy;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
        {
            Scene scene = SceneManager.GetActiveScene();
            if (!IsWorldMapScene(scene.name)) return;
            if (FindObjectOfType<SCR_WorldMapMissionDeploy>() != null) return;
            new GameObject("CARGO_V2_MissionDeployGateway").AddComponent<SCR_WorldMapMissionDeploy>();
        }

        private static bool IsWorldMapScene(string sceneName)
        {
            if (string.IsNullOrWhiteSpace(sceneName)) return false;
            return sceneName.IndexOf("WorldMap", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   sceneName.IndexOf("04_", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private void Start()
        {
            DiscoverRouteController();
            BuildDeployControl();
        }

        private void Update()
        {
            if (routeController == null) DiscoverRouteController();
            RefreshStatus();
        }

        private void DiscoverRouteController()
        {
            routeControllerType = Type.GetType("CargoV2.Logic.SCR_WorldMapRouteController, Assembly-CSharp");
            if (routeControllerType == null) return;
            UnityEngine.Object controller = FindObjectOfType(routeControllerType);
            if (controller == null) return;
            routeController = controller;
            selectedMissionIdProperty = routeControllerType.GetProperty("SelectedMissionId", BindingFlags.Instance | BindingFlags.Public);
            getNodeStateMethod = routeControllerType.GetMethod("GetNodeState", BindingFlags.Instance | BindingFlags.Public);
        }

        private void BuildDeployControl()
        {
            GameObject button = GameObject.CreatePrimitive(PrimitiveType.Cube);
            button.name = "DeployMissionButton";
            button.transform.SetParent(transform, false);
            button.transform.position = new Vector3(0f, 0.45f, -7.15f);
            button.transform.localScale = new Vector3(4.8f, 0.22f, 1.05f);

            Shader shader = Shader.Find("Standard") ?? Shader.Find("Universal Render Pipeline/Lit");
            Renderer renderer = button.GetComponent<Renderer>();
            if (renderer != null && shader != null)
            {
                Material material = new Material(shader) { color = new Color(0.88f, 0.66f, 0.16f) };
                renderer.material = material;
            }

            DeployClick click = button.AddComponent<DeployClick>();
            click.Owner = this;

            GameObject label = new GameObject("DeployLabel");
            label.transform.SetParent(button.transform, false);
            label.transform.localPosition = new Vector3(0f, 0.72f, 0f);
            label.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            statusText = label.AddComponent<TextMesh>();
            statusText.anchor = TextAnchor.MiddleCenter;
            statusText.alignment = TextAlignment.Center;
            statusText.fontSize = 44;
            statusText.characterSize = 0.065f;
            statusText.color = Color.white;
            RefreshStatus();
        }

        private int ResolveSelectedMissionId()
        {
            if (routeController != null && selectedMissionIdProperty != null)
            {
                try { return Mathf.Clamp(Convert.ToInt32(selectedMissionIdProperty.GetValue(routeController)), 1, 20); }
                catch (Exception) { }
            }
            return 1;
        }

        private bool IsDeployable(int missionId)
        {
            if (missionId < 1 || missionId > 20) return false;
            if (routeController == null || getNodeStateMethod == null) return missionId == 1;
            try
            {
                object state = getNodeStateMethod.Invoke(routeController, new object[] { missionId });
                string value = state == null ? "Locked" : state.ToString();
                return !string.Equals(value, "Locked", StringComparison.OrdinalIgnoreCase);
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] Deploy state lookup failed safely: {e.Message}");
                return false;
            }
        }

        internal void TryDeploy()
        {
            if (transitionBusy) return;
            int missionId = ResolveSelectedMissionId();
            if (!IsDeployable(missionId))
            {
                Debug.Log($"[CARGO V2][UI_TEAM] Mission {missionId} deploy rejected because it is locked or unavailable.");
                RefreshStatus("LOCKED — COMPLETE PREVIOUS MISSION");
                return;
            }

            string nextScene = FindMissionScene();
            if (string.IsNullOrWhiteSpace(nextScene))
            {
                Debug.LogWarning("[CARGO V2][UI_TEAM] No Mission/Briefing/05_ scene exists in build settings; remaining safely on WorldMap.");
                RefreshStatus("BRIEFING SCENE NOT YET ADMITTED");
                return;
            }

            transitionBusy = true;
            PlayerPrefs.SetInt(PendingMissionKey, missionId);
            PlayerPrefs.Save();
            RefreshStatus($"DEPLOYING MISSION {missionId:00}...");
            SceneManager.LoadScene(nextScene, LoadSceneMode.Single);
        }

        private static string FindMissionScene()
        {
            for (int i = 0; i < SceneManager.sceneCountInBuildSettings; i++)
            {
                string path = SceneUtility.GetScenePathByBuildIndex(i);
                string name = System.IO.Path.GetFileNameWithoutExtension(path);
                if (name.IndexOf("Briefing", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    name.IndexOf("Mission", StringComparison.OrdinalIgnoreCase) >= 0 ||
                    name.StartsWith("05_", StringComparison.OrdinalIgnoreCase))
                {
                    return name;
                }
            }
            return null;
        }

        private void RefreshStatus(string overrideText = null)
        {
            if (statusText == null) return;
            if (!string.IsNullOrWhiteSpace(overrideText))
            {
                statusText.text = overrideText;
                return;
            }
            int missionId = ResolveSelectedMissionId();
            statusText.text = transitionBusy
                ? $"DEPLOYING MISSION {missionId:00}..."
                : IsDeployable(missionId)
                    ? $"DEPLOY MISSION {missionId:00}"
                    : "MISSION LOCKED";
        }

        private sealed class DeployClick : MonoBehaviour
        {
            public SCR_WorldMapMissionDeploy Owner;
            private void OnMouseUpAsButton() { Owner?.TryDeploy(); }
        }
    }
}
