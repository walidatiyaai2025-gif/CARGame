using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace CargoV2.QA
{
    public sealed class SCR_CargoV2RuntimeContractProbe : MonoBehaviour
    {
        private static readonly string[] RequiredTypes =
        {
            "CargoV2.Logic.SCR_WorldMapRouteController",
            "CargoV2.Logic.SCR_WorldMapPersistenceBridge",
            "CargoV2.Logic.SCR_MissionCompletionHandoffBridge",
            "CargoV2.Logic.SCR_MissionRewardStore",
            "CargoV2.UI.SCR_WorldMapMissionDeployGateway",
            "CargoV2.UI.SCR_WorldMapTouchInputBridge",
            "CargoV2.UI.SCR_MissionRuntimeDirector",
        };

        private static readonly string[] RequiredMissionModelParts =
        {
            "CargoCrate",
            "CargoCrateBand",
            "DepotPallet",
            "RouteGateLeft",
            "RouteGateRight",
            "RouteGateTop",
            "CheckpointBeacon",
        };

        private const string MissionResourcePath = "CargoV2/Mission/MOD_Mission_CargoDepot";

        [ContextMenu("Run CARGO V2 Runtime Contract Probe")]
        public void RunProbe()
        {
            int pass = 0;
            int hold = 0;
            foreach (string typeName in RequiredTypes)
            {
                Type type = FindType(typeName);
                if (type == null)
                {
                    hold++;
                    Debug.LogWarning($"[CARGO V2][QA][HOLD] Missing runtime contract type: {typeName}");
                    continue;
                }

                pass++;
                Debug.Log($"[CARGO V2][QA][PASS] Runtime contract type present: {typeName}");
            }

            InspectWorldMapController(ref pass, ref hold);
            InspectRewardStore(ref pass, ref hold);
            InspectMissionResource(ref pass, ref hold);

            Debug.Log($"[CARGO V2][QA] READ-ONLY CONTRACT PROBE COMPLETE — PASS={pass}, HOLD={hold}. This is structural runtime evidence only; it is not visual/FPS/gameplay QA PASS.");
        }

        private static void InspectWorldMapController(ref int pass, ref int hold)
        {
            Type type = FindType("CargoV2.Logic.SCR_WorldMapRouteController");
            if (type == null) return;

            PropertyInfo missionCount = type.GetProperty("MissionCount", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            MethodInfo getMission = type.GetMethod("GetMission", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (missionCount == null || getMission == null)
            {
                hold++;
                Debug.LogWarning("[CARGO V2][QA][HOLD] WorldMap controller API surface is incomplete: MissionCount/GetMission not both available.");
                return;
            }

            UnityEngine.Object instance = FindObjectOfType(type);
            if (instance == null)
            {
                hold++;
                Debug.LogWarning("[CARGO V2][QA][HOLD] WorldMap controller type exists but no live instance is present in the current scene.");
                return;
            }

            object value = missionCount.GetValue(instance, null);
            int count = value is int intValue ? intValue : -1;
            if (count == 20)
            {
                pass++;
                Debug.Log("[CARGO V2][QA][PASS] Live WorldMap controller reports exactly 20 missions.");
            }
            else
            {
                hold++;
                Debug.LogWarning($"[CARGO V2][QA][HOLD] Live WorldMap controller mission count is {count}; expected 20.");
            }
        }

        private static void InspectRewardStore(ref int pass, ref int hold)
        {
            Type type = FindType("CargoV2.Logic.SCR_MissionRewardStore");
            if (type == null) return;

            MethodInfo readSnapshot = type.GetMethod("TryReadSnapshot", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            if (readSnapshot == null)
            {
                hold++;
                Debug.LogWarning("[CARGO V2][QA][HOLD] Mission reward store exists but TryReadSnapshot is unavailable.");
                return;
            }

            pass++;
            Debug.Log("[CARGO V2][QA][PASS] Mission reward store exposes read-only snapshot inspection. Probe intentionally does not invoke settlement or mutate PlayerPrefs.");
        }

        private static void InspectMissionResource(ref int pass, ref int hold)
        {
            GameObject prefab = Resources.Load<GameObject>(MissionResourcePath);
            if (prefab == null)
            {
                hold++;
                Debug.LogWarning($"[CARGO V2][QA][HOLD] Runtime Mission model does not resolve at Resources path: {MissionResourcePath}");
                return;
            }

            pass++;
            Debug.Log($"[CARGO V2][QA][PASS] Runtime Mission model resolves: {MissionResourcePath}");

            var names = new HashSet<string>(StringComparer.Ordinal);
            Transform[] transforms = prefab.GetComponentsInChildren<Transform>(true);
            foreach (Transform transform in transforms)
            {
                if (transform != null && !string.IsNullOrEmpty(transform.name)) names.Add(transform.name);
            }

            foreach (string requiredPart in RequiredMissionModelParts)
            {
                if (names.Contains(requiredPart))
                {
                    pass++;
                    Debug.Log($"[CARGO V2][QA][PASS] Runtime Mission model contains required named part: {requiredPart}");
                }
                else
                {
                    hold++;
                    Debug.LogWarning($"[CARGO V2][QA][HOLD] Runtime Mission model is missing required named part: {requiredPart}");
                }
            }
        }

        private static Type FindType(string fullName)
        {
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type type = assembly.GetType(fullName, false);
                if (type != null) return type;
            }
            return null;
        }
    }
}
