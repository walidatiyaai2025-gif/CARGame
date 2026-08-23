using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    public sealed class SCR_UIManager : MonoBehaviour
    {
        public enum SceneMode
        {
            Splash = 0,
            Loading = 1,
            WorldMap = 2,
        }

        [Header("Scene flow")]
        [SerializeField] private SceneMode sceneMode = SceneMode.Splash;
        [SerializeField, Min(0.5f)] private float splashDurationSeconds = 3.2f;
        [SerializeField, Min(0.5f)] private float loadingDurationSeconds = 3.0f;
        [SerializeField] private string splashScene = "01_Splash";
        [SerializeField] private string loadingScene = "02_Loading";
        [SerializeField] private string worldMapScene = "04_WorldMap";

        [Header("Premium art pass")]
        [SerializeField] private Texture2D logoTexture;
        [SerializeField] private Texture2D truckTexture;
        [SerializeField] private Texture2D truckAltTexture;
        [SerializeField] private Texture2D glowTexture;

        private static readonly Color NavyTop = new Color32(0x05, 0x0D, 0x1B, 0xFF);
        private static readonly Color NavyLift = new Color32(0x12, 0x2E, 0x4A, 0xFF);
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private static readonly Color WarmGold = new Color32(0xFF, 0xD8, 0x63, 0xFF);
        private static readonly Color IceWhite = new Color32(0xF4, 0xF7, 0xFA, 0xFF);

        private const float ReferenceHalfHeight = 5.4f;
        private const float TransitionFadeSeconds = 0.28f;

        private readonly List<SpriteRenderer> sceneRenderers = new List<SpriteRenderer>(64);
        private readonly List<ParticleDot> particleDots = new List<ParticleDot>(24);

        private Camera sceneCamera;
        private Texture2D solidTexture;
        private Sprite solidSprite;
        private float startedAt;
        private bool transitionIssued;

        private Transform heroRoot;
        private SpriteRenderer logoRenderer;
        private SpriteRenderer glowRenderer;
        private SpriteRenderer lightSweepRenderer;
        private SpriteRenderer truckRenderer;
        private SpriteRenderer truckAltRenderer;
        private Transform progressFillTransform;
        private float progressTrackWidth;
        private float progressTrackStartX;
        private TextMesh progressText;

        public float NormalizedProgress { get; private set; }

        private void Awake()
        {
            Application.targetFrameRate = 60;
            BuildCamera();
            BuildSolidSprite();
        }

        private void Start()
        {
            startedAt = Time.unscaledTime;
            BuildSharedBackdrop();

            switch (sceneMode)
            {
                case SceneMode.Splash:
                    BuildSplash();
                    break;
                case SceneMode.Loading:
                    BuildLoading();
                    break;
                case SceneMode.WorldMap:
                    BuildWorldMapCheckpoint();
                    break;
            }

            ValidateRequiredArt();
            Debug.Log($"[CARGO V2][UI_TEAM] Premium {sceneMode} checkpoint ready.");
        }

        private void Update()
        {
            float elapsed = Time.unscaledTime - startedAt;

            switch (sceneMode)
            {
                case SceneMode.Splash:
                    UpdateSplash(elapsed);
                    break;
                case SceneMode.Loading:
                    UpdateLoading(elapsed);
                    break;
                case SceneMode.WorldMap:
                    UpdateBackdropMotion(elapsed);
                    break;
            }

            UpdateParticles(elapsed);
        }

        private void BuildCamera()
        {
            sceneCamera = Camera.main;
            if (sceneCamera == null)
            {
                sceneCamera = new GameObject("Main Camera").AddComponent<Camera>();
                sceneCamera.tag = "MainCamera";
            }

            sceneCamera.orthographic = true;
            sceneCamera.orthographicSize = ReferenceHalfHeight;
            sceneCamera.transform.position = new Vector3(0f, 0f, -10f);
            sceneCamera.transform.rotation = Quaternion.identity;
            sceneCamera.clearFlags = CameraClearFlags.SolidColor;
            sceneCamera.backgroundColor = NavyTop;
        }

        private void BuildSolidSprite()
        {
            solidTexture = new Texture2D(2, 2, TextureFormat.RGBA32, false)
            {
                name = "UI_RuntimeSolid",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };
            solidTexture.SetPixels(new[] { Color.white, Color.white, Color.white, Color.white });
            solidTexture.Apply(false, true);
            solidSprite = Sprite.Create(solidTexture, new Rect(0, 0, 2, 2), new Vector2(0.5f, 0.5f), 2f);
            solidSprite.name = "UI_RuntimeSolidSprite";
        }

        private void BuildSharedBackdrop()
        {
            float worldWidth = GetWorldWidth();

            CreateRect("Backdrop_Navy", new Vector2(worldWidth + 1f, ReferenceHalfHeight * 2f + 1f),
                new Vector3(0f, 0f, 4f), NavyTop, -100);

            CreateRect("Backdrop_Lift", new Vector2(worldWidth + 1f, ReferenceHalfHeight * 0.78f),
                new Vector3(0f, -3.7f, 3.8f), WithAlpha(NavyLift, 0.50f), -99);

            CreateRect("Top_Hairline", new Vector2(worldWidth * 0.86f, 0.025f),
                new Vector3(0f, 4.52f, 3.5f), WithAlpha(Gold, 0.52f), -20);

            CreateRect("Bottom_Hairline", new Vector2(worldWidth * 0.86f, 0.018f),
                new Vector3(0f, -4.48f, 3.5f), WithAlpha(IceWhite, 0.18f), -20);

            BuildRouteConstellation();
            BuildAmbientParticles();
        }

        private void BuildSplash()
        {
            heroRoot = new GameObject("Splash_Hero").transform;
            heroRoot.position = new Vector3(0f, 0.2f, 0f);

            glowRenderer = CreateTextureRenderer(
                "VFX_Glow_Premium",
                glowTexture,
                8.4f,
                heroRoot,
                new Vector3(0f, 0.15f, 0.9f),
                -7,
                WithAlpha(WarmGold, 0.54f));

            logoRenderer = CreateTextureRenderer(
                "IMG_Logo_Premium",
                logoTexture,
                6.3f,
                heroRoot,
                new Vector3(0f, 0.35f, 0f),
                5,
                Color.white);

            if (logoRenderer == null)
            {
                CreatePremiumText("CARGO V2", heroRoot, new Vector3(0f, 0.42f, 0f), 92, 0.067f, Gold, 5, FontStyle.Bold);
            }

            CreatePremiumText("GLOBAL LOGISTICS · PREMIUM DELIVERY NETWORK", heroRoot,
                new Vector3(0f, -1.72f, 0f), 32, 0.038f, WithAlpha(IceWhite, 0.82f), 6, FontStyle.Normal);

            CreateRect("Splash_Accent_Left", new Vector2(1.45f, 0.035f),
                new Vector3(-3.35f, -1.75f, 0f), WithAlpha(Gold, 0.48f), 4);

            CreateRect("Splash_Accent_Right", new Vector2(1.45f, 0.035f),
                new Vector3(3.35f, -1.75f, 0f), WithAlpha(Gold, 0.48f), 4);

            lightSweepRenderer = CreateRect("Splash_LightSweep", new Vector2(0.18f, 3.65f),
                new Vector3(-4.1f, 0.42f, -0.2f), WithAlpha(IceWhite, 0.0f), 11);
            lightSweepRenderer.transform.rotation = Quaternion.Euler(0f, 0f, -18f);
        }

        private void BuildLoading()
        {
            heroRoot = new GameObject("Loading_Hero").transform;
            heroRoot.position = new Vector3(0f, 0.25f, 0f);

            CreatePremiumText("PREPARING YOUR ROUTE", heroRoot, new Vector3(0f, 3.48f, 0f),
                38, 0.046f, WithAlpha(IceWhite, 0.90f), 7, FontStyle.Bold);

            CreatePremiumText("GLOBAL DELIVERY NETWORK", heroRoot, new Vector3(0f, 3.02f, 0f),
                24, 0.035f, WithAlpha(WarmGold, 0.80f), 7, FontStyle.Normal);

            glowRenderer = CreateTextureRenderer(
                "VFX_Glow_Premium",
                glowTexture,
                9.2f,
                heroRoot,
                new Vector3(0f, 0.45f, 0.9f),
                -7,
                WithAlpha(WarmGold, 0.42f));

            truckRenderer = CreateTextureRenderer(
                "IMG_Truck_Premium",
                truckTexture,
                7.8f,
                heroRoot,
                new Vector3(-0.05f, 0.45f, 0f),
                6,
                Color.white);

            truckAltRenderer = CreateTextureRenderer(
                "IMG_Truck_Premium_Alt",
                truckAltTexture,
                7.8f,
                heroRoot,
                new Vector3(-0.05f, 0.45f, 0.05f),
                7,
                WithAlpha(Color.white, 0f));

            if (truckRenderer == null && truckAltRenderer == null)
            {
                CreatePremiumText("PREMIUM CARGO", heroRoot, new Vector3(0f, 0.55f, 0f),
                    64, 0.060f, Gold, 5, FontStyle.Bold);
            }

            BuildProgressRoute(heroRoot);
        }

        private void BuildProgressRoute(Transform parent)
        {
            progressTrackWidth = Mathf.Min(8.9f, GetWorldWidth() * 0.64f);
            progressTrackStartX = -progressTrackWidth * 0.5f;

            CreateRect("Progress_Track", new Vector2(progressTrackWidth, 0.09f),
                new Vector3(0f, -2.62f, 0f), WithAlpha(IceWhite, 0.16f), 10, parent);

            progressFillTransform = CreateRect("Progress_Fill", new Vector2(0.01f, 0.09f),
                new Vector3(progressTrackStartX, -2.62f, -0.05f), Gold, 11, parent).transform;

            const int dashCount = 18;
            for (int i = 0; i < dashCount; i++)
            {
                float t = i / (float)(dashCount - 1);
                float x = Mathf.Lerp(progressTrackStartX, -progressTrackStartX, t);
                CreateRect($"Route_Dash_{i:00}", new Vector2(0.18f, 0.025f),
                    new Vector3(x, -2.26f, 0f), WithAlpha(IceWhite, 0.20f), 8, parent);
            }

            CreateRouteNode("Route_Start", new Vector3(progressTrackStartX, -2.62f, -0.1f), parent, WithAlpha(IceWhite, 0.74f));
            CreateRouteNode("Route_Destination", new Vector3(-progressTrackStartX, -2.62f, -0.1f), parent, Gold);

            progressText = CreatePremiumText("0%", parent, new Vector3(0f, -3.30f, 0f),
                38, 0.050f, IceWhite, 12, FontStyle.Bold);

            CreatePremiumText("LOADING WORLD ROUTE", parent, new Vector3(0f, -3.78f, 0f),
                24, 0.034f, WithAlpha(IceWhite, 0.66f), 12, FontStyle.Normal);
        }

        private void BuildWorldMapCheckpoint()
        {
            CreatePremiumText("WORLD MAP", null, new Vector3(0f, 0.35f, 0f),
                80, 0.068f, Gold, 5, FontStyle.Bold);

            CreatePremiumText("TRANSITION TARGET READY", null, new Vector3(0f, -0.65f, 0f),
                30, 0.040f, WithAlpha(IceWhite, 0.78f), 5, FontStyle.Normal);
        }

        private void BuildRouteConstellation()
        {
            float width = Mathf.Min(9.6f, GetWorldWidth() * 0.72f);
            float y = -4.02f;

            CreateRect("Constellation_Line", new Vector2(width, 0.018f),
                new Vector3(0f, y, 1.7f), WithAlpha(IceWhite, 0.10f), -8);

            for (int i = 0; i < 5; i++)
            {
                float t = i / 4f;
                float x = Mathf.Lerp(-width * 0.5f, width * 0.5f, t);
                float size = i == 2 ? 0.085f : 0.055f;
                CreateRect($"Constellation_Node_{i}", new Vector2(size, size),
                    new Vector3(x, y + Mathf.Sin(i * 1.7f) * 0.12f, 1.5f),
                    i == 2 ? WithAlpha(Gold, 0.58f) : WithAlpha(IceWhite, 0.22f), -7);
            }
        }

        private void BuildAmbientParticles()
        {
            float worldWidth = GetWorldWidth();
            const int count = 22;

            for (int i = 0; i < count; i++)
            {
                float seed = (i + 1) * 1.6180339f;
                float x = Mathf.Lerp(-worldWidth * 0.46f, worldWidth * 0.46f, Frac(seed * 0.47f));
                float y = Mathf.Lerp(-3.7f, 4.1f, Frac(seed * 0.83f));
                float size = Mathf.Lerp(0.018f, 0.055f, Frac(seed * 1.31f));
                float alpha = Mathf.Lerp(0.08f, 0.30f, Frac(seed * 1.79f));
                SpriteRenderer renderer = CreateRect($"Ambient_Particle_{i:00}", new Vector2(size, size),
                    new Vector3(x, y, 2.6f), WithAlpha(i % 4 == 0 ? Gold : IceWhite, alpha), -15);

                particleDots.Add(new ParticleDot
                {
                    Renderer = renderer,
                    BasePosition = renderer.transform.position,
                    Phase = seed,
                    Amplitude = Mathf.Lerp(0.025f, 0.10f, Frac(seed * 2.11f)),
                    Speed = Mathf.Lerp(0.35f, 0.85f, Frac(seed * 2.59f)),
                    BaseAlpha = alpha,
                });
            }
        }

        private void UpdateSplash(float elapsed)
        {
            float progress = Mathf.Clamp01(elapsed / splashDurationSeconds);
            NormalizedProgress = progress;

            if (heroRoot != null)
            {
                float intro = Smooth01(Mathf.Clamp01(elapsed / 0.75f));
                float scale = Mathf.Lerp(0.94f, 1f, intro);
                heroRoot.localScale = Vector3.one * scale;
                heroRoot.position = new Vector3(0f, 0.2f + Mathf.Sin(elapsed * 1.25f) * 0.025f, 0f);
            }

            if (logoRenderer != null)
            {
                float introAlpha = Smooth01(Mathf.Clamp01(elapsed / 0.55f));
                logoRenderer.color = WithAlpha(Color.white, introAlpha);
            }

            if (glowRenderer != null)
            {
                float pulse = 0.40f + Mathf.Sin(elapsed * 1.9f) * 0.08f;
                glowRenderer.color = WithAlpha(WarmGold, pulse);
            }

            if (lightSweepRenderer != null)
            {
                float sweepT = Mathf.Repeat(elapsed / 2.15f, 1f);
                float x = Mathf.Lerp(-4.2f, 4.2f, Smooth01(sweepT));
                float alpha = Mathf.Sin(sweepT * Mathf.PI);
                lightSweepRenderer.transform.localPosition = new Vector3(x, 0.42f, -0.2f);
                lightSweepRenderer.color = WithAlpha(IceWhite, alpha * 0.14f);
            }

            ApplyExitFade(splashDurationSeconds, elapsed);

            if (!transitionIssued && elapsed >= splashDurationSeconds)
            {
                TransitionTo(loadingScene);
            }
        }

        private void UpdateLoading(float elapsed)
        {
            NormalizedProgress = Mathf.Clamp01(elapsed / loadingDurationSeconds);
            float smooth = Smooth01(NormalizedProgress);

            if (heroRoot != null)
            {
                heroRoot.position = new Vector3(0f, 0.25f + Mathf.Sin(elapsed * 2.0f) * 0.018f, 0f);
            }

            if (truckRenderer != null)
            {
                float entry = Smooth01(Mathf.Clamp01(elapsed / 0.72f));
                float x = Mathf.Lerp(-0.55f, -0.05f, entry);
                float y = 0.45f + Mathf.Sin(elapsed * 2.8f) * 0.035f;
                truckRenderer.transform.localPosition = new Vector3(x, y, 0f);
                truckRenderer.color = WithAlpha(Color.white, entry);
            }

            if (truckAltRenderer != null)
            {
                float blend = Smooth01(Mathf.Clamp01((NormalizedProgress - 0.38f) / 0.42f));
                float y = 0.45f + Mathf.Sin(elapsed * 2.8f + 0.35f) * 0.028f;
                truckAltRenderer.transform.localPosition = new Vector3(-0.05f, y, 0.05f);
                truckAltRenderer.color = WithAlpha(Color.white, blend * 0.18f);
            }

            if (glowRenderer != null)
            {
                glowRenderer.color = WithAlpha(WarmGold, 0.34f + Mathf.Sin(elapsed * 2.1f) * 0.07f);
            }

            if (progressFillTransform != null)
            {
                float width = Mathf.Max(0.01f, progressTrackWidth * smooth);
                progressFillTransform.localScale = new Vector3(width, 0.09f, 1f);
                progressFillTransform.localPosition = new Vector3(progressTrackStartX + width * 0.5f, -2.62f, -0.05f);
            }

            if (progressText != null)
            {
                progressText.text = $"{Mathf.RoundToInt(NormalizedProgress * 100f)}%";
            }

            ApplyExitFade(loadingDurationSeconds, elapsed);

            if (!transitionIssued && NormalizedProgress >= 1f)
            {
                TransitionTo(worldMapScene);
            }
        }

        private void UpdateBackdropMotion(float elapsed)
        {
            if (glowRenderer != null)
            {
                glowRenderer.color = WithAlpha(WarmGold, 0.30f + Mathf.Sin(elapsed * 1.7f) * 0.05f);
            }
        }

        private void UpdateParticles(float elapsed)
        {
            for (int i = 0; i < particleDots.Count; i++)
            {
                ParticleDot dot = particleDots[i];
                if (dot.Renderer == null)
                {
                    continue;
                }

                float wave = Mathf.Sin(elapsed * dot.Speed + dot.Phase);
                Vector3 position = dot.BasePosition;
                position.y += wave * dot.Amplitude;
                dot.Renderer.transform.position = position;

                Color color = dot.Renderer.color;
                color.a = dot.BaseAlpha * (0.65f + (wave + 1f) * 0.175f);
                dot.Renderer.color = color;
            }
        }

        private void ApplyExitFade(float duration, float elapsed)
        {
            float fadeStart = Mathf.Max(0f, duration - TransitionFadeSeconds);
            if (elapsed < fadeStart)
            {
                return;
            }

            float fade = 1f - Mathf.Clamp01((elapsed - fadeStart) / TransitionFadeSeconds);
            for (int i = 0; i < sceneRenderers.Count; i++)
            {
                SpriteRenderer renderer = sceneRenderers[i];
                if (renderer == null || renderer.gameObject.name.StartsWith("Backdrop_"))
                {
                    continue;
                }

                Color color = renderer.color;
                color.a = Mathf.Min(color.a, fade);
                renderer.color = color;
            }
        }

        private SpriteRenderer CreateTextureRenderer(
            string name,
            Texture2D texture,
            float targetWidth,
            Transform parent,
            Vector3 localPosition,
            int sortingOrder,
            Color tint)
        {
            if (texture == null)
            {
                return null;
            }

            Sprite sprite = Sprite.Create(
                texture,
                new Rect(0f, 0f, texture.width, texture.height),
                new Vector2(0.5f, 0.5f),
                100f,
                0,
                SpriteMeshType.FullRect);

            sprite.name = $"{name}_RuntimeSprite";

            GameObject go = new GameObject(name);
            Transform t = go.transform;
            if (parent != null)
            {
                t.SetParent(parent, false);
                t.localPosition = localPosition;
            }
            else
            {
                t.position = localPosition;
            }

            SpriteRenderer renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = sprite;
            renderer.color = tint;
            renderer.sortingOrder = sortingOrder;

            float nativeWidth = Mathf.Max(0.001f, texture.width / 100f);
            float scale = targetWidth / nativeWidth;
            t.localScale = new Vector3(scale, scale, 1f);

            sceneRenderers.Add(renderer);
            return renderer;
        }

        private SpriteRenderer CreateRect(
            string name,
            Vector2 size,
            Vector3 position,
            Color color,
            int sortingOrder,
            Transform parent = null)
        {
            GameObject go = new GameObject(name);
            Transform t = go.transform;
            if (parent != null)
            {
                t.SetParent(parent, false);
                t.localPosition = position;
            }
            else
            {
                t.position = position;
            }

            SpriteRenderer renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = solidSprite;
            renderer.color = color;
            renderer.sortingOrder = sortingOrder;
            t.localScale = new Vector3(size.x, size.y, 1f);

            sceneRenderers.Add(renderer);
            return renderer;
        }

        private void CreateRouteNode(string name, Vector3 position, Transform parent, Color color)
        {
            CreateRect($"{name}_Outer", new Vector2(0.22f, 0.22f), position, WithAlpha(color, 0.22f), 12, parent);
            CreateRect($"{name}_Inner", new Vector2(0.085f, 0.085f), new Vector3(position.x, position.y, position.z - 0.02f), color, 13, parent);
        }

        private static TextMesh CreatePremiumText(
            string text,
            Transform parent,
            Vector3 position,
            int fontSize,
            float characterSize,
            Color color,
            int sortingOrder,
            FontStyle style)
        {
            GameObject go = new GameObject($"TXT_{text.Replace(" ", "_")}");
            Transform t = go.transform;
            if (parent != null)
            {
                t.SetParent(parent, false);
                t.localPosition = position;
            }
            else
            {
                t.position = position;
            }

            TextMesh mesh = go.AddComponent<TextMesh>();
            mesh.text = text;
            mesh.anchor = TextAnchor.MiddleCenter;
            mesh.alignment = TextAlignment.Center;
            mesh.fontSize = fontSize;
            mesh.characterSize = characterSize;
            mesh.fontStyle = style;
            mesh.color = color;

            MeshRenderer renderer = go.GetComponent<MeshRenderer>();
            if (renderer != null)
            {
                renderer.sortingOrder = sortingOrder;
            }

            return mesh;
        }

        private void ValidateRequiredArt()
        {
            if (sceneMode == SceneMode.Splash)
            {
                if (logoTexture == null)
                {
                    Debug.LogError("[CARGO V2][UI_TEAM] IMG_Logo_Premium is not bound in 01_Splash.");
                }

                if (glowTexture == null)
                {
                    Debug.LogError("[CARGO V2][UI_TEAM] VFX_Glow_Premium is not bound in 01_Splash.");
                }
            }

            if (sceneMode == SceneMode.Loading)
            {
                if (truckTexture == null)
                {
                    Debug.LogError("[CARGO V2][UI_TEAM] IMG_Truck_Premium is not bound in 02_Loading.");
                }

                if (truckAltTexture == null)
                {
                    Debug.LogWarning("[CARGO V2][UI_TEAM] IMG_Truck_Premium_Alt is not bound; primary truck will remain visible.");
                }

                if (glowTexture == null)
                {
                    Debug.LogError("[CARGO V2][UI_TEAM] VFX_Glow_Premium is not bound in 02_Loading.");
                }
            }
        }

        private void TransitionTo(string sceneName)
        {
            if (transitionIssued)
            {
                return;
            }

            transitionIssued = true;

            if (string.IsNullOrWhiteSpace(sceneName))
            {
                Debug.LogError("[CARGO V2][UI_TEAM] Transition blocked: target scene is empty.");
                return;
            }

            Debug.Log($"[CARGO V2][UI_TEAM] Transition {SceneManager.GetActiveScene().name} -> {sceneName}");

            if (Application.CanStreamedLevelBeLoaded(sceneName))
            {
                SceneManager.LoadScene(sceneName, LoadSceneMode.Single);
                return;
            }

#if UNITY_EDITOR
            string editorPath = $"Assets/_Project/Scenes/{sceneName}.unity";
            UnityEditor.SceneManagement.EditorSceneManager.LoadSceneInPlayMode(
                editorPath,
                new LoadSceneParameters(LoadSceneMode.Single));
#else
            Debug.LogError($"[CARGO V2][UI_TEAM] Scene '{sceneName}' is not present in Build Settings.");
#endif
        }

        private float GetWorldWidth()
        {
            float aspect = sceneCamera != null && sceneCamera.aspect > 0.01f
                ? sceneCamera.aspect
                : (Screen.height > 0 ? Screen.width / (float)Screen.height : 16f / 9f);
            return ReferenceHalfHeight * 2f * aspect;
        }

        private static float Smooth01(float value)
        {
            return value * value * (3f - 2f * value);
        }

        private static float Frac(float value)
        {
            return value - Mathf.Floor(value);
        }

        private static Color WithAlpha(Color color, float alpha)
        {
            color.a = Mathf.Clamp01(alpha);
            return color;
        }

        private sealed class ParticleDot
        {
            public SpriteRenderer Renderer;
            public Vector3 BasePosition;
            public float Phase;
            public float Amplitude;
            public float Speed;
            public float BaseAlpha;
        }
    }
}
