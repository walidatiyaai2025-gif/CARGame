using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_PremiumTruck3D : MonoBehaviour
    {
        [SerializeField] private bool loadingMode;
        [SerializeField] private float targetHeight = 3.55f;
        [SerializeField] private Vector3 splashPosition = new Vector3(0f, -1.10f, -0.72f);
        [SerializeField] private Vector3 loadingPosition = new Vector3(2.15f, -0.18f, -0.72f);
        [SerializeField] private Vector3 splashEuler = new Vector3(6f, -22f, 0f);
        [SerializeField] private Vector3 loadingEuler = new Vector3(4f, -33f, 0f);
        [SerializeField] private float idleYawAmplitude = 1.1f;
        [SerializeField] private float idleYawSpeed = 0.48f;
        [SerializeField] private float idleBobAmplitude = 0.025f;
        [SerializeField] private float idleBobSpeed = 1.05f;

        private Vector3 basePosition;
        private Quaternion baseRotation;
        private bool normalized;

        public void Configure(bool isLoading)
        {
            loadingMode = isLoading;
        }

        private void Start()
        {
            NormalizeAndPlace();
            EnsurePresentationLights();
        }

        private void LateUpdate()
        {
            if (!normalized)
            {
                return;
            }

            float t = Time.unscaledTime;
            float yaw = Mathf.Sin(t * idleYawSpeed) * idleYawAmplitude;
            float bob = Mathf.Sin(t * idleBobSpeed) * idleBobAmplitude;

            transform.position = basePosition + Vector3.up * bob;
            transform.rotation = baseRotation * Quaternion.Euler(0f, yaw, 0f);
        }

        private void NormalizeAndPlace()
        {
            Renderer[] renderers = GetComponentsInChildren<Renderer>(true);
            if (renderers.Length == 0)
            {
                Debug.LogError("[CARGO V2][UI_TEAM] Premium 3D truck has no renderers after import.");
                return;
            }

            Bounds bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            float height = Mathf.Max(bounds.size.y, 0.0001f);
            float scale = targetHeight / height;
            transform.localScale = Vector3.one * scale;

            bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            Transform model = transform.childCount > 0 ? transform.GetChild(0) : null;
            if (model != null)
            {
                Vector3 centerLocal = transform.InverseTransformPoint(bounds.center);
                model.localPosition -= centerLocal;
            }

            basePosition = loadingMode ? loadingPosition : splashPosition;
            baseRotation = Quaternion.Euler(loadingMode ? loadingEuler : splashEuler);
            transform.position = basePosition;
            transform.rotation = baseRotation;
            normalized = true;
        }

        private void EnsurePresentationLights()
        {
            if (GetComponentInChildren<Light>() != null)
            {
                return;
            }

            CreateLight(
                "PremiumTruck_Key",
                LightType.Directional,
                new Color(1.0f, 0.76f, 0.34f),
                1.32f,
                new Vector3(30f, -38f, 0f));

            CreateLight(
                "PremiumTruck_Rim",
                LightType.Directional,
                new Color(0.28f, 0.63f, 1.0f),
                0.84f,
                new Vector3(16f, 146f, 0f));

            CreateLight(
                "PremiumTruck_Fill",
                LightType.Directional,
                new Color(0.95f, 0.55f, 0.18f),
                0.38f,
                new Vector3(58f, 68f, 0f));
        }

        private void CreateLight(string lightName, LightType type, Color color, float intensity, Vector3 euler)
        {
            GameObject lightObject = new GameObject(lightName);
            lightObject.transform.SetParent(transform, false);
            lightObject.transform.rotation = Quaternion.Euler(euler);

            Light light = lightObject.AddComponent<Light>();
            light.type = type;
            light.color = color;
            light.intensity = intensity;
            light.shadows = LightShadows.None;
        }
    }
}
