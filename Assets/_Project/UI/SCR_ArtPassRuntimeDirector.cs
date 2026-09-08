using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    /// <summary>
    /// Runtime visual director for the approved CARGO V2 premium Art Pass.
    /// It is intentionally self-contained so Play Mode does not depend on SVG/vector packages.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class SCR_ArtPassRuntimeDirector : MonoBehaviour
    {
        private static readonly Color Navy = new Color32(0x05, 0x0D, 0x1B, 0xFF);
        private static readonly Color NavyLift = new Color32(0x0B, 0x24, 0x3E, 0xFF);
        private static readonly Color DeepBlue = new Color32(0x0E, 0x3A, 0x67, 0xFF);
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private static readonly Color WarmGold = new Color32(0xFF, 0xD8, 0x63, 0xFF);
        private static readonly Color Ice = new Color32(0xF5, 0xF8, 0xFC, 0xFF);
        private static readonly Color Muted = new Color32(0x9F, 0xB4, 0xCC, 0xFF);

        private Camera sceneCamera;
        private Sprite solidSprite;
        private Texture2D solidTexture;
        private Material lineMaterial;
        private SCR_UIManager uiManager;
        private Transform runtimeRoot;
        private Transform progressFill;
        private float progressWidth;
        private float progressStartX;
        private TextMesh progressText;
        private Light heroGlow;
        private bool loadingMode;
        private float startedAt;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Bootstrap()
        {
            string scene = SceneManager.GetActiveScene().name;
            if (scene != "01_Splash" && scene != "02_Loading")
            {
                return;
            }

            if (Object.FindObjectOfType<SCR_ArtPassRuntimeDirector>() != null)
            {
                return;
            }

            GameObject root = new GameObject("CARGO_V2_ArtPass_Runtime");
            root.AddComponent<SCR_ArtPassRuntimeDirector>();
        }

        private IEnumerator Start()
        {
            // Let the existing UI manager build first, then replace its prototype presentation layers.
            yield return null;

            loadingMode = SceneManager.GetActiveScene().name == "02_Loading";
            startedAt = Time.unscaledTime;
            uiManager = Object.FindObjectOfType<SCR_UIManager>();
            sceneCamera = Camera.main;

            if (sceneCamera == null)
            {
                sceneCamera = new GameObject("Main Camera").AddComponent<Camera>();
                sceneCamera.tag = "MainCamera";
            }

            ConfigureCamera();
            BuildSharedResources();
            HidePrototypePresentation();
            BuildPremiumScene();

            Debug.Log($"[CARGO V2][UI_TEAM] Art Pass runtime director active: {(loadingMode ? "Loading" : "Splash")}");
        }

        private void Update()
        {
            if (runtimeRoot == null)
            {
                return;
            }

            float t = Time.unscaledTime - startedAt;
            float pulse = 0.94f + Mathf.Sin(t * 1.1f) * 0.06f;
            if (heroGlow != null)
            {
                heroGlow.intensity = 1.35f + pulse * 0.45f;
            }

            if (loadingMode)
            {
                UpdateLoadingProgress();
            }
        }

        private void OnDestroy()
        {
            if (solidSprite != null)
            {
                Destroy(solidSprite);
            }

            if (solidTexture != null)
            {
                Destroy(solidTexture);
            }

            if (lineMaterial != null)
            {
                Destroy(lineMaterial);
            }
        }

        private void ConfigureCamera()
        {
            sceneCamera.orthographic = true;
            sceneCamera.orthographicSize = 5.4f;
            sceneCamera.transform.position = new Vector3(0f, 0f, -10f);
            sceneCamera.transform.rotation = Quaternion.identity;
            sceneCamera.clearFlags = CameraClearFlags.SolidColor;
            sceneCamera.backgroundColor = Navy;
        }

        private void BuildSharedResources()
        {
            solidTexture = new Texture2D(2, 2, TextureFormat.RGBA32, false)
            {
                name = "CargoV2_ArtPassSolid",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };
            solidTexture.SetPixels(new[] { Color.white, Color.white, Color.white, Color.white });
            solidTexture.Apply(false, true);
            solidSprite = Sprite.Create(solidTexture, new Rect(0f, 0f, 2f, 2f), new Vector2(0.5f, 0.5f), 2f);

            Shader shader = Shader.Find("Sprites/Default");
            if (shader == null) shader = Shader.Find("Unlit/Color");
            if (shader != null)
            {
                lineMaterial = new Material(shader) { color = Color.white };
            }
        }

        private void HidePrototypePresentation()
        {
            string[] names =
            {
                "IMG_Logo_Premium",
                "IMG_Truck_Premium",
                "IMG_Truck_Premium_Alt",
                "VFX_Glow_Premium",
                "Splash_LightSweep",
                "Progress_Track",
                "Progress_Fill",
                "Progress_Start_Outer",
                "Progress_Start_Inner",
                "Progress_End_Outer",
                "Progress_End_Inner",
            };

            for (int i = 0; i < names.Length; i++)
            {
                GameObject item = GameObject.Find(names[i]);
                if (item != null)
                {
                    item.SetActive(false);
                }
            }

            // Existing premium 3D truck stays visible and becomes the hero asset.
            GameObject truck3D = GameObject.Find("PremiumTruck3D");
            if (truck3D != null)
            {
                truck3D.SetActive(true);
            }
        }

        private void BuildPremiumScene()
        {
            runtimeRoot = new GameObject(loadingMode ? "ArtPass_Loading" : "ArtPass_Splash").transform;
            runtimeRoot.SetParent(transform, false);

            BuildCinematicBackdrop(runtimeRoot);
            BuildWorldRoutes(runtimeRoot);
            BuildHarborSilhouette(runtimeRoot);
            BuildGoldGroundGlow(runtimeRoot);

            if (loadingMode)
            {
                BuildLoadingComposition(runtimeRoot);
            }
            else
            {
                BuildSplashComposition(runtimeRoot);
            }

            EnsureHeroLighting();
        }

        private void BuildCinematicBackdrop(Transform parent)
        {
            float w = WorldWidth() + 1.5f;
            CreateRect("ArtPass_Navy", new Vector2(w, 12f), new Vector3(0f, 0f, 4.8f), Navy, 110, parent);
            CreateRect("ArtPass_BlueLift", new Vector2(w, 5.7f), new Vector3(0f, 0.55f, 4.6f), WithAlpha(NavyLift, 0.78f), 111, parent);
            CreateRect("ArtPass_Horizon", new Vector2(w, 2.9f), new Vector3(0f, -3.65f, 4.4f), WithAlpha(DeepBlue, 0.72f), 112, parent);

            for (int i = 0; i < 6; i++)
            {
                float width = Mathf.Lerp(10.5f, 3.7f, i / 5f);
                float alpha = Mathf.Lerp(0.018f, 0.055f, i / 5f);
                CreateRect(
                    $"ArtPass_AmbientBand_{i:00}",
                    new Vector2(width, 0.12f + i * 0.045f),
                    new Vector3(0f, 2.35f - i * 0.42f, 4.1f - i * 0.02f),
                    WithAlpha(Gold, alpha),
                    113 + i,
                    parent);
            }
        }

        private void BuildWorldRoutes(Transform parent)
        {
            Vector3[][] routes =
            {
                new[] { new Vector3(-7.4f, 2.35f, 2.6f), new Vector3(-4.3f, 3.25f, 2.6f), new Vector3(-1.2f, 2.75f, 2.6f), new Vector3(2.2f, 3.28f, 2.6f), new Vector3(6.7f, 2.25f, 2.6f) },
                new[] { new Vector3(-6.6f, 1.35f, 2.65f), new Vector3(-3.3f, 2.0f, 2.65f), new Vector3(0.4f, 1.6f, 2.65f), new Vector3(4.8f, 2.15f, 2.65f) },
                new[] { new Vector3(-5.5f, 3.45f, 2.7f), new Vector3(-2.8f, 2.45f, 2.7f), new Vector3(0.6f, 3.2f, 2.7f), new Vector3(5.6f, 3.55f, 2.7f) },
            };

            for (int r = 0; r < routes.Length; r++)
            {
                LineRenderer line = CreateLine($"WorldRoute_{r:00}", parent, 0.018f + r * 0.004f, WithAlpha(r == 1 ? Gold : Ice, r == 1 ? 0.32f : 0.16f), 121 + r);
                if (line == null) continue;
                line.positionCount = routes[r].Length;
                line.SetPositions(routes[r]);

                for (int i = 0; i < routes[r].Length; i++)
                {
                    Color nodeColor = (i + r) % 3 == 0 ? Gold : Ice;
                    CreateNode($"RouteNode_{r}_{i}", routes[r][i] + new Vector3(0f, 0f, -0.05f), nodeColor, parent, 130 + r);
                }
            }
        }

        private void BuildHarborSilhouette(Transform parent)
        {
            float[] heights = { 0.5f, 0.95f, 0.7f, 1.5f, 0.82f, 1.18f, 0.6f, 1.75f, 0.92f, 1.28f, 0.68f, 1.42f, 0.78f, 1.1f };
            float start = -7.6f;

            for (int i = 0; i < heights.Length; i++)
            {
                float x = start + i * 1.12f;
                float h = heights[i];
                CreateRect($"Skyline_{i:00}", new Vector2(0.62f, h), new Vector3(x, -4.45f + h * 0.5f, 3.2f), WithAlpha(new Color32(0x04, 0x12, 0x25, 0xFF), 0.9f), 140, parent);

                if (i % 2 == 0)
                {
                    CreateRect($"SkylineLight_{i:00}", new Vector2(0.06f, 0.06f), new Vector3(x + 0.12f, -4.2f + h * 0.54f, 3.0f), WithAlpha(Gold, 0.65f), 141, parent);
                }
            }

            CreateRect("HarborDeck", new Vector2(WorldWidth() + 2f, 0.12f), new Vector3(0f, -4.52f, 3.0f), WithAlpha(Gold, 0.22f), 142, parent);
        }

        private void BuildGoldGroundGlow(Transform parent)
        {
            CreateRect("TruckGroundGlowWide", new Vector2(8.4f, 0.16f), new Vector3(loadingMode ? 1.6f : 0f, -2.5f, 1.9f), WithAlpha(Gold, 0.11f), 150, parent);
            CreateRect("TruckGroundGlowCore", new Vector2(5.5f, 0.07f), new Vector3(loadingMode ? 1.6f : 0f, -2.48f, 1.8f), WithAlpha(WarmGold, 0.32f), 151, parent);
        }

        private void BuildSplashComposition(Transform parent)
        {
            Transform badge = new GameObject("PremiumLogoBadge").transform;
            badge.SetParent(parent, false);
            badge.localPosition = new Vector3(0f, 2.55f, 1.0f);
            BuildPremiumLogo(badge, 1.0f);

            TextMesh tagline = CreateText("BUILD  •  DRIVE  •  DELIVER", parent, new Vector3(0f, -3.45f, 0.7f), 34, 0.034f, Ice, 210, FontStyle.Bold);
            if (tagline != null)
            {
                tagline.characterSize = 0.034f;
            }

            CreateText("GLOBAL LOGISTICS EMPIRE", parent, new Vector3(0f, -3.92f, 0.65f), 22, 0.027f, WithAlpha(WarmGold, 0.88f), 211, FontStyle.Normal);

            CreateRect("SplashAccentLeft", new Vector2(2.0f, 0.022f), new Vector3(-4.0f, -3.83f, 0.6f), WithAlpha(Gold, 0.55f), 212, parent);
            CreateRect("SplashAccentRight", new Vector2(2.0f, 0.022f), new Vector3(4.0f, -3.83f, 0.6f), WithAlpha(Gold, 0.55f), 212, parent);
        }

        private void BuildLoadingComposition(Transform parent)
        {
            Transform badge = new GameObject("PremiumLogoBadge_Loading").transform;
            badge.SetParent(parent, false);
            badge.localPosition = new Vector3(-4.6f, 3.15f, 1.0f);
            BuildPremiumLogo(badge, 0.62f);

            // Dark glass panel anchors the loading information while leaving the 3D truck hero visible on the right.
            CreateRect("LoadingGlassPanel", new Vector2(7.6f, 4.15f), new Vector3(-3.1f, -0.15f, 1.4f), WithAlpha(new Color32(0x03, 0x0B, 0x18, 0xFF), 0.76f), 180, parent);
            CreateRect("LoadingGlassAccent", new Vector2(0.045f, 3.45f), new Vector3(-6.75f, -0.05f, 1.3f), Gold, 181, parent);

            CreateText("PREPARING GLOBAL ROUTE", parent, new Vector3(-3.2f, 0.95f, 1.0f), 38, 0.041f, Ice, 220, FontStyle.Bold);
            CreateText("Loading assets and synchronizing the next delivery.", parent, new Vector3(-3.2f, 0.38f, 0.95f), 23, 0.026f, Muted, 221, FontStyle.Normal);

            BuildProgress(parent);
            BuildLoadingStages(parent);
        }

        private void BuildProgress(Transform parent)
        {
            progressWidth = 5.9f;
            progressStartX = -6.05f;
            float y = -0.65f;

            CreateRect("ArtPassProgressOuter", new Vector2(progressWidth + 0.24f, 0.46f), new Vector3(-3.1f, y, 0.88f), WithAlpha(new Color32(0x02, 0x0A, 0x15, 0xFF), 0.96f), 230, parent);
            CreateRect("ArtPassProgressTrack", new Vector2(progressWidth, 0.25f), new Vector3(-3.1f, y, 0.82f), WithAlpha(new Color32(0x12, 0x42, 0x70, 0xFF), 0.72f), 231, parent);

            SpriteRenderer fill = CreateRect("ArtPassProgressFill", new Vector2(0.01f, 0.25f), new Vector3(progressStartX, y, 0.76f), Gold, 232, parent);
            progressFill = fill.transform;

            progressText = CreateText("0%", parent, new Vector3(0.25f, y, 0.7f), 34, 0.04f, Gold, 233, FontStyle.Bold);
        }

        private void BuildLoadingStages(Transform parent)
        {
            string[] labels = { "ROUTE", "CARGO", "ON ROAD", "DELIVER" };
            float[] xs = { -5.55f, -3.9f, -2.25f, -0.6f };
            for (int i = 0; i < labels.Length; i++)
            {
                Color c = i < 3 ? Gold : WithAlpha(Muted, 0.72f);
                CreateNode($"StageNode_{i}", new Vector3(xs[i], -1.55f, 0.65f), c, parent, 240);
                CreateText(labels[i], parent, new Vector3(xs[i], -1.93f, 0.62f), 18, 0.021f, i < 3 ? Ice : Muted, 241, FontStyle.Bold);
                if (i < labels.Length - 1)
                {
                    CreateRect($"StageLine_{i}", new Vector2(1.22f, 0.022f), new Vector3((xs[i] + xs[i + 1]) * 0.5f, -1.55f, 0.64f), WithAlpha(i < 2 ? Gold : Muted, 0.42f), 239, parent);
                }
            }
        }

        private void UpdateLoadingProgress()
        {
            float p = uiManager != null ? uiManager.NormalizedProgress : Mathf.PingPong(Time.unscaledTime * 0.18f, 1f);
            p = Mathf.Clamp01(p);

            if (progressFill != null)
            {
                float width = Mathf.Max(0.01f, progressWidth * p);
                progressFill.localScale = new Vector3(width, 0.25f, 1f);
                progressFill.position = new Vector3(progressStartX + width * 0.5f, -0.65f, 0.76f);
            }

            if (progressText != null)
            {
                progressText.text = $"{Mathf.RoundToInt(p * 100f)}%";
            }
        }

        private void BuildPremiumLogo(Transform parent, float scale)
        {
            // Globe/ring silhouette behind the mark.
            const int ringSegments = 24;
            for (int i = 0; i < ringSegments; i++)
            {
                float a = i / (float)ringSegments * Mathf.PI * 2f;
                Vector3 p = new Vector3(Mathf.Cos(a) * 2.52f, Mathf.Sin(a) * 1.24f + 0.38f, 0.22f) * scale;
                SpriteRenderer seg = CreateRect($"LogoRing_{i:00}", new Vector2(0.34f, 0.055f) * scale, p, WithAlpha(i % 3 == 0 ? WarmGold : Gold, 0.72f), 195, parent);
                seg.transform.localRotation = Quaternion.Euler(0f, 0f, a * Mathf.Rad2Deg + 90f);
            }

            // Wing bars.
            for (int i = 0; i < 3; i++)
            {
                float y = (0.45f - i * 0.36f) * scale;
                float width = (1.55f - i * 0.24f) * scale;
                CreateRect($"LogoWingL_{i}", new Vector2(width, 0.15f * scale), new Vector3((-3.0f + i * 0.12f) * scale, y, 0.12f), Gold, 196, parent);
                CreateRect($"LogoWingR_{i}", new Vector2(width, 0.15f * scale), new Vector3((3.0f - i * 0.12f) * scale, y, 0.12f), Gold, 196, parent);
            }

            // Extruded CARGO word.
            for (int layer = 7; layer >= 0; layer--)
            {
                float depth = layer * 0.025f * scale;
                Color c = layer == 0 ? WarmGold : Color.Lerp(new Color32(0x6B, 0x35, 0x00, 0xFF), Gold, layer / 8f);
                TextMesh cargo = CreateText("CARGO", parent, new Vector3(0f, 0.05f, -depth), Mathf.RoundToInt(110 * scale), 0.067f * scale, c, 205 + layer, FontStyle.Bold);
                cargo.anchor = TextAnchor.MiddleCenter;
            }

            for (int layer = 4; layer >= 0; layer--)
            {
                float depth = layer * 0.022f * scale;
                Color c = layer == 0 ? Ice : Color.Lerp(new Color32(0x28, 0x55, 0x82, 0xFF), Ice, layer / 5f);
                TextMesh v2 = CreateText("V2", parent, new Vector3(0f, -1.02f * scale, -depth), Mathf.RoundToInt(82 * scale), 0.061f * scale, c, 214 + layer, FontStyle.Bold);
                v2.anchor = TextAnchor.MiddleCenter;
            }
        }

        private void EnsureHeroLighting()
        {
            GameObject glowObject = new GameObject("ArtPass_HeroGlow");
            glowObject.transform.SetParent(runtimeRoot, false);
            glowObject.transform.localPosition = new Vector3(loadingMode ? 2.25f : 0f, -0.25f, -1.4f);
            heroGlow = glowObject.AddComponent<Light>();
            heroGlow.type = LightType.Point;
            heroGlow.color = new Color(1f, 0.66f, 0.20f);
            heroGlow.range = 8.5f;
            heroGlow.intensity = 1.6f;
            heroGlow.shadows = LightShadows.None;
        }

        private float WorldWidth()
        {
            return sceneCamera != null ? sceneCamera.orthographicSize * 2f * sceneCamera.aspect : 19.2f;
        }

        private SpriteRenderer CreateRect(string objectName, Vector2 size, Vector3 position, Color color, int order, Transform parent)
        {
            GameObject go = new GameObject(objectName);
            go.transform.SetParent(parent, false);
            go.transform.localPosition = position;
            SpriteRenderer renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = solidSprite;
            renderer.color = color;
            renderer.sortingOrder = order;
            go.transform.localScale = new Vector3(size.x, size.y, 1f);
            return renderer;
        }

        private TextMesh CreateText(string text, Transform parent, Vector3 position, int fontSize, float characterSize, Color color, int order, FontStyle fontStyle)
        {
            GameObject go = new GameObject("Text_" + text.Replace(" ", "_"));
            go.transform.SetParent(parent, false);
            go.transform.localPosition = position;
            TextMesh mesh = go.AddComponent<TextMesh>();
            mesh.text = text;
            mesh.anchor = TextAnchor.MiddleCenter;
            mesh.alignment = TextAlignment.Center;
            mesh.fontSize = Mathf.Max(12, fontSize);
            mesh.characterSize = characterSize;
            mesh.fontStyle = fontStyle;
            mesh.color = color;
            MeshRenderer renderer = mesh.GetComponent<MeshRenderer>();
            renderer.sortingOrder = order;
            return mesh;
        }

        private LineRenderer CreateLine(string objectName, Transform parent, float width, Color color, int order)
        {
            if (lineMaterial == null)
            {
                return null;
            }

            GameObject go = new GameObject(objectName);
            go.transform.SetParent(parent, false);
            LineRenderer line = go.AddComponent<LineRenderer>();
            line.material = lineMaterial;
            line.useWorldSpace = false;
            line.widthMultiplier = width;
            line.startColor = color;
            line.endColor = color;
            line.numCapVertices = 2;
            line.numCornerVertices = 2;
            line.sortingOrder = order;
            return line;
        }

        private void CreateNode(string objectName, Vector3 position, Color color, Transform parent, int order)
        {
            CreateRect(objectName + "_Outer", new Vector2(0.22f, 0.22f), position, WithAlpha(color, 0.22f), order, parent);
            CreateRect(objectName + "_Inner", new Vector2(0.085f, 0.085f), position + new Vector3(0f, 0f, -0.02f), color, order + 1, parent);
        }

        private static Color WithAlpha(Color c, float alpha)
        {
            c.a = Mathf.Clamp01(alpha);
            return c;
        }
    }
}
