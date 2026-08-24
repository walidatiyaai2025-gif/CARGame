#if UNITY_EDITOR
using System;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace CargoV2.QA.Editor
{
    public static class SCR_CargoV2IntegrationPreviewReadiness
    {
        private static readonly string[] RequiredSceneTokens = { "Splash", "Loading", "WorldMap" };
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

        private const string MissionResourcePath = "CargoV2/Mission/MOD_Mission_CargoDepot";

        [MenuItem("CARGO V2/QA/Report Integration Preview Readiness")]
        public static void Report()
        {
            int pass = 0;
            int hold = 0;

            foreach (string token in RequiredSceneTokens)
            {
                bool present = EditorBuildSettings.scenes.Any(scene => scene.enabled &&
                    scene.path.IndexOf(token, StringComparison.OrdinalIgnoreCase) >= 0);
                Record(present, $"Enabled build scene contains '{token}'", ref pass, ref hold);
            }

            foreach (string typeName in RequiredTypes)
            {
                Record(FindType(typeName) != null, $"Runtime contract present: {typeName}", ref pass, ref hold);
            }

            Record(Resources.Load<GameObject>(MissionResourcePath) != null,
                $"Mission Resources asset resolves: {MissionResourcePath}", ref pass, ref hold);

            string verdict = hold == 0 ? "STRUCTURAL READY" : "HOLD";
            Debug.Log($"[CARGO V2][QA] INTEGRATION PREVIEW READINESS — {verdict}; PASS={pass}, HOLD={hold}. This report is read-only and is NOT Unity Play Mode, visual, FPS, gameplay, or release QA PASS.");
        }

        private static void Record(bool ok, string message, ref int pass, ref int hold)
        {
            if (ok)
            {
                pass++;
                Debug.Log($"[CARGO V2][QA][PASS] {message}");
            }
            else
            {
                hold++;
                Debug.LogWarning($"[CARGO V2][QA][HOLD] {message}");
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
#endif
