using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI.Editor
{
    [InitializeOnLoad]
    public static class SCR_CargoPreviewStartup
    {
        private const string SplashScenePath = "Assets/_Project/Scenes/01_Splash.unity";
        private const string SessionKey = "CARGO_V2_PREVIEW_SPLASH_OPENED";

        static SCR_CargoPreviewStartup()
        {
            EditorApplication.delayCall += OpenSplashWhenReady;
        }

        [MenuItem("CARGO V2/Preview/Open 01 Splash")]
        public static void OpenSplashFromMenu()
        {
            OpenSplash(force: true);
        }

        private static void OpenSplashWhenReady()
        {
            if (EditorApplication.isCompiling || EditorApplication.isUpdating || EditorApplication.isPlayingOrWillChangePlaymode)
            {
                EditorApplication.delayCall += OpenSplashWhenReady;
                return;
            }

            if (SessionState.GetBool(SessionKey, false))
            {
                return;
            }

            Scene active = SceneManager.GetActiveScene();
            bool isUntitled = string.IsNullOrWhiteSpace(active.path) || active.name == "Untitled";
            if (!isUntitled)
            {
                SessionState.SetBool(SessionKey, true);
                return;
            }

            OpenSplash(force: false);
        }

        private static void OpenSplash(bool force)
        {
            SceneAsset splash = AssetDatabase.LoadAssetAtPath<SceneAsset>(SplashScenePath);
            if (splash == null)
            {
                if (force)
                {
                    Debug.LogError($"[CARGO V2] Preview splash scene is missing: {SplashScenePath}");
                }
                return;
            }

            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            {
                return;
            }

            EditorSceneManager.OpenScene(SplashScenePath, OpenSceneMode.Single);
            SessionState.SetBool(SessionKey, true);
            Selection.activeObject = splash;
            EditorGUIUtility.PingObject(splash);
            Debug.Log("[CARGO V2] Opened 01_Splash for premium Art Pass preview.");
        }
    }
}
