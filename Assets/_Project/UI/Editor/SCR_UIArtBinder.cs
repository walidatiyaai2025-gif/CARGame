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

        public int callbackOrder => -500;

        public void OnPreprocessBuild(BuildReport report)
        {
            BindPremiumArtOrThrow();
        }

        [MenuItem("CARGO V2/UI/Bind Premium Art")]
        public static void BindPremiumArtMenu()
        {
            BindPremiumArtOrThrow();
            Debug.Log("[CARGO V2][UI_TEAM] Premium SVG art bound into Splash + Loading scenes.");
        }

        public static void BindPremiumArtOrThrow()
        {
            Sprite logo = ResolveSprite(SCR_UIManager.LogoAssetPath, required: true);
            Sprite truck = ResolveSprite(SCR_UIManager.TruckAssetPath, required: true);
            Sprite truckAlt = ResolveSprite(SCR_UIManager.TruckAltAssetPath, required: false);
            Sprite glow = ResolveSprite(SCR_UIManager.GlowAssetPath, required: true);

            string activeScenePath = SceneManager.GetActiveScene().path;
            bool activeSceneWasSaved = !string.IsNullOrWhiteSpace(activeScenePath);

            try
            {
                BindScene(SplashScenePath, logo, truck, truckAlt, glow);
                BindScene(LoadingScenePath, logo, truck, truckAlt, glow);
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
                    "Verify SVG importer/vector-graphics support and commit deterministic .meta files before QA PASS.");
            }

            return null;
        }

        private static void BindScene(
            string scenePath,
            Sprite logo,
            Sprite truck,
            Sprite truckAlt,
            Sprite glow)
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
            SetSprite(serialized, "truckSprite", truck);
            SetSprite(serialized, "truckAltSprite", truckAlt);
            SetSprite(serialized, "glowSprite", glow);
            serialized.ApplyModifiedPropertiesWithoutUndo();

            EditorUtility.SetDirty(manager);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
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
