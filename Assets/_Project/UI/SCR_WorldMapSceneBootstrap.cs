using System;
using CargoV2.Logic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    /// <summary>
    /// Deterministic runtime bootstrap for the source-controlled 04_WorldMap scene.
    /// Keeps the scene intentionally minimal while guaranteeing progression,
    /// persistence/completion bridges and a usable 3D camera/light rig are wired.
    /// </summary>
    public static class SCR_WorldMapSceneBootstrap
    {
        private static bool sceneHookRegistered;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void RegisterSceneHook()
        {
            if (sceneHookRegistered) SceneManager.sceneLoaded -= HandleSceneLoaded;
            SceneManager.sceneLoaded += HandleSceneLoaded;
            sceneHookRegistered = true;
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void InstallInitialScene()
        {
            Install(SceneManager.GetActiveScene());
        }

        private static void HandleSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            Install(scene);
        }

        private static void Install(Scene scene)
        {
            if (!scene.IsValid() || !scene.isLoaded || !IsWorldMapScene(scene.name)) return;

            Application.targetFrameRate = 60;

            SCR_WorldMapRouteController controller = UnityEngine.Object.FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null)
            {
                GameObject controllerHost = new GameObject("CARGO_V2_WorldMapRouteController");
                controller = controllerHost.AddComponent<SCR_WorldMapRouteController>();
            }

            // Do not rely on ordering between independent RuntimeInitialize hooks.
            // These bridges are required for first-frame save restoration and for a
            // completion handoff that may already exist after a crash/relaunch.
            if (controller.GetComponent<SCR_WorldMapPersistenceBridge>() == null)
            {
                controller.gameObject.AddComponent<SCR_WorldMapPersistenceBridge>();
            }
            if (controller.GetComponent<SCR_MissionCompletionHandoffBridge>() == null)
            {
                controller.gameObject.AddComponent<SCR_MissionCompletionHandoffBridge>();
            }

            Camera camera = Camera.main;
            if (camera == null)
            {
                GameObject cameraHost = new GameObject("Main Camera");
                cameraHost.tag = "MainCamera";
                camera = cameraHost.AddComponent<Camera>();
                cameraHost.AddComponent<AudioListener>();
                camera.transform.position = new Vector3(0f, 7.5f, -16f);
                camera.transform.rotation = Quaternion.Euler(18f, 0f, 0f);
                camera.backgroundColor = new Color(0.015f, 0.035f, 0.075f);
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.nearClipPlane = 0.1f;
                camera.farClipPlane = 500f;
            }

            if (UnityEngine.Object.FindObjectOfType<Light>() == null)
            {
                GameObject lightHost = new GameObject("CARGO_V2_WorldMapKeyLight");
                Light light = lightHost.AddComponent<Light>();
                light.type = LightType.Directional;
                light.intensity = 1.15f;
                light.color = new Color(1f, 0.94f, 0.82f);
                light.transform.rotation = Quaternion.Euler(48f, -32f, 0f);
            }
        }

        private static bool IsWorldMapScene(string sceneName)
        {
            if (string.IsNullOrWhiteSpace(sceneName)) return false;
            return sceneName.IndexOf("WorldMap", StringComparison.OrdinalIgnoreCase) >= 0 ||
                   sceneName.StartsWith("04_", StringComparison.OrdinalIgnoreCase);
        }
    }
}
