using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_MissionRuntimeDirector : MonoBehaviour
    {
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private static readonly Vector3 MissionOrigin = new Vector3(1000f, 0f, 1000f);

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

        public static bool LaunchInPlace(int missionId)
        {
            if (missionId < 1 || missionId > 20) return false;
            if (FindObjectOfType<SCR_MissionRuntimeDirector>() != null) return false;

            GameObject host = new GameObject("CARGO_V2_InPlaceMissionRuntime");
            SCR_MissionRuntimeDirector director = host.AddComponent<SCR_MissionRuntimeDirector>();
            return director.Initialize(missionId);
        }

        private bool Initialize(int missionId)
        {
            balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            balance.ResetToApprovedDefaults();
            mission = balance.GetMission(missionId);
            if (mission == null)
            {
                Destroy(gameObject);
                return false;
            }

            remainingSeconds = Mathf.Max(10f, mission.timeSeconds);
            BuildMissionWorld();
            return true;
        }

        private void Update()
        {
            if (terminal) return;
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

            GameObject depot = GameObject.CreatePrimitive(PrimitiveType.Cube);
            depot.name = "MissionDepot";
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
            gateLeft.transform.position = MissionOrigin + new Vector3(-4.5f, 2f, 5f);
            gateLeft.transform.localScale = new Vector3(0.5f, 4f, 0.5f);
            SetMaterial(gateLeft, gold);
            spawnedObjects.Add(gateLeft);

            GameObject gateRight = GameObject.CreatePrimitive(PrimitiveType.Cube);
            gateRight.transform.position = MissionOrigin + new Vector3(4.5f, 2f, 5f);
            gateRight.transform.localScale = new Vector3(0.5f, 4f, 0.5f);
            SetMaterial(gateRight, gold);
            spawnedObjects.Add(gateRight);

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
            if (terminal || cargo == null || !cargo.activeSelf) return;
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
            const int width = 430;
            GUILayout.BeginArea(new Rect(24, 24, width, 260), GUI.skin.box);
            GUILayout.Label($"CARGO V2 — MISSION {mission.missionId:00}");
            GUILayout.Label($"{mission.city}  |  Time {Mathf.CeilToInt(remainingSeconds)}s");
            GUILayout.Label($"Delivered: {delivered}/{requiredDeliveries}");
            GUILayout.Label("Tap/click each gold cargo crate to deliver it to the depot.");

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
