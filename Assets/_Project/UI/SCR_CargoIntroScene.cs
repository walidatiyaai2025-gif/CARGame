using UnityEngine;
using UnityEngine.SceneManagement;

namespace CargoV2.UI
{
    public sealed class SCR_CargoIntroScene : MonoBehaviour
    {
        public enum IntroSceneKind { Splash = 0, Loading = 1, Onboarding = 2 }

        [SerializeField] private IntroSceneKind sceneKind = IntroSceneKind.Splash;
        [SerializeField] private float splashDurationSeconds = 3f;
        [SerializeField] private bool arabic;

        private static readonly Color Navy = new Color32(0x0A, 0x1A, 0x2F, 0xFF);
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private Transform heroRoot;
        private float startedAt;
        private int onboardingStep;

        private void Awake()
        {
            Application.targetFrameRate = 60;
            CreateCameraAndLightIfNeeded();
            RenderSettings.ambientLight = new Color(0.16f, 0.2f, 0.28f);
        }

        private void Start()
        {
            startedAt = Time.unscaledTime;
            if (sceneKind == IntroSceneKind.Splash) BuildSplash();
            Debug.Log($"[CARGO V2][UI] Scene ready: {sceneKind}");
        }

        private void Update()
        {
            if (sceneKind != IntroSceneKind.Splash || heroRoot == null) return;

            float elapsed = Time.unscaledTime - startedAt;
            heroRoot.Rotate(0f, 16f * Time.unscaledDeltaTime, 0f, Space.World);
            float intro = Mathf.Clamp01(elapsed / 0.7f);
            float pulse = 1f + Mathf.Sin(elapsed * 4.5f) * 0.025f;
            heroRoot.localScale = Vector3.one * Mathf.SmoothStep(0.15f, 1f, intro) * pulse;

            if (elapsed >= splashDurationSeconds && Application.CanStreamedLevelBeLoaded("02_Loading"))
            {
                SceneManager.LoadScene("02_Loading");
            }
        }

        private void OnGUI()
        {
            GUI.backgroundColor = Navy;
            GUI.color = Color.white;
            GUI.Box(new Rect(0f, 0f, Screen.width, Screen.height), GUIContent.none);

            if (sceneKind == IntroSceneKind.Splash)
            {
                DrawCenteredTitle("CARGO V2", Screen.height * 0.71f, Mathf.Max(30, Screen.height / 18));
                DrawCenteredLabel(arabic ? "ابنِ إمبراطورية الشحن العالمية" : "BUILD YOUR GLOBAL LOGISTICS EMPIRE", Screen.height * 0.80f, Mathf.Max(15, Screen.height / 38), Gold);
                return;
            }

            if (sceneKind == IntroSceneKind.Loading)
            {
                DrawCenteredTitle("CARGO V2", Screen.height * 0.28f, Mathf.Max(32, Screen.height / 17));
                float progress = Mathf.PingPong((Time.unscaledTime - startedAt) * 0.34f, 1f);
                Rect track = new Rect(Screen.width * 0.16f, Screen.height * 0.55f, Screen.width * 0.68f, 24f);
                GUI.color = new Color(1f, 1f, 1f, 0.18f);
                GUI.Box(track, GUIContent.none);
                GUI.color = Gold;
                GUI.Box(new Rect(track.x, track.y, track.width * progress, track.height), GUIContent.none);
                DrawCenteredLabel(arabic ? "جاري تجهيز الرحلة..." : "PREPARING YOUR ROUTE...", track.y + 50f, 18, Color.white);
                return;
            }

            DrawOnboarding();
        }

        private void BuildSplash()
        {
            heroRoot = new GameObject("CARGO_V2_Hero").transform;
            heroRoot.position = new Vector3(0f, 0.25f, 0f);

            Material goldMaterial = CreateMaterial(Gold, 0.45f);
            Material darkMaterial = CreateMaterial(Navy, 0.15f);

            GameObject trailer = GameObject.CreatePrimitive(PrimitiveType.Cube);
            trailer.name = "TruckTrailer";
            trailer.transform.SetParent(heroRoot, false);
            trailer.transform.localPosition = new Vector3(-0.55f, 0f, 0f);
            trailer.transform.localScale = new Vector3(1.75f, 0.75f, 0.72f);
            trailer.GetComponent<Renderer>().material = goldMaterial;

            GameObject cab = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cab.name = "TruckCab";
            cab.transform.SetParent(heroRoot, false);
            cab.transform.localPosition = new Vector3(0.75f, -0.1f, 0f);
            cab.transform.localScale = new Vector3(0.72f, 0.95f, 0.72f);
            cab.GetComponent<Renderer>().material = goldMaterial;

            for (int i = 0; i < 3; i++)
            {
                GameObject wheel = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                wheel.name = $"Wheel_{i}";
                wheel.transform.SetParent(heroRoot, false);
                wheel.transform.localPosition = new Vector3(-0.95f + i * 0.9f, -0.58f, 0f);
                wheel.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
                wheel.transform.localScale = new Vector3(0.34f, 0.16f, 0.34f);
                wheel.GetComponent<Renderer>().material = darkMaterial;
            }

            TextMesh logo = new GameObject("Cargo3DLogo").AddComponent<TextMesh>();
            logo.transform.SetParent(heroRoot, false);
            logo.transform.localPosition = new Vector3(0f, 1.45f, 0f);
            logo.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);
            logo.anchor = TextAnchor.MiddleCenter;
            logo.alignment = TextAlignment.Center;
            logo.text = "CARGO";
            logo.fontSize = 96;
            logo.characterSize = 0.06f;
            logo.color = Gold;

