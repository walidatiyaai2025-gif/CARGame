using System;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI.Editor
{
    public sealed class SCR_UIArtBinder : IPreprocessBuildWithReport
    {
        private const string SplashScenePath = "Assets/_Project/Scenes/01_Splash.unity";
        private const string LoadingScenePath = "Assets/_Project/Scenes/02_Loading.unity";
        private const string TruckModelAssetPath = "Assets/_Project/Generated/MOD_Truck_Premium.obj";
        private const string TruckModelRootName = "PremiumTruck3D";

        public int callbackOrder => -500;

        public void OnPreprocessBuild(BuildReport report)
        {
            BindPremiumArtOrThrow();
        }

        [MenuItem("CARGO V2/UI/Bind Premium Art")]
        public static void BindPremiumArtMenu()
        {
            BindPremiumArtOrThrow();
            Debug.Log("[CARGO V2][UI_TEAM] Premium art + real 3D truck bound into Splash + Loading scenes.");
        }

        public static void BindPremiumArtOrThrow()
        {
            Sprite logo = ResolveSprite(SCR_UIManager.LogoAssetPath, required: true);
            Sprite truckFallback = ResolveSprite(SCR_UIManager.TruckAssetPath, required: false);
            Sprite truckAlt = ResolveSprite(SCR_UIManager.TruckAltAssetPath, required: false);
            Sprite glow = ResolveSprite(SCR_UIManager.GlowAssetPath, required: true);
            GameObject truckModel = ResolveModel(TruckModelAssetPath);

            string activeScenePath = SceneManager.GetActiveScene().path;
            bool activeSceneWasSaved = !string.IsNullOrWhiteSpace(activeScenePath);

            try
            {
                BindScene(SplashScenePath, logo, truckFallback, truckAlt, glow, truckModel);
                BindScene(LoadingScenePath, logo, truckFallback, truckAlt, glow, truckModel);
                AssetDatabase.SaveAssets();
            }
            finally
            {
                if (activeSceneWasSaved && AssetDatabase.LoadAssetAtPath<SceneAsset>(activeScenePath) != null)
                {
                    EditorSceneManager.OpenScene(activeScenePath, OpenSceneMode.Single);
                }
            }
        }

        private static GameObject ResolveModel(string assetPath)
        {
            AssetDatabase.ImportAsset(
                assetPath,
                ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);

            GameObject model = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
            if (model == null)
            {
                throw new BuildFailedException(
                    $"[CARGO V2][UI_TEAM] Required real 3D truck model is missing or failed Unity import: {assetPath}. " +
                    "PR #256 must provide a valid source-controlled OBJ/MTL checkpoint before release QA.");
            }

            return model;
        }

        private static Sprite ResolveSprite(string assetPath, bool required)
        {
            if (AssetDatabase.LoadMainAssetAtPath(assetPath) == null)
            {
                if (required)
                {
                    throw new BuildFailedException(
                        $"[CARGO V2][UI_TEAM] Required Art Pass asset is missing: {assetPath}. " +
                        "PR #256 (or its approved replacement) must land before a release build.");
                }

                return null;
            }

            AssetDatabase.ImportAsset(
                assetPath,
                ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);

            Sprite sprite = AssetDatabase.LoadAssetAtPath<Sprite>(assetPath);
            if (sprite != null)
            {
                return sprite;
            }

            UnityEngine.Object[] importedObjects = AssetDatabase.LoadAllAssetsAtPath(assetPath);
            for (int i = 0; i < importedObjects.Length; i++)
            {
                if (importedObjects[i] is Sprite importedSprite)
                {
                    return importedSprite;
                }
            }

            if (required)
            {
                throw new BuildFailedException(
                    $"[CARGO V2][UI_TEAM] '{assetPath}' exists but Unity did not import it as a Sprite. " +
                    "Verify its importer and deterministic .meta files before QA PASS.");
            }

            return null;
        }

        private static void BindScene(
            string scenePath,
            Sprite logo,
            Sprite truckFallback,
            Sprite truckAlt,
            Sprite glow,
            GameObject truckModel)
        {
            SceneAsset sceneAsset = AssetDatabase.LoadAssetAtPath<SceneAsset>(scenePath);
            if (sceneAsset == null)
            {
                throw new BuildFailedException($"[CARGO V2][UI_TEAM] Required UI scene is missing: {scenePath}");
            }

            Scene scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);
            SCR_UIManager manager = UnityEngine.Object.FindObjectOfType<SCR_UIManager>();
            if (manager == null)
            {
                throw new BuildFailedException(
                    $"[CARGO V2][UI_TEAM] {scenePath} does not contain SCR_UIManager.");
            }

            SerializedObject serialized = new SerializedObject(manager);
            SetSprite(serialized, "logoSprite", logo);
            SetSprite(serialized, "truckSprite", truckFallback);
            SetSprite(serialized, "truckAltSprite", truckAlt);
            SetSprite(serialized, "glowSprite", glow);
            serialized.ApplyModifiedPropertiesWithoutUndo();

            EnsureRealTruck(scene, scenePath, truckModel);

            EditorUtility.SetDirty(manager);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
        }

        private static void EnsureRealTruck(Scene scene, string scenePath, GameObject modelAsset)
        {
            GameObject existing = GameObject.Find(TruckModelRootName);
            if (existing != null)
            {
                UnityEngine.Object.DestroyImmediate(existing);
            }

            GameObject root = new GameObject(TruckModelRootName);
            SceneManager.MoveGameObjectToScene(root, scene);

            GameObject instance = (GameObject)PrefabUtility.InstantiatePrefab(modelAsset, scene);
            if (instance == null)
            {
                UnityEngine.Object.DestroyImmediate(root);
                throw new BuildFailedException(
                    $"[CARGO V2][UI_TEAM] Unity could not instantiate the real truck model in {scenePath}.");
            }

            instance.name = "MOD_Truck_Premium_Instance";
            instance.transform.SetParent(root.transform, false);

            SCR_PremiumTruck3D presenter = root.AddComponent<SCR_PremiumTruck3D>();
            presenter.Configure(scenePath == LoadingScenePath);

            EditorUtility.SetDirty(root);
            EditorUtility.SetDirty(presenter);
        }

        private static void SetSprite(SerializedObject serialized, string propertyName, Sprite sprite)
        {
            SerializedProperty property = serialized.FindProperty(propertyName);
            if (property == null)
            {
                throw new InvalidOperationException(
                    $"[CARGO V2][UI_TEAM] Serialized property '{propertyName}' was not found.");
            }

            property.objectReferenceValue = sprite;
        }
    }
}
