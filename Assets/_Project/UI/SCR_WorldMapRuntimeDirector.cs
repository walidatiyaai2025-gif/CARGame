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
        private const string MarkerResourcePath = "CargoV2/WorldMap/MOD_WorldMap_MarkerPack";

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
        [SerializeField] private float realMarkerScale = 0.82f;

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
        private GameObject markerPackPrefab;
        private bool markerLoadAttempted;
        private bool markerWarningLogged;
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
            EnsureMarkerPack();
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

        private void EnsureMarkerPack()
        {
            if (markerLoadAttempted) return;
            markerLoadAttempted = true;
            markerPackPrefab = Resources.Load<GameObject>(MarkerResourcePath);
            if (markerPackPrefab == null)
            {
                LogMarkerFallbackOnce($"Resources marker pack not found at {MarkerResourcePath}; primitive node fallback remains active.");
                return;
            }

            string[] requiredParts = { "MissionMarker_Base", "MissionMarker_GoldRing", "MissionMarker_Beacon" };
            for (int i = 0; i < requiredParts.Length; i++)
            {
                if (FindDescendant(markerPackPrefab.transform, requiredParts[i]) != null) continue;
                LogMarkerFallbackOnce($"Resources marker pack is missing required part {requiredParts[i]}; primitive node fallback remains active.");
                markerPackPrefab = null;
                return;
            }
        }

        private void LogMarkerFallbackOnce(string message)
        {
            if (markerWarningLogged) return;
            markerWarningLogged = true;
            Debug.LogWarning($"[CARGO V2][UI_TEAM] {message}");
        }

        private static Transform FindDescendant(Transform root, string targetName)
        {
            if (root == null || string.IsNullOrWhiteSpace(targetName)) return null;
            Transform[] transforms = root.GetComponentsInChildren<Transform>(true);
            for (int i = 0; i < transforms.Length; i++)
            {
                if (string.Equals(transforms[i].name, targetName, StringComparison.Ordinal)) return transforms[i];
            }
            return null;
        }

        private bool TryAttachMissionMarker(GameObject nodeObject, int missionId)
        {
            if (nodeObject == null) return false;
            EnsureMarkerPack();
            if (markerPackPrefab == null) return false;

            try
            {
                GameObject markerInstance = Instantiate(markerPackPrefab, nodeObject.transform, false);
                markerInstance.name = $"MissionMarkerVisual_{missionId:00}";
                markerInstance.transform.localPosition = Vector3.zero;
                markerInstance.transform.localRotation = Quaternion.identity;
                markerInstance.transform.localScale = Vector3.one * Mathf.Clamp(realMarkerScale, 0.1f, 4f);

                Renderer[] renderers = markerInstance.GetComponentsInChildren<Renderer>(true);
                int enabledMissionRenderers = 0;
                for (int i = 0; i < renderers.Length; i++)
                {
                    bool keep = IsMissionMarkerPart(renderers[i].transform, markerInstance.transform);
                    renderers[i].enabled = keep;
                    if (keep) enabledMissionRenderers++;
                }

                Collider[] colliders = markerInstance.GetComponentsInChildren<Collider>(true);
                for (int i = 0; i < colliders.Length; i++) colliders[i].enabled = false;

                if (enabledMissionRenderers == 0)
                {
                    Destroy(markerInstance);
                    LogMarkerFallbackOnce("Resources marker pack contained no renderable MissionMarker geometry; primitive node fallback remains active.");
                    return false;
                }

                return true;
            }
            catch (Exception e)
            {
                LogMarkerFallbackOnce($"Resources marker instantiation failed safely: {e.Message}");
                return false;
            }
        }

        private static bool IsMissionMarkerPart(Transform current, Transform instanceRoot)
        {
            Transform cursor = current;
            while (cursor != null && cursor != instanceRoot)
            {
                if (cursor.name.StartsWith("MissionMarker_", StringComparison.Ordinal)) return true;
                cursor = cursor.parent;
            }
            return false;
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
                Renderer fallbackRenderer = nodeObject.GetComponent<Renderer>();
                WorldMapNodeClick fallbackClick = nodeObject.AddComponent<WorldMapNodeClick>();
                fallbackClick.Configure(this, missionId);
                bool hasRealMarker = TryAttachMissionMarker(nodeObject, missionId);
                if (fallbackRenderer != null) fallbackRenderer.enabled = !hasRealMarker;

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
                    Renderer = fallbackRenderer,
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
                    if (result is bool accepted && !accepted)
                    {
                        SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Error);
                        return;
                    }
                    SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
                    RefreshStates(true);
                }
                catch (Exception e)
                {
                    Debug.LogWarning($"[CARGO V2][UI_TEAM] Mission {missionId} selection failed safely: {e.Message}");
                    SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Error);
                }
                return;
            }

            if (missionId != 1)
            {
                Debug.Log($"[CARGO V2][UI_TEAM] Mission {missionId} is locked in visual-preview mode; progression controller is not present.");
                SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Error);
                return;
            }

            previewSelectedMissionId = missionId;
            Debug.Log($"[CARGO V2][UI_TEAM] Mission {missionId} selected in visual-preview mode; progression controller not present on this branch.");
            SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
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
                        string city = mission == null ? L("mission") : Term(mission.city);
                        node.Label.text = $"{Two(node.MissionId)}  {city}\n{StateCue(state, selected)}";
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
                detailText.text = $"{L("mission")} {Two(missionId)}\n{L("world.dataUnavailable")}";
            }
            else
            {
                detailText.text = $"{Term(mission.city)} | {L("mission")} {Two(missionId)} | {StateCue(state, true)}\n" +
                                  $"{L("world.energy")} {Num(mission.energyCost)}   {L("world.time")} {Num(mission.timeSeconds)}s   " +
                                  $"{L("world.star1")} {Num(mission.coin1Star)}   {L("world.star3")} {Num(mission.coin3Star)}   XP {Num(mission.xp)}";
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
            if (selected) return $"[✓] {L("state.selected")}";
            if (string.Equals(state, "Completed", StringComparison.OrdinalIgnoreCase)) return $"[✓] {L("state.completed")}";
            if (string.Equals(state, "Available", StringComparison.OrdinalIgnoreCase)) return $"[▶] {L("state.available")}";
            return $"[🔒] {L("state.locked")}";
        }

        private static string L(string key)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.Get(key) : key;
        }

        private static string Num(long value)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.FormatInteger(value) : value.ToString("N0");
        }

        private static string Two(int value)
        {
            string raw = Mathf.Clamp(value, 0, 99).ToString("00");
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.LocalizeDigits(raw) : raw;
        }

        private static string Term(string value)
        {
            return CargoV2LocalizationTerms.Term(value);
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
