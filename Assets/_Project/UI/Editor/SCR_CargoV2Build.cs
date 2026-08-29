#if UNITY_EDITOR
using System;
using System.IO;
using CargoV2.Logic;
using CargoV2.UI;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace CargoV2.EditorTools
{
    public static class SCR_CargoV2Build
    {
        private static readonly string[] Scenes =
        {
            "Assets/_Project/Scenes/01_Splash.unity",
            "Assets/_Project/Scenes/02_Loading.unity",
            "Assets/_Project/Scenes/04_WorldMap.unity",
        };

        private const string MissionResourcePath = "CargoV2/Mission/MOD_Mission_CargoDepot";
        private const string WorldMapResourcePath = "CargoV2/WorldMap/MOD_WorldMap_MarkerPack";
        private const string TruckResourcePath = "CargoV2/Truck/MOD_Truck_Premium";

        [MenuItem("CARGO V2/Build/Validate Unity Project")]
        public static void ValidateMenu()
        {
            ValidateOrThrow();
            Debug.Log("[CARGO V2][BUILD] Unity project validation PASS.");
        }

        public static void ValidateBatch()
        {
            ValidateOrThrow();
            Debug.Log("[CARGO V2][BUILD] Batch validation PASS.");
        }

        [MenuItem("CARGO V2/Build/Build Android APK")]
        public static void BuildAndroidMenu()
        {
            BuildAndroid();
        }

        public static void BuildAndroidBatch()
        {
            BuildAndroid();
        }

        private static void ValidateOrThrow()
        {
            AssetDatabase.Refresh();

            foreach (string scene in Scenes)
            {
                if (!File.Exists(scene)) throw new InvalidOperationException($"Missing required scene: {scene}");
            }

            if (typeof(SCR_WorldMapRouteController) == null ||
                typeof(SCR_WorldMapRuntimeDirector) == null ||
                typeof(SCR_WorldMapMissionDeploy) == null ||
                typeof(SCR_MissionRuntimeDirector) == null ||
                typeof(SCR_LogisticsBusinessRuntime) == null)
            {
                throw new InvalidOperationException("Required CARGO V2 runtime contract failed to compile.");
            }

            RequireResource(MissionResourcePath);
            RequireResource(WorldMapResourcePath);
            RequireResource(TruckResourcePath);

            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(Scenes[0], true),
                new EditorBuildSettingsScene(Scenes[1], true),
                new EditorBuildSettingsScene(Scenes[2], true),
            };
        }

        private static void RequireResource(string path)
        {
            if (Resources.Load<GameObject>(path) == null)
            {
                throw new InvalidOperationException($"Required runtime Resources asset does not resolve: {path}");
            }
        }

        private static void BuildAndroid()
        {
            ValidateOrThrow();

            if (!EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Android, BuildTarget.Android))
            {
                throw new InvalidOperationException("Unable to switch Unity build target to Android. Install Android Build Support for Unity 2022.3.75f1.");
            }

            PlayerSettings.productName = "CARGO V2";
            PlayerSettings.companyName = "WALKA";
            PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "com.walka.cargov2");
            PlayerSettings.bundleVersion = "2.0.0";
            PlayerSettings.Android.bundleVersionCode = 20000;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel23;
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.colorSpace = ColorSpace.Linear;

            string output = Environment.GetEnvironmentVariable("CARGO_V2_ANDROID_OUTPUT");
            if (string.IsNullOrWhiteSpace(output)) output = "Builds/CargoV2/CARGO-V2.apk";
            string directory = Path.GetDirectoryName(output);
            if (!string.IsNullOrWhiteSpace(directory)) Directory.CreateDirectory(directory);

            BuildReport report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
            {
                scenes = Scenes,
                locationPathName = output,
                target = BuildTarget.Android,
                options = BuildOptions.None,
            });

            if (report.summary.result != BuildResult.Succeeded)
            {
                throw new InvalidOperationException($"CARGO V2 Android build failed: {report.summary.result}; errors={report.summary.totalErrors} warnings={report.summary.totalWarnings}");
            }

            Debug.Log($"[CARGO V2][BUILD] Android APK PASS: {Path.GetFullPath(output)} ({report.summary.totalSize} bytes)");
        }
    }
}
#endif
