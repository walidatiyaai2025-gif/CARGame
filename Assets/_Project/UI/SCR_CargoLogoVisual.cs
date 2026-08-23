using UnityEngine;

namespace CargoV2.UI
{
    public sealed class SCR_CargoLogoVisual : MonoBehaviour
    {
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private static readonly Color DeepGold = new Color32(0xB8, 0x73, 0x00, 0xFF);
        private float startedAt;

        private void Awake()
        {
            startedAt = Time.unscaledTime;
            BuildExtrudedLogo();
            BuildGlowParticles();
        }

        private void Update()
        {
            float t = Time.unscaledTime - startedAt;
            transform.rotation = Quaternion.Euler(0f, Mathf.Sin(t * 1.15f) * 7f, 0f);
            float s = 1f + Mathf.Sin(t * 3.2f) * 0.025f;
            transform.localScale = Vector3.one * s;
        }

        private void BuildExtrudedLogo()
        {
            const int depthLayers = 8;
            for (int i = depthLayers - 1; i >= 0; i--)
            {
                TextMesh layer = new GameObject($"LogoDepth_{i}").AddComponent<TextMesh>();
                layer.transform.SetParent(transform, false);
                layer.transform.localPosition = new Vector3(0f, 0.55f, i * 0.018f);
                layer.anchor = TextAnchor.MiddleCenter;
                layer.alignment = TextAlignment.Center;
                layer.fontSize = 116;
                layer.characterSize = 0.055f;
                layer.fontStyle = FontStyle.Bold;
                layer.text = "CARGO V2";
                layer.color = i == 0 ? Gold : Color.Lerp(DeepGold, Gold, i / (float)depthLayers * 0.45f);
            }

            TextMesh sub = new GameObject("LogoSubtitle").AddComponent<TextMesh>();
            sub.transform.SetParent(transform, false);
            sub.transform.localPosition = new Vector3(0f, -0.55f, 0f);
            sub.anchor = TextAnchor.MiddleCenter;
            sub.alignment = TextAlignment.Center;
            sub.fontSize = 48;
            sub.characterSize = 0.042f;
            sub.text = "GLOBAL LOGISTICS";
            sub.color = Color.white;
        }

        private void BuildGlowParticles()
        {
            Light glow = new GameObject("VFX_Glow").AddComponent<Light>();
            glow.transform.SetParent(transform, false);
            glow.type = LightType.Point;
            glow.color = Gold;
            glow.intensity = 2.2f;
            glow.range = 5.5f;

            ParticleSystem ps = new GameObject("VFX_GoldParticles").AddComponent<ParticleSystem>();
            ps.transform.SetParent(transform, false);
            var main = ps.main;
            main.loop = true;
            main.startLifetime = 1.8f;
            main.startSpeed = 0.7f;
            main.startSize = 0.055f;
            main.startColor = Gold;
            main.maxParticles = 96;
            main.simulationSpace = ParticleSystemSimulationSpace.Local;

            var emission = ps.emission;
            emission.rateOverTime = 34f;

            var shape = ps.shape;
            shape.shapeType = ParticleSystemShapeType.Box;
            shape.scale = new Vector3(4.2f, 1.6f, 0.5f);
        }
    }
}
