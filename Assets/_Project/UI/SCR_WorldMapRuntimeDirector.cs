using System;
using System.Collections.Generic;
using System.Reflection;
using CargoV2.Data;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapRuntimeDirector : MonoBehaviour
    {
        private sealed class NodeView
        {
            public int MissionId;
            public GameObject Root;
            public Renderer Renderer;
            public TextMesh Label;
            public WorldMapNodeClick FallbackClick;
            public Component LogicNode;
            public string LastState;
            public bool LastSelected;
        }

        [SerializeField] private SO_GameBalance gameBalance;
        [SerializeField] private bool autoBuildOnWorldMapScene = true;
        [SerializeField] private float width = 18f;
        [SerializeField] private float height = 9f;
        [SerializeField] private float refreshIntervalSeconds = 0.12f;

        private readonly List<NodeView> nodes = new List<NodeView>(20);
        private object routeController;
        private Type routeControllerType;
        private Type routeNodeType;
        private MethodInfo getNodeState;
        private MethodInfo trySelectMission;
        private MethodInfo bindRouteNode;
        private PropertyInfo selectedMissionId;
        private Material lockedMaterial;
        private Material availableMaterial;
        private Material completedMaterial;
        private Material selectedMaterial;
        private Material routeMaterial;
        private TextMesh detailText;
        private int previewSelectedMissionId = 1;
        private float nextRefreshAt;
        private int lastDetailMissionId = -1;
        private string lastDetailState;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
        {
            Scene scene = SceneManager.GetActiveScene();
            if (!IsWorldMapScene(scene.name)) return;
            if (FindObjectOfType<SCR_WorldMapRuntimeDirector>() != null) return;
            new GameObject("CARGO_V2_WorldMapRuntime").AddComponent<SCR_WorldMapRuntimeDirector>();
        }

        private static bool IsWorldMapScene(string sceneName)
        {
            if (string.IsNullOrWhiteSpace(sceneName)) return false;
            return sceneName.IndexOf("WorldMap", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   sceneName.IndexOf("04_", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private void Start()
        {
            if (!autoBuildOnWorldMapScene) return;
            EnsureBalance();
            CreateSharedMaterials();
            DiscoverLogicController();
            BuildWorldMap();
        }

        private void Update()
        {
            if (routeController == null) DiscoverLogicController();
            if (Time.unscaledTime < nextRefreshAt) return;
            nextRefreshAt = Time.unscaledTime + Mathf.Max(0.05f, refreshIntervalSeconds);
            RefreshStates();
        }

        private void OnDestroy()
        {
            DestroyMaterial(lockedMaterial);
            DestroyMaterial(availableMaterial);
            DestroyMaterial(completedMaterial);
            DestroyMaterial(selectedMaterial);
            DestroyMaterial(routeMaterial);
        }

        private static void DestroyMaterial(Material material)
        {
            if (material != null) UnityEngine.Object.Destroy(material);
        }

        private void EnsureBalance()
        {
            if (gameBalance != null && gameBalance.missions != null && gameBalance.missions.Count > 0) return;
            gameBalance = ScriptableObject.CreateInstance<SO_GameBalance>();
            gameBalance.name = "SO_GameBalance_WorldMapPreview";
            gameBalance.ResetToApprovedDefaults();
        }

        private void CreateSharedMaterials()
        {
            if (lockedMaterial != null) return;
            lockedMaterial = MakeMaterial(new Color(0.13f, 0.18f, 0.27f));
            availableMaterial = MakeMaterial(new Color(0.88f, 0.66f, 0.16f));
            completedMaterial = MakeMaterial(new Color(0.12f, 0.50f, 0.34f));
            selectedMaterial = MakeMaterial(Color.white);
            routeMaterial = MakeMaterial(new Color(0.88f, 0.66f, 0.16f));
        }

        private void DiscoverLogicController()
        {
            routeControllerType = Type.GetType("CargoV2.Logic.SCR_WorldMapRouteController, Assembly-CSharp");
            if (routeControllerType == null) return;
            UnityEngine.Object controller = FindObjectOfType(routeControllerType);
            if (controller == null) return;

            routeController = controller;
            getNodeState = routeControllerType.GetMethod("GetNodeState", BindingFlags.Instance | BindingFlags.Public);
            trySelectMission = routeControllerType.GetMethod("TrySelectMission", BindingFlags.Instance | BindingFlags.Public);
            selectedMissionId = routeControllerType.GetProperty("SelectedMissionId", BindingFlags.Instance | BindingFlags.Public);

            routeNodeType = Type.GetType("CargoV2.Logic.SCR_WorldMapMissionNode, Assembly-CSharp");
            bindRouteNode = routeNodeType?.GetMethod("Bind", BindingFlags.Instance | BindingFlags.Public);
            BindAllNodesToLogic();
            RefreshStates(true);
        }

        private void BindAllNodesToLogic()
        {
            if (routeController == null || routeNodeType == null || bindRouteNode == null) return;
            for (int i = 0; i < nodes.Count; i++) BindNodeToLogic(nodes[i]);
        }

        private void BindNodeToLogic(NodeView node)
        {
            if (node == null || node.Root == null || node.LogicNode != null || routeController == null || routeNodeType == null || bindRouteNode == null) return;
            try
            {
                Component logicNode = node.Root.GetComponent(routeNodeType) ?? node.Root.AddComponent(routeNodeType);
                bindRouteNode.Invoke(logicNode, new object[] { routeController, node.MissionId });
                node.LogicNode = logicNode;
                if (node.FallbackClick != null) node.FallbackClick.enabled = false;
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] Mission {node.MissionId} logic-node binding fallback: {e.Message}");
            }
        }

        private void BuildWorldMap()
        {
            if (nodes.Count > 0) return;
            Camera camera = Camera.main;
            if (camera != null)
            {
                camera.transform.position = new Vector3(0f, 7.5f, -16f);
                camera.transform.rotation = Quaternion.Euler(18f, 0f, 0f);
                camera.backgroundColor = new Color(0.015f, 0.035f, 0.075f);
            }

            LineRenderer route = new GameObject("RouteLine").AddComponent<LineRenderer>();
            route.transform.SetParent(transform, false);
            route.positionCount = 20;
            route.widthMultiplier = 0.08f;
            route.sharedMaterial = routeMaterial;
            route.useWorldSpace = true;

            for (int i = 0; i < 20; i++)
            {
                int missionId = i + 1;
                Vector3 position = ResolvePosition(missionId, i);
                route.SetPosition(i, position + Vector3.down * 0.35f);

                GameObject nodeObject = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                nodeObject.name = $"MissionNode_{missionId:00}";
                nodeObject.transform.SetParent(transform, false);
                nodeObject.transform.position = position;
                nodeObject.transform.localScale = new Vector3(0.72f, 0.18f, 0.72f);
                WorldMapNodeClick fallbackClick = nodeObject.AddComponent<WorldMapNodeClick>();
                fallbackClick.Configure(this, missionId);

                GameObject labelObject = new GameObject("Label");
                labelObject.transform.SetParent(nodeObject.transform, false);
                labelObject.transform.localPosition = new Vector3(0f, 1.7f, 0f);
                labelObject.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
                TextMesh label = labelObject.AddComponent<TextMesh>();
                label.anchor = TextAnchor.MiddleCenter;
                label.alignment = TextAlignment.Center;
                label.fontSize = 44;
                label.characterSize = 0.08f;
                label.color = Color.white;

                NodeView node = new NodeView
                {
                    MissionId = missionId,
                    Root = nodeObject,
                    Renderer = nodeObject.GetComponent<Renderer>(),
                    Label = label,
                    FallbackClick = fallbackClick,
                };
                nodes.Add(node);
                BindNodeToLogic(node);
            }

            BuildDetailBoard();
            RefreshStates(true);
        }

        private void BuildDetailBoard()
        {
            GameObject panel = GameObject.CreatePrimitive(PrimitiveType.Cube);
            panel.name = "SelectedMissionPanel";
            panel.transform.SetParent(transform, false);
            panel.transform.position = new Vector3(0f, 0.28f, -5.4f);
            panel.transform.localScale = new Vector3(7.2f, 0.12f, 1.25f);
            Renderer panelRenderer = panel.GetComponent<Renderer>();
            if (panelRenderer != null) panelRenderer.sharedMaterial = lockedMaterial;
            Collider panelCollider = panel.GetComponent<Collider>();
            if (panelCollider != null) Destroy(panelCollider);

            GameObject textObject = new GameObject("SelectedMissionDetails");
            textObject.transform.SetParent(panel.transform, false);
            textObject.transform.localPosition = new Vector3(0f, 0.7f, 0f);
            textObject.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            detailText = textObject.AddComponent<TextMesh>();
            detailText.anchor = TextAnchor.MiddleCenter;
            detailText.alignment = TextAlignment.Center;
            detailText.fontSize = 42;
            detailText.characterSize = 0.055f;
            detailText.color = Color.white;
        }

        private Vector3 ResolvePosition(int missionId, int index)
        {
            try
            {
                Type catalogType = Type.GetType("CargoV2.Data.WorldMapPresentationCatalog, Assembly-CSharp");
                MethodInfo tryGet = catalogType?.GetMethod("TryGet", BindingFlags.Public | BindingFlags.Static);
                if (tryGet != null)
                {
                    object[] args = { missionId, null };
                    if ((bool)tryGet.Invoke(null, args) && args[1] != null)
                    {
                        object record = args[1];
                        Type t = record.GetType();
                        float x = Convert.ToSingle(t.GetProperty("NormalizedX")?.GetValue(record));
                        float y = Convert.ToSingle(t.GetProperty("NormalizedY")?.GetValue(record));
                        return new Vector3(x * width * 0.5f, 0f, y * height * 0.5f);
                    }
                }
            }
            catch (Exception e)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] WorldMap metadata fallback: {e.Message}");
            }

            float tFallback = index / 19f;
            float xFallback = Mathf.Lerp(-width * 0.46f, width * 0.46f, tFallback);
            float zFallback = Mathf.Sin(tFallback * Mathf.PI * 2f) * height * 0.28f;
            return new Vector3(xFallback, 0f, zFallback);
        }

        internal void SelectMission(int missionId)
        {
            if (missionId < 1 || missionId > 20) return;
            if (routeController != null && trySelectMission != null)
            {
                try
                {
                    object result = trySelectMission.Invoke(routeController, new object[] { missionId });
                    if (result is bool accepted && !accepted) return;
                    RefreshStates(true);
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[CARGO V2][UI_TEAM] Mission {missionId} selection failed safely: {e.Message}");
                }
                return;
            }

            if (missionId != 1)
            {
                Debug.Log($"[CARGO V2][UI_TEAM] Mission {missionId} is locked in visual-preview mode; progression controller is not present.");
                return;
            }

            previewSelectedMissionId = missionId;
            Debug.Log($"[CARGO V2][UI_TEAM] Mission {missionId} selected in visual-preview mode; progression controller not present on this branch.");
            RefreshStates(true);
        }

        private void RefreshStates(bool force = false)
        {
            int selectedId = GetSelectedMissionId();
            string selectedState = "Locked";

            for (int i = 0; i < nodes.Count; i++)
            {
                NodeView node = nodes[i];
                string state = ResolveNodeState(node.MissionId);
                bool selected = selectedId == node.MissionId;

                if (force || node.LastState != state || node.LastSelected != selected)
                {
                    if (node.Renderer != null) node.Renderer.sharedMaterial = ResolveMaterial(state, selected);
                    if (node.Label != null)
                    {
                        SO_GameBalance.MissionBalance mission = gameBalance.GetMission(node.MissionId);
                        string city = mission == null ? "MISSION" : mission.city;
                        node.Label.text = $"{node.MissionId:00}  {city}\n{StateCue(state, selected)}";
                    }
                    node.LastState = state;
                    node.LastSelected = selected;
                }

                if (selected) selectedState = state;
            }

            RefreshDetailBoard(selectedId, selectedState, force);
        }

        private int GetSelectedMissionId()
        {
            if (routeController != null && selectedMissionId != null)
            {
                try { return Mathf.Clamp(Convert.ToInt32(selectedMissionId.GetValue(routeController)), 1, 20); }
                catch (Exception) { }
            }
            return Mathf.Clamp(previewSelectedMissionId, 1, 20);
        }

        private string ResolveNodeState(int missionId)
        {
            if (routeController != null && getNodeState != null)
            {
                try
                {
                    object raw = getNodeState.Invoke(routeController, new object[] { missionId });
                    if (raw != null) return raw.ToString();
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[CARGO V2][UI_TEAM] Progression state fallback for mission {missionId}: {e.Message}");
                }
            }
            return missionId == 1 ? "Available" : "Locked";
        }

        private void RefreshDetailBoard(int missionId, string state, bool force)
        {
            if (detailText == null) return;
            if (!force && lastDetailMissionId == missionId && lastDetailState == state) return;

            SO_GameBalance.MissionBalance mission = gameBalance.GetMission(missionId);
            if (mission == null)
            {
                detailText.text = $"MISSION {missionId:00}\nDATA UNAVAILABLE";
            }
            else
            {
                detailText.text = $"{mission.city.ToUpperInvariant()} | MISSION {missionId:00} | {StateCue(state, true)}\n" +
                                  $"ENERGY {mission.energyCost}   TIME {mission.timeSeconds}s   1 STAR {mission.coin1Star:N0}   3 STAR {mission.coin3Star:N0}   XP {mission.xp}";
            }

            lastDetailMissionId = missionId;
            lastDetailState = state;
        }

        private Material ResolveMaterial(string state, bool selected)
        {
            if (selected) return selectedMaterial;
            if (string.Equals(state, "Completed", StringComparison.OrdinalIgnoreCase)) return completedMaterial;
            if (string.Equals(state, "Available", StringComparison.OrdinalIgnoreCase)) return availableMaterial;
            return lockedMaterial;
        }

        private static string StateCue(string state, bool selected)
        {
            if (selected) return "[SELECTED]";
            if (string.Equals(state, "Completed", StringComparison.OrdinalIgnoreCase)) return "[DONE] COMPLETED";
            if (string.Equals(state, "Available", StringComparison.OrdinalIgnoreCase)) return "[READY] AVAILABLE";
            return "[LOCKED]";
        }

        private static Material MakeMaterial(Color color)
        {
            Shader shader = Shader.Find("Standard") ?? Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Sprites/Default");
            if (shader == null)
            {
                Debug.LogWarning("[CARGO V2][UI_TEAM] No compatible WorldMap shader found; geometry will use Unity's safe material fallback.");
                return null;
            }
            return new Material(shader) { color = color };
        }

        private sealed class WorldMapNodeClick : MonoBehaviour
        {
            private SCR_WorldMapRuntimeDirector owner;
            private int missionId;

            public void Configure(SCR_WorldMapRuntimeDirector director, int id)
            {
                owner = director;
                missionId = id;
            }

            private void OnMouseUpAsButton()
            {
                owner?.SelectMission(missionId);
            }
        }
    }
}
