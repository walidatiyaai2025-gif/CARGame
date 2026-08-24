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
        }

        public const string LogoAssetPath = "Assets/_Project/Generated/IMG_Logo_Premium.svg";
        public const string TruckAssetPath = "Assets/_Project/Generated/IMG_Truck_Premium.svg";
        public const string TruckAltAssetPath = "Assets/_Project/Generated/IMG_Truck_Premium_Alt.svg";
        public const string GlowAssetPath = "Assets/_Project/Generated/VFX_Glow_Premium.svg";

        [Header("Scene flow")]
        [SerializeField] private SceneMode sceneMode = SceneMode.Splash;
        [SerializeField, Min(0.5f)] private float splashDurationSeconds = 3.2f;
        [SerializeField, Min(0.5f)] private float loadingDurationSeconds = 3.0f;
        [SerializeField] private string loadingScene = "02_Loading";
        [SerializeField] private string worldMapScene = "04_WorldMap";

        [Header("Premium art pass")]
        [SerializeField] private Sprite logoSprite;
        [SerializeField] private Sprite truckSprite;
        [SerializeField] private Sprite truckAltSprite;
        [SerializeField] private Sprite glowSprite;

        private static readonly Color Navy = new Color32(0x05, 0x0D, 0x1B, 0xFF);
        private static readonly Color NavyLift = new Color32(0x0C, 0x22, 0x39, 0xFF);
        private static readonly Color DeepBlue = new Color32(0x11, 0x34, 0x57, 0xFF);
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private static readonly Color WarmGold = new Color32(0xFF, 0xD8, 0x63, 0xFF);
        private static readonly Color IceWhite = new Color32(0xF4, 0xF7, 0xFA, 0xFF);

        private const float ReferenceHalfHeight = 5.4f;
        private const float TransitionFadeSeconds = 0.28f;

        private Camera sceneCamera;
        private Texture2D solidTexture;
        private Sprite solidSprite;
        private float startedAt;
        private bool transitionIssued;

        private Transform heroRoot;
        private SpriteRenderer logoRenderer;
        private SpriteRenderer truckRenderer;
        private SpriteRenderer truckAltRenderer;
        private SpriteRenderer glowRenderer;
        private SpriteRenderer lightSweepRenderer;
        private SpriteRenderer fadeRenderer;
        private Transform progressFillTransform;
        private float progressTrackWidth;
        private float progressTrackStartX;
        private TextMesh progressText;

        public float NormalizedProgress { get; private set; }

        private void Awake()
        {
            Application.targetFrameRate = 60;
            EnsureCamera();
            BuildSolidSprite();
        }

        private void Start()
        {
            startedAt = Time.unscaledTime;
            BuildBackdrop();

            if (sceneMode == SceneMode.Splash)
            {
                BuildSplash();
            }
            else
            {
                BuildLoading();
            }

            BuildFadeOverlay();
            ValidateRequiredArt();
            Debug.Log($"[CARGO V2][UI_TEAM] Premium {sceneMode} scene ready.");
        }

        private void Update()
        {
            float elapsed = Time.unscaledTime - startedAt;

            if (sceneMode == SceneMode.Splash)
            {
                UpdateSplash(elapsed);
            }
            else
            {
                UpdateLoading(elapsed);
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
        }

        private void EnsureCamera()
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
            sceneCamera.backgroundColor = Navy;
        }

        private void BuildSolidSprite()
        {
            solidTexture = new Texture2D(2, 2, TextureFormat.RGBA32, false)
            {
                name = "CargoV2_UI_Solid",
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
            };

            solidTexture.SetPixels(new[] { Color.white, Color.white, Color.white, Color.white });
            solidTexture.Apply(false, true);
            solidSprite = Sprite.Create(solidTexture, new Rect(0f, 0f, 2f, 2f), new Vector2(0.5f, 0.5f), 2f);
            solidSprite.name = "CargoV2_UI_SolidSprite";
        }

        private void BuildBackdrop()
        {
            float worldWidth = GetWorldWidth();

            CreateRect(
                "Backdrop_Navy",
                new Vector2(worldWidth + 1f, ReferenceHalfHeight * 2f + 1f),
                new Vector3(0f, 0f, 5f),
                Navy,
                -100);

            CreateRect(
                "Backdrop_DeepBlue",
                new Vector2(worldWidth + 1f, 4.5f),
                new Vector3(0f, -3.45f, 4.8f),
                WithAlpha(DeepBlue, 0.45f),
                -99);

            CreateRect(
                "Backdrop_HorizonGlow",
                new Vector2(worldWidth * 0.78f, 0.22f),
                new Vector3(0f, -1.35f, 4.5f),
                WithAlpha(Gold, 0.07f),
                -96);

            CreateRect(
                "TopGoldLine",
                new Vector2(worldWidth * 0.84f, 0.025f),
                new Vector3(0f, 4.55f, 4.2f),
                WithAlpha(Gold, 0.48f),
                -90);

            CreateRect(
                "BottomCoolLine",
                new Vector2(worldWidth * 0.84f, 0.018f),
                new Vector3(0f, -4.58f, 4.2f),
                WithAlpha(IceWhite, 0.14f),
                -90);

            BuildRouteConstellation(worldWidth);
        }

        private void BuildRouteConstellation(float worldWidth)
        {
            float width = Mathf.Min(9.8f, worldWidth * 0.72f);
            float y = -4.05f;

            CreateRect(
                "Route_Constellation_Line",
                new Vector2(width, 0.016f),
                new Vector3(0f, y, 3f),
                WithAlpha(IceWhite, 0.08f),
                -70);

            for (int i = 0; i < 7; i++)
            {
                float t = i / 6f;
                float x = Mathf.Lerp(-width * 0.5f, width * 0.5f, t);
                float yOffset = Mathf.Sin(i * 1.31f) * 0.11f;
                float size = i == 3 ? 0.08f : 0.045f;
                Color color = i == 3 ? WithAlpha(Gold, 0.55f) : WithAlpha(IceWhite, 0.18f);

                CreateRect(
                    $"Route_Constellation_Node_{i:00}",
                    new Vector2(size, size),
                    new Vector3(x, y + yOffset, 2.9f),
                    color,
                    -69);
            }
        }

        private void BuildSplash()
        {
            heroRoot = new GameObject("Splash_PremiumHero").transform;
            heroRoot.position = new Vector3(0f, 0.05f, 0f);

            glowRenderer = CreateArt(
                "VFX_Glow_Premium",
                glowSprite,
                8.4f,
                heroRoot,
                new Vector3(0f, 1.35f, 0.8f),
                -8,
                WithAlpha(Color.white, 0.62f));

            truckRenderer = CreateArt(
                "IMG_Truck_Premium",
                truckSprite,
                5.15f,
                heroRoot,
                new Vector3(0f, -1.12f, 0.3f),
                1,
                WithAlpha(Color.white, 0.94f));

            logoRenderer = CreateArt(
                "IMG_Logo_Premium",
                logoSprite,
                6.45f,
                heroRoot,
                new Vector3(0f, 1.62f, 0f),
                8,
                Color.white);

            if (logoRenderer == null)
            {
                CreatePremiumText(
                    "CARGO V2",
                    heroRoot,
                    new Vector3(0f, 1.72f, 0f),
                    92,
                    0.064f,
                    Gold,
                    8,
                    FontStyle.Bold);
            }

            CreatePremiumText(
                "PREMIUM GLOBAL CARGO NETWORK",
                heroRoot,
                new Vector3(0f, -3.25f, 0f),
                28,
                0.036f,
                WithAlpha(IceWhite, 0.82f),
                9,
                FontStyle.Bold);

            CreatePremiumText(
                "DELIVER  ·  EXPAND  ·  DOMINATE",
                heroRoot,
                new Vector3(0f, -3.72f, 0f),
                22,
                0.031f,
                WithAlpha(WarmGold, 0.78f),
                9,
                FontStyle.Normal);

            lightSweepRenderer = CreateRect(
                "Splash_LightSweep",
                new Vector2(0.13f, 5.2f),
                new Vector3(-5.4f, 0.55f, -0.2f),
                WithAlpha(IceWhite, 0f),
                20,
                heroRoot);

            lightSweepRenderer.transform.localRotation = Quaternion.Euler(0f, 0f, -17f);
        }

        private void BuildLoading()
        {
            heroRoot = new GameObject("Loading_PremiumHero").transform;
            heroRoot.position = new Vector3(0f, 0.15f, 0f);

            logoRenderer = CreateArt(
                "IMG_Logo_Premium",
                logoSprite,
                3.65f,
                heroRoot,
                new Vector3(0f, 3.45f, 0f),
                10,
                WithAlpha(Color.white, 0.98f));

            glowRenderer = CreateArt(
                "VFX_Glow_Premium",
                glowSprite,
                8.8f,
                heroRoot,
                new Vector3(0f, 0.45f, 0.8f),
                -8,
                WithAlpha(Color.white, 0.54f));

            truckRenderer = CreateArt(
                "IMG_Truck_Premium",
                truckSprite,
                6.7f,
                heroRoot,
                new Vector3(0f, 0.18f, 0.1f),
                6,
                Color.white);

            truckAltRenderer = CreateArt(
                "IMG_Truck_Premium_Alt",
                truckAltSprite,
                7.4f,
                heroRoot,
                new Vector3(0f, 0.15f, 0.05f),
                7,
                WithAlpha(Color.white, 0f));

            if (truckRenderer == null && truckAltRenderer == null)
            {
                CreatePremiumText(
                    "PREMIUM CARGO",
                    heroRoot,
                    new Vector3(0f, 0.45f, 0f),
                    62,
                    0.056f,
                    Gold,
                    7,
                    FontStyle.Bold);
            }

            CreatePremiumText(
                "PREPARING YOUR WORLD ROUTE",
                heroRoot,
                new Vector3(0f, -2.25f, 0f),
                27,
                0.036f,
                WithAlpha(IceWhite, 0.88f),
                12,
                FontStyle.Bold);

            BuildProgressRoute(heroRoot);
        }

        private void BuildProgressRoute(Transform parent)
        {
            progressTrackWidth = Mathf.Min(8.7f, GetWorldWidth() * 0.62f);
            progressTrackStartX = -progressTrackWidth * 0.5f;

            CreateRect(
                "Progress_Track",
                new Vector2(progressTrackWidth, 0.10f),
                new Vector3(0f, -2.86f, 0f),
                WithAlpha(IceWhite, 0.14f),
                14,
                parent);

            SpriteRenderer fill = CreateRect(
                "Progress_Fill",
                new Vector2(0.001f, 0.10f),
                new Vector3(progressTrackStartX, -2.86f, -0.04f),
                Gold,
                15,
                parent);

            progressFillTransform = fill.transform;

            CreateRouteNode(
                "Progress_Start",
                new Vector3(progressTrackStartX, -2.86f, -0.08f),
                parent,
                WithAlpha(IceWhite, 0.72f));

            CreateRouteNode(
                "Progress_End",
                new Vector3(-progressTrackStartX, -2.86f, -0.08f),
                parent,
                Gold);

            progressText = CreatePremiumText(
                "0%",
                parent,
                new Vector3(0f, -3.45f, 0f),
                34,
                0.045f,
                IceWhite,
                16,
                FontStyle.Bold);
        }

        private void CreateRouteNode(string name, Vector3 position, Transform parent, Color color)
        {
            CreateRect(name + "_Outer", new Vector2(0.20f, 0.20f), position, WithAlpha(color, 0.30f), 16, parent);
            CreateRect(name + "_Inner", new Vector2(0.085f, 0.085f), position + new Vector3(0f, 0f, -0.02f), color, 17, parent);
        }

        private void BuildFadeOverlay()
        {
            fadeRenderer = CreateRect(
                "Transition_Fade",
                new Vector2(GetWorldWidth() + 1f, ReferenceHalfHeight * 2f + 1f),
                new Vector3(0f, 0f, -1.5f),
                WithAlpha(Navy, 1f),
                1000);
        }

        private void UpdateSplash(float elapsed)
        {
            float progress = Mathf.Clamp01(elapsed / splashDurationSeconds);
            NormalizedProgress = progress;

            float intro = Smooth01(Mathf.Clamp01(elapsed / 0.72f));
            if (heroRoot != null)
            {
                float pulse = 1f + Mathf.Sin(elapsed * 1.35f) * 0.004f;
                heroRoot.localScale = Vector3.one * Mathf.Lerp(0.95f, pulse, intro);
                heroRoot.position = new Vector3(0f, Mathf.Lerp(-0.08f, 0.05f, intro), 0f);
            }

            if (glowRenderer != null)
            {
                float glow = 0.47f + Mathf.Sin(elapsed * 1.1f) * 0.06f;
                glowRenderer.color = WithAlpha(Color.white, glow * intro);
            }

            if (truckRenderer != null)
            {
                truckRenderer.transform.localPosition = new Vector3(
                    0f,
                    -1.12f + Mathf.Sin(elapsed * 0.9f) * 0.018f,
                    0.3f);
            }

            if (lightSweepRenderer != null)
            {
                float sweepT = Mathf.Repeat(elapsed / 2.7f, 1f);
                float worldWidth = GetWorldWidth();
                float x = Mathf.Lerp(-worldWidth * 0.42f, worldWidth * 0.42f, sweepT);
                float alpha = Mathf.Sin(sweepT * Mathf.PI) * 0.12f;
                lightSweepRenderer.transform.localPosition = new Vector3(x, 0.55f, -0.2f);
                lightSweepRenderer.color = WithAlpha(IceWhite, alpha);
            }

            UpdateFade(elapsed, splashDurationSeconds);

            if (!transitionIssued && progress >= 1f)
            {
                transitionIssued = true;
                TryLoadScene(loadingScene, "Loading");
            }
        }

        private void UpdateLoading(float elapsed)
        {
            float progress = Mathf.Clamp01(elapsed / loadingDurationSeconds);
            NormalizedProgress = progress;

            if (heroRoot != null)
            {
                heroRoot.position = new Vector3(0f, 0.15f + Mathf.Sin(elapsed * 0.85f) * 0.022f, 0f);
            }

            if (glowRenderer != null)
            {
                glowRenderer.color = WithAlpha(Color.white, 0.45f + Mathf.Sin(elapsed * 1.05f) * 0.045f);
            }

            if (truckRenderer != null && truckAltRenderer != null)
            {
                float crossFade = Smooth01(Mathf.InverseLerp(0.42f, 0.82f, progress));
                truckRenderer.color = WithAlpha(Color.white, 1f - crossFade * 0.82f);
                truckAltRenderer.color = WithAlpha(Color.white, crossFade);
            }

            UpdateProgressVisual(progress);
            UpdateFade(elapsed, loadingDurationSeconds);

            if (!transitionIssued && progress >= 1f)
            {
                transitionIssued = true;
                TryLoadScene(worldMapScene, "WorldMap");
            }
        }

        private void UpdateProgressVisual(float progress)
        {
            if (progressFillTransform != null)
            {
                float width = Mathf.Max(0.001f, progressTrackWidth * progress);
                progressFillTransform.localScale = new Vector3(width, 0.10f, 1f);
                progressFillTransform.localPosition = new Vector3(
                    progressTrackStartX + width * 0.5f,
                    -2.86f,
                    -0.04f);
            }

            if (progressText != null)
            {
                progressText.text = $"{Mathf.RoundToInt(progress * 100f):0}%";
            }
        }

        private void UpdateFade(float elapsed, float duration)
        {
            if (fadeRenderer == null)
            {
                return;
            }

            float introAlpha = 1f - Mathf.Clamp01(elapsed / TransitionFadeSeconds);
            float outroStart = Mathf.Max(TransitionFadeSeconds, duration - TransitionFadeSeconds);
            float outroAlpha = Mathf.InverseLerp(outroStart, duration, elapsed);
            float alpha = Mathf.Clamp01(Mathf.Max(introAlpha, outroAlpha));
            fadeRenderer.color = WithAlpha(Navy, alpha);
        }

        private void TryLoadScene(string sceneName, string label)
        {
            if (string.IsNullOrWhiteSpace(sceneName))
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] {label} scene name is empty.");
                return;
            }

            if (!Application.CanStreamedLevelBeLoaded(sceneName))
            {
                Debug.LogWarning(
                    $"[CARGO V2][UI_TEAM] {label} scene '{sceneName}' is not yet available in the player build. " +
                    "The current premium UI checkpoint remains visible for QA.");
                return;
            }

            SceneManager.LoadScene(sceneName, LoadSceneMode.Single);
        }

        private void ValidateRequiredArt()
        {
            if (logoSprite == null)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] Missing bound logo sprite from {LogoAssetPath}.");
            }

            if (truckSprite == null)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] Missing bound truck sprite from {TruckAssetPath}.");
            }

            if (glowSprite == null)
            {
                Debug.LogWarning($"[CARGO V2][UI_TEAM] Missing bound glow sprite from {GlowAssetPath}.");
            }
        }

        private SpriteRenderer CreateArt(
            string name,
            Sprite sprite,
            float targetWidth,
            Transform parent,
            Vector3 localPosition,
            int sortingOrder,
            Color color)
        {
            if (sprite == null)
            {
                return null;
            }

            GameObject go = new GameObject(name);
            Transform transformRef = go.transform;
            transformRef.SetParent(parent, false);
            transformRef.localPosition = localPosition;

            SpriteRenderer renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = sprite;
            renderer.sortingOrder = sortingOrder;
            renderer.color = color;

            float spriteWidth = Mathf.Max(0.001f, sprite.bounds.size.x);
            float scale = targetWidth / spriteWidth;
            transformRef.localScale = new Vector3(scale, scale, 1f);
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
            Transform transformRef = go.transform;
            transformRef.SetParent(parent, false);
            transformRef.localPosition = position;
            transformRef.localScale = new Vector3(size.x, size.y, 1f);

            SpriteRenderer renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = solidSprite;
            renderer.color = color;
            renderer.sortingOrder = sortingOrder;
            return renderer;
        }

        private TextMesh CreatePremiumText(
            string text,
            Transform parent,
            Vector3 localPosition,
            int fontSize,
            float characterSize,
            Color color,
            int sortingOrder,
            FontStyle style)
        {
            GameObject go = new GameObject("Text_" + text.Replace(" ", "_"));
            Transform transformRef = go.transform;
            transformRef.SetParent(parent, false);
            transformRef.localPosition = localPosition;

            TextMesh mesh = go.AddComponent<TextMesh>();
            mesh.text = text;
            mesh.fontSize = fontSize;
            mesh.characterSize = characterSize;
            mesh.anchor = TextAnchor.MiddleCenter;
            mesh.alignment = TextAlignment.Center;
            mesh.color = color;
            mesh.fontStyle = style;

            MeshRenderer meshRenderer = go.GetComponent<MeshRenderer>();
            meshRenderer.sortingOrder = sortingOrder;
            return mesh;
        }

        private float GetWorldWidth()
        {
            float aspect = Mathf.Max(0.6f, (float)Screen.width / Mathf.Max(1f, Screen.height));
            return ReferenceHalfHeight * 2f * aspect;
        }

        private static Color WithAlpha(Color color, float alpha)
        {
            color.a = Mathf.Clamp01(alpha);
            return color;
        }

        private static float Smooth01(float value)
        {
            return value * value * (3f - 2f * value);
        }
    }
}
