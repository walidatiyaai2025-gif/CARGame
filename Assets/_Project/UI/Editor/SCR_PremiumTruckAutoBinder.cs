using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI.Editor
{
    [InitializeOnLoad]
    public static class SCR_PremiumTruckAutoBinder
    {
        private const string SessionKey = "CARGO_V2_PREMIUM_TRUCK_AUTOBIND_V2";
        private const string ModelPath = "Assets/_Project/Generated/MOD_Truck_Premium.obj";
        private const string SplashScenePath = "Assets/_Project/Scenes/01_Splash.unity";
        private const string LoadingScenePath = "Assets/_Project/Scenes/02_Loading.unity";
        private const string RootName = "PremiumTruck3D";

        static SCR_PremiumTruckAutoBinder()
        {
            EditorApplication.delayCall += TryBindOnce;
        }

        [MenuItem("CARGO V2/UI/Bind Premium 3D Truck Only")]
        public static void BindFromMenu()
        {
            BindModelIntoScenes(force: true);
        }

        private static void TryBindOnce()
        {
            if (EditorApplication.isCompiling || EditorApplication.isUpdating)
            {
                EditorApplication.delayCall += TryBindOnce;
                return;
            }

            if (SessionState.GetBool(SessionKey, false))
            {
                return;
            }

            SessionState.SetBool(SessionKey, true);
            BindModelIntoScenes(force: false);
        }

        private static void BindModelIntoScenes(bool force)
        {
            AssetDatabase.ImportAsset(ModelPath, ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
            GameObject model = AssetDatabase.LoadAssetAtPath<GameObject>(ModelPath);
            if (model == null)
            {
                if (force)
                {
                    Debug.LogError($"[CARGO V2][UI_TEAM] Premium truck model is missing or not imported: {ModelPath}");
                }
                return;
            }

            string activeScenePath = SceneManager.GetActiveScene().path;
            bool restoreScene = !string.IsNullOrWhiteSpace(activeScenePath) && AssetDatabase.LoadAssetAtPath<SceneAsset>(activeScenePath) != null;

            try
            {
                BindScene(SplashScenePath, model, loadingMode: false);
                BindScene(LoadingScenePath, model, loadingMode: true);
                AssetDatabase.SaveAssets();
                Debug.Log("[CARGO V2][UI_TEAM] Premium 3D truck auto-bound into Splash and Loading.");
            }
            finally
            {
                if (restoreScene)
                {
                    EditorSceneManager.OpenScene(activeScenePath, OpenSceneMode.Single);
                }
            }
        }

        private static void BindScene(string scenePath, GameObject modelAsset, bool loadingMode)
        {
            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(scenePath) == null)
            {
                return;
            }

            Scene scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);
            GameObject existing = GameObject.Find(RootName);
            if (existing != null)
            {
                Object.DestroyImmediate(existing);
            }

            GameObject root = new GameObject(RootName);
            SceneManager.MoveGameObjectToScene(root, scene);

            GameObject instance = PrefabUtility.InstantiatePrefab(modelAsset, scene) as GameObject;
            if (instance == null)
            {
                Object.DestroyImmediate(root);
                Debug.LogError($"[CARGO V2][UI_TEAM] Could not instantiate premium truck in {scenePath}.");
                return;
            }

            instance.name = "MOD_Truck_Premium_Instance";
            instance.transform.SetParent(root.transform, false);

            SCR_PremiumTruck3D presenter = root.AddComponent<SCR_PremiumTruck3D>();
            presenter.Configure(loadingMode);

            EditorUtility.SetDirty(root);
            EditorUtility.SetDirty(presenter);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
        }
    }
}