            ParticleSystem particles = new GameObject("GoldParticles").AddComponent<ParticleSystem>();
            particles.transform.SetParent(heroRoot, false);
            particles.transform.localPosition = Vector3.zero;
            var main = particles.main;
            main.loop = true;
            main.startLifetime = 1.6f;
            main.startSpeed = 1.1f;
            main.startSize = 0.07f;
            main.startColor = Gold;
            main.maxParticles = 80;
            var emission = particles.emission;
            emission.rateOverTime = 28f;
            var shape = particles.shape;
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = 1.5f;
        }

        private void DrawOnboarding()
        {
            string[] en = { "Deliver cargo across the world", "Complete missions and earn rewards", "Unlock cards and tournaments" };
            string[] ar = { "انقل الشحنات حول العالم", "أكمل المهام واحصل على المكافآت", "افتح البطاقات والبطولات" };
            string[] copy = arabic ? ar : en;

            DrawCenteredTitle(arabic ? "ابدأ رحلتك" : "START YOUR JOURNEY", Screen.height * 0.18f, Mathf.Max(28, Screen.height / 20));
            Rect card = new Rect(Screen.width * 0.1f, Screen.height * 0.33f, Screen.width * 0.8f, Screen.height * 0.28f);
            GUI.color = new Color(1f, 1f, 1f, 0.09f);
            GUI.Box(card, GUIContent.none);
            DrawCenteredLabel($"{onboardingStep + 1}/3", card.y + 35f, 18, Gold);
            DrawCenteredLabel(copy[onboardingStep], card.y + card.height * 0.5f, Mathf.Max(18, Screen.height / 34), Color.white);

            GUI.backgroundColor = Gold;
            GUI.color = Navy;
            Rect next = new Rect(Screen.width * 0.26f, Screen.height * 0.72f, Screen.width * 0.48f, 56f);
            if (GUI.Button(next, onboardingStep == 2 ? (arabic ? "ابدأ المهمة" : "START MISSION") : (arabic ? "متابعة" : "CONTINUE")))
            {
                onboardingStep = Mathf.Min(2, onboardingStep + 1);
            }
        }

        private static Material CreateMaterial(Color color, float metallic)
        {
            Shader shader = Shader.Find("Standard");
            Material material = new Material(shader != null ? shader : Shader.Find("Sprites/Default"));
            material.color = color;
            if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", metallic);
            if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", 0.72f);
            return material;
        }

        private static void CreateCameraAndLightIfNeeded()
        {
            if (Camera.main == null)
            {
                Camera camera = new GameObject("Main Camera").AddComponent<Camera>();
                camera.tag = "MainCamera";
                camera.transform.position = new Vector3(0f, 0.5f, -7f);
                camera.transform.rotation = Quaternion.identity;
                camera.clearFlags = CameraClearFlags.SolidColor;
                camera.backgroundColor = Navy;
            }

            if (FindFirstObjectByType<Light>() == null)
            {
                Light light = new GameObject("Key Light").AddComponent<Light>();
                light.type = LightType.Directional;
                light.color = new Color(1f, 0.82f, 0.48f);
                light.intensity = 1.5f;
                light.transform.rotation = Quaternion.Euler(38f, -42f, 0f);
            }
        }

        private static void DrawCenteredTitle(string text, float y, int size) => DrawCenteredLabel(text, y, size, Gold);

        private static void DrawCenteredLabel(string text, float y, int size, Color color)
        {
            GUIStyle style = new GUIStyle(GUI.skin.label)
            {
                alignment = TextAnchor.MiddleCenter,
                fontStyle = FontStyle.Bold,
                fontSize = size,
                wordWrap = true,
            };
            style.normal.textColor = color;
            GUI.Label(new Rect(Screen.width * 0.08f, y, Screen.width * 0.84f, Mathf.Max(70f, size * 2.4f)), text, style);
        }
    }
}
