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

        [SerializeField] private SceneMode sceneMode = SceneMode.Splash;
        [SerializeField, Min(0.5f)] private float splashDurationSeconds = 3f;
        [SerializeField, Min(0.5f)] private float loadingDurationSeconds = 2f;
        [SerializeField] private string splashScene = "01_Splash";
        [SerializeField] private string loadingScene = "02_Loading";
        [SerializeField] private string worldMapScene = "04_WorldMap";

        private static readonly Color Navy = new Color32(0x0A, 0x1A, 0x2F, 0xFF);
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);

        private float startedAt;
        private GameObject activeVisual;
        private bool transitionIssued;

        public float NormalizedProgress { get; private set; }

        private void Awake()
        {
            Application.targetFrameRate = 60;
            EnsureCameraAndLight();
            RenderSettings.ambientLight = new Color(0.14f, 0.18f, 0.27f);
        }

        private void Start()
        {
            startedAt = Time.unscaledTime;
            BuildVisibleCheckpoint();
            Debug.Log($"[CARGO V2][UI] {sceneMode} ready. Palette Navy=#0A1A2F Gold=#FFC107");
        }

        private void Update()
        {
            float elapsed = Time.unscaledTime - startedAt;

            switch (sceneMode)
            {
                case SceneMode.Splash:
                    NormalizedProgress = Mathf.Clamp01(elapsed / splashDurationSeconds);
                    if (!transitionIssued && elapsed >= splashDurationSeconds)
                    {
                        TransitionTo(loadingScene);
                    }
                    break;

                case SceneMode.Loading:
                    NormalizedProgress = Mathf.Clamp01(elapsed / loadingDurationSeconds);
                    if (activeVisual != null)
                    {
                        float x = Mathf.Lerp(-5.5f, 5.5f, Mathf.SmoothStep(0f, 1f, NormalizedProgress));
                        activeVisual.transform.position = new Vector3(x, 0.35f + Mathf.Sin(elapsed * 5f) * 0.05f, 0f);
                    }
                    if (!transitionIssued && NormalizedProgress >= 1f)
                    {
                        TransitionTo(worldMapScene);
                    }
                    break;
            }
        }

        private void BuildVisibleCheckpoint()
        {
            if (sceneMode == SceneMode.Splash)
            {
                activeVisual = SpawnResourcePrefab("PREFAB_CARGO_V2_Logo");
                return;
            }

            if (sceneMode == SceneMode.Loading)
            {
                activeVisual = SpawnResourcePrefab("PREFAB_IMG_Truck_3D");
                if (activeVisual != null)
                {
                    activeVisual.transform.position = new Vector3(-5.5f, 0.35f, 0f);
                    activeVisual.transform.localScale = Vector3.one * 0.85f;
                }
            }
        }

        private static GameObject SpawnResourcePrefab(string resourceName)
        {
            GameObject prefab = Resources.Load<GameObject>(resourceName);
            if (prefab == null)
            {
                Debug.LogError($"[CARGO V2][UI] Missing Resources prefab: {resourceName}");
                return null;
            }
            return Instantiate(prefab);
        }

        private void TransitionTo(string sceneName)
        {
            transitionIssued = true;
            if (string.IsNullOrWhiteSpace(sceneName))
            {
                Debug.LogError("[CARGO V2][UI] Transition blocked: target scene name is empty.");
                return;
            }

            if (!Application.CanStreamedLevelBeLoaded(sceneName))
            {
                Debug.LogError($"[CARGO V2][UI] Transition blocked: scene '{sceneName}' is not in Build Settings.");
                return;
            }

            Debug.Log($"[CARGO V2][UI] Transition {SceneManager.GetActiveScene().name} -> {sceneName}");
            SceneManager.LoadScene(sceneName, LoadSceneMode.Single);
        }

        private void OnGUI()
        {
            GUI.color = Color.white;

            if (sceneMode == SceneMode.Splash)
            {
                DrawCentered("CARGO V2", Screen.height * 0.70f, Mathf.Max(32, Screen.height / 18), Gold);
                DrawCentered("GLOBAL LOGISTICS EMPIRE", Screen.height * 0.80f, Mathf.Max(15, Screen.height / 42), Color.white);
                return;
            }

            if (sceneMode == SceneMode.Loading)
            {
                DrawCentered("LOADING WORLD ROUTE", Screen.height * 0.23f, Mathf.Max(24, Screen.height / 24), Gold);
                DrawProgressBar();
                return;
            }

            DrawCentered("WORLD MAP", Screen.height * 0.42f, Mathf.Max(36, Screen.height / 16), Gold);
            DrawCentered("VISIBLE CHECKPOINT REACHED", Screen.height * 0.53f, Mathf.Max(16, Screen.height / 40), Color.white);
        }

        private void DrawProgressBar()
        {
            Rect track = new Rect(Screen.width * 0.14f, Screen.height * 0.72f, Screen.width * 0.72f, Mathf.Max(22f, Screen.height * 0.026f));

            GUI.color = Color.white;
            GUI.backgroundColor = new Color(1f, 1f, 1f, 0.22f);
            GUI.Box(track, GUIContent.none);

            GUI.color = Color.white;
            GUI.backgroundColor = Gold;
            GUI.Box(new Rect(track.x, track.y, track.width * NormalizedProgress, track.height), GUIContent.none);

            GUI.backgroundColor = Color.white;
            DrawCentered($"{Mathf.RoundToInt(NormalizedProgress * 100f)}%", track.y + track.height + 12f, Mathf.Max(15, Screen.height / 44), Color.white);
        }

        private static void DrawCentered(string text, float y, int size, Color color)
        {
            GUIStyle style = new GUIStyle(GUI.skin.label)
            {
                alignment = TextAnchor.MiddleCenter,
                fontSize = size,
                fontStyle = FontStyle.Bold,
                wordWrap = true,
            };
            style.normal.textColor = color;
            GUI.Label(new Rect(Screen.width * 0.06f, y, Screen.width * 0.88f, Mathf.Max(64f, size * 2.3f)), text, style);
        }

        private static void EnsureCameraAndLight()
        {
            Camera camera = Camera.main;
            if (camera == null)
            {
                camera = new GameObject("Main Camera").AddComponent<Camera>();
                camera.tag = "MainCamera";
            }
            camera.orthographic = true;
            camera.orthographicSize = 4.6f;
            camera.transform.position = new Vector3(0f, 0.2f, -10f);
            camera.transform.rotation = Quaternion.identity;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Navy;

            if (FindFirstObjectByType<Light>() == null)
            {
                Light key = new GameObject("CARGO V2 Key Light").AddComponent<Light>();
                key.type = LightType.Directional;
                key.color = new Color(1f, 0.81f, 0.42f);
                key.intensity = 1.55f;
                key.transform.rotation = Quaternion.Euler(38f, -42f, 0f);
            }
        }
    }
}
