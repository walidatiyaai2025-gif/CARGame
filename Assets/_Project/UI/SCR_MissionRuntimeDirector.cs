using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_MissionRuntimeDirector : MonoBehaviour
    {
        private const string PendingMissionKey = "cargo_v2_pending_mission_id";
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private const string MissionAssetResourcePath = "CargoV2/Mission/MOD_Mission_CargoDepot";
        private static readonly Vector3 MissionOrigin = new Vector3(1000f, 0f, 1000f);
        private static SCR_MissionRuntimeDirector activeInstance;

        private readonly List<GameObject> spawnedObjects = new List<GameObject>();
        private readonly List<Material> runtimeMaterials = new List<Material>();

        private SO_GameBalance balance;
        private SO_GameBalance.MissionBalance mission;
        private Camera missionCamera;
        private int delivered;
        private int requiredDeliveries = 5;
        private float remainingSeconds;
        private bool terminal;
        private bool succeeded;
        private bool initialized;
        private bool usingRealAssetPack;

        public static bool IsRunning => activeInstance != null;

        public static bool LaunchInPlace(int missionId)
        {
            if (missionId < 1 || missionId > 20) return false;
            if (IsRunning) return false;

            GameObject host = new GameObject("CARGO_V2_InPlaceMissionRuntime");
            SCR_MissionRuntimeDirector director = host.AddComponent<SCR_MissionRuntimeDirector>();
            bool launched = director.Initialize(missionId);
            if (!launched && director != null) Destroy(director.gameObject);
            return launched;
        }

        private bool Initialize(int missionId)
        {
            if (initialized || activeInstance != null) return false;

            balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            balance.ResetToApprovedDefaults();
            mission = balance.GetMission(missionId);
            if (mission == null) return false;

            initialized = true;
            activeInstance = this;
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.Save();
            remainingSeconds = Mathf.Max(10f, mission.timeSeconds);
            BuildMissionWorld();
            return true;
        }

        private void Update()
        {
            if (!initialized || terminal) return;
            remainingSeconds -= Time.deltaTime;
            if (remainingSeconds <= 0f)
            {
                remainingSeconds = 0f;
                terminal = true;
                succeeded = false;
            }
        }

        private void BuildMissionWorld()
        {
            Shader shader = Shader.Find("Standard") ?? Shader.Find("Universal Render Pipeline/Lit");
            Material navy = CreateMaterial(shader, new Color(0.02f, 0.07f, 0.17f));
            Material gold = CreateMaterial(shader, new Color(0.78f, 0.52f, 0.08f));
            Material chrome = CreateMaterial(shader, new Color(0.42f, 0.44f, 0.48f));

            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ground.name = "MissionGround";
            ground.transform.position = MissionOrigin + new Vector3(0f, -0.3f, 2f);
            ground.transform.localScale = new Vector3(18f, 0.4f, 16f);
            SetMaterial(ground, navy);
            spawnedObjects.Add(ground);

            usingRealAssetPack = TryBuildRealAssetProps();
            if (!usingRealAssetPack)
            {
                BuildFallbackMissionProps(gold, chrome);
            }

            GameObject cameraGo = new GameObject("MissionRuntimeCamera");
            missionCamera = cameraGo.AddComponent<Camera>();
            missionCamera.depth = 100f;
            missionCamera.transform.position = MissionOrigin + new Vector3(0f, 8f, -11f);
            missionCamera.transform.LookAt(MissionOrigin + new Vector3(0f, 0.8f, 2f));
            spawnedObjects.Add(cameraGo);

            Light key = new GameObject("MissionKeyLight").AddComponent<Light>();
            key.type = LightType.Directional;
            key.intensity = 1.1f;
            key.transform.rotation = Quaternion.Euler(45f, -35f, 0f);
            spawnedObjects.Add(key.gameObject);
        }

        private bool TryBuildRealAssetProps()
        {
            GameObject source = Resources.Load<GameObject>(MissionAssetResourcePath);
            if (source == null) return false;

            Transform cargoSource = FindChildRecursive(source.transform, "CargoCrate");
            Transform bandSource = FindChildRecursive(source.transform, "CargoCrateBand");
            Transform depotSource = FindChildRecursive(source.transform, "DepotPallet");
            Transform gateLeftSource = FindChildRecursive(source.transform, "RouteGateLeft");
            Transform gateRightSource = FindChildRecursive(source.transform, "RouteGateRight");
            Transform gateTopSource = FindChildRecursive(source.transform, "RouteGateTop");
            Transform beaconSource = FindChildRecursive(source.transform, "CheckpointBeacon");

            if (cargoSource == null || bandSource == null || depotSource == null ||
                gateLeftSource == null || gateRightSource == null || gateTopSource == null || beaconSource == null)
            {
                Debug.LogWarning("CARGO V2 Mission asset exists but required named parts are incomplete; using primitive fallback.");
                return false;
            }

            GameObject environment = new GameObject("MissionReal3DEnvironment");
            environment.transform.position = MissionOrigin + new Vector3(0f, 0.15f, 5f);
            spawnedObjects.Add(environment);
            CloneModelPart(depotSource, environment.transform, "MissionReal_DepotPallet");
            CloneModelPart(gateLeftSource, environment.transform, "MissionReal_GateLeft");
            CloneModelPart(gateRightSource, environment.transform, "MissionReal_GateRight");
            CloneModelPart(gateTopSource, environment.transform, "MissionReal_GateTop");
            CloneModelPart(beaconSource, environment.transform, "MissionReal_CheckpointBeacon");

            for (int i = 0; i < requiredDeliveries; i++)
            {
                GameObject cargoHost = new GameObject($"MissionCargo_{i + 1:00}");
                float x = -4f + (i % 3) * 4f;
                float z = -2f + (i / 3) * 3f;
                cargoHost.transform.position = MissionOrigin + new Vector3(x, 0.15f, z);
                cargoHost.transform.localScale = Vector3.one * 1.35f;
                CloneModelPart(cargoSource, cargoHost.transform, "CargoCrateMesh");
                CloneModelPart(bandSource, cargoHost.transform, "CargoCrateBandMesh");
                BoxCollider collider = cargoHost.AddComponent<BoxCollider>();
                collider.center = new Vector3(0f, 0.45f, 0f);
                collider.size = new Vector3(1.35f, 1.05f, 1.05f);
                MissionCargoClick click = cargoHost.AddComponent<MissionCargoClick>();
                click.Owner = this;
                spawnedObjects.Add(cargoHost);
            }

            return true;
        }

        private static GameObject CloneModelPart(Transform source, Transform parent, string objectName)
        {
            GameObject clone = Instantiate(source.gameObject, parent);
            clone.name = objectName;
            clone.transform.localPosition = Vector3.zero;
            clone.transform.localRotation = Quaternion.identity;
            clone.transform.localScale = Vector3.one;
            return clone;
        }

        private static Transform FindChildRecursive(Transform root, string childName)
        {
            if (root == null) return null;
            if (string.Equals(root.name, childName, StringComparison.Ordinal)) return root;
            for (int i = 0; i < root.childCount; i++)
            {
                Transform match = FindChildRecursive(root.GetChild(i), childName);
                if (match != null) return match;
            }
            return null;
        }

        private void BuildFallbackMissionProps(Material gold, Material chrome)
        {
            GameObject depot = GameObject.CreatePrimitive(PrimitiveType.Cube);
            depot.name = "MissionDepot_Fallback";
            depot.transform.position = MissionOrigin + new Vector3(0f, 1.2f, 7f);
            depot.transform.localScale = new Vector3(7f, 2.4f, 1.4f);
            SetMaterial(depot, chrome);
            spawnedObjects.Add(depot);

            for (int i = 0; i < requiredDeliveries; i++)
            {
                GameObject cargo = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cargo.name = $"MissionCargo_{i + 1:00}";
                float x = -4f + (i % 3) * 4f;
                float z = -2f + (i / 3) * 3f;
                cargo.transform.position = MissionOrigin + new Vector3(x, 0.8f, z);
                cargo.transform.localScale = new Vector3(1.5f, 1.5f, 1.5f);
                SetMaterial(cargo, gold);
                MissionCargoClick click = cargo.AddComponent<MissionCargoClick>();
                click.Owner = this;
                spawnedObjects.Add(cargo);
            }

            GameObject gateLeft = GameObject.CreatePrimitive(PrimitiveType.Cube);
            gateLeft.name = "MissionGateLeft_Fallback";
            gateLeft.transform.position = MissionOrigin + new Vector3(-4.5f, 2f, 5f);
            gateLeft.transform.localScale = new Vector3(0.5f, 4f, 0.5f);
            SetMaterial(gateLeft, gold);
            spawnedObjects.Add(gateLeft);

            GameObject gateRight = GameObject.CreatePrimitive(PrimitiveType.Cube);
            gateRight.name = "MissionGateRight_Fallback";
            gateRight.transform.position = MissionOrigin + new Vector3(4.5f, 2f, 5f);
            gateRight.transform.localScale = new Vector3(0.5f, 4f, 0.5f);
            SetMaterial(gateRight, gold);
            spawnedObjects.Add(gateRight);
        }

        private Material CreateMaterial(Shader shader, Color color)
        {
            if (shader == null) return null;
            Material material = new Material(shader) { color = color };
            runtimeMaterials.Add(material);
            return material;
        }

        private static void SetMaterial(GameObject go, Material material)
        {
            Renderer renderer = go.GetComponent<Renderer>();
            if (renderer != null && material != null) renderer.sharedMaterial = material;
        }

        internal void Deliver(GameObject cargo)
        {
            if (!initialized || terminal || cargo == null || !cargo.activeSelf) return;
            cargo.SetActive(false);
            delivered++;
            if (delivered >= requiredDeliveries)
            {
                terminal = true;
                succeeded = true;
                PlayerPrefs.SetInt(CompletionHandoffKey, mission.missionId);
                PlayerPrefs.Save();
            }
        }

        private void RetryMission()
        {
            if (!initialized) return;
            delivered = 0;
            terminal = false;
            succeeded = false;
            remainingSeconds = Mathf.Max(10f, mission.timeSeconds);
            foreach (GameObject go in spawnedObjects)
            {
                if (go != null && go.name.StartsWith("MissionCargo_", StringComparison.Ordinal)) go.SetActive(true);
            }
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.Save();
        }

        private void OnGUI()
        {
            if (!initialized || mission == null) return;

            const int width = 430;
            GUILayout.BeginArea(new Rect(24, 24, width, 280), GUI.skin.box);
            GUILayout.Label($"CARGO V2 — MISSION {mission.missionId:00}");
            GUILayout.Label($"{mission.city}  |  Time {Mathf.CeilToInt(remainingSeconds)}s");
            GUILayout.Label($"Delivered: {delivered}/{requiredDeliveries}");
            GUILayout.Label(usingRealAssetPack ? "Visuals: REAL 3D MISSION ASSET PACK" : "Visuals: SAFE PRIMITIVE FALLBACK");
            GUILayout.Label("Tap/click each cargo crate to deliver it to the depot.");

            if (terminal)
            {
                GUILayout.Space(8);
                GUILayout.Label(succeeded ? "MISSION COMPLETE — HANDOFF READY" : "TIME EXPIRED");
                if (GUILayout.Button("RETRY")) RetryMission();
                if (GUILayout.Button("BACK TO MAP")) Destroy(gameObject);
            }
            GUILayout.EndArea();
        }

        private void OnDestroy()
        {
            if (activeInstance == this) activeInstance = null;
            PlayerPrefs.DeleteKey(PendingMissionKey);
            PlayerPrefs.Save();

            foreach (GameObject go in spawnedObjects)
            {
                if (go != null) Destroy(go);
            }
            spawnedObjects.Clear();

            foreach (Material material in runtimeMaterials)
            {
                if (material != null) Destroy(material);
            }
            runtimeMaterials.Clear();

            if (balance != null) Destroy(balance);
        }

        private sealed class MissionCargoClick : MonoBehaviour
        {
            public SCR_MissionRuntimeDirector Owner;
            private void OnMouseUpAsButton() { Owner?.Deliver(gameObject); }
        }
    }
}
