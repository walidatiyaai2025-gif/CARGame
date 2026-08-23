using UnityEngine;

namespace CargoV2.UI
{
    public sealed class SCR_TruckVisual : MonoBehaviour
    {
        private static readonly Color Gold = new Color32(0xFF, 0xC1, 0x07, 0xFF);
        private static readonly Color DeepGold = new Color32(0xC4, 0x7B, 0x00, 0xFF);
        private static readonly Color Navy = new Color32(0x0A, 0x1A, 0x2F, 0xFF);
        private readonly Transform[] wheels = new Transform[4];

        private void Awake()
        {
            gameObject.name = "IMG_Truck_3D";
            BuildTruck();
        }

        private void Update()
        {
            float degrees = 420f * Time.unscaledDeltaTime;
            for (int i = 0; i < wheels.Length; i++)
            {
                if (wheels[i] != null) wheels[i].Rotate(0f, degrees, 0f, Space.Self);
            }
        }

        private void BuildTruck()
        {
            Material gold = CreateMaterial(Gold, 0.55f, 0.78f);
            Material deepGold = CreateMaterial(DeepGold, 0.4f, 0.7f);
            Material navy = CreateMaterial(Navy, 0.15f, 0.45f);
            Material white = CreateMaterial(Color.white, 0.1f, 0.55f);

            CreatePart("Trailer", PrimitiveType.Cube, new Vector3(-0.65f, 0.35f, 0f), new Vector3(2.25f, 1.15f, 0.95f), gold);
            CreatePart("TrailerTop", PrimitiveType.Cube, new Vector3(-0.65f, 0.94f, 0f), new Vector3(2.15f, 0.08f, 0.84f), white);
            CreatePart("Cab", PrimitiveType.Cube, new Vector3(1.05f, 0.18f, 0f), new Vector3(0.88f, 1.25f, 0.95f), deepGold);
            CreatePart("Windshield", PrimitiveType.Cube, new Vector3(1.04f, 0.48f, -0.49f), new Vector3(0.55f, 0.42f, 0.035f), navy);
            CreatePart("Bumper", PrimitiveType.Cube, new Vector3(1.55f, -0.23f, 0f), new Vector3(0.18f, 0.18f, 1.02f), white);

            float[] wheelX = { -1.28f, -0.25f, 0.85f, 1.36f };
            for (int i = 0; i < wheelX.Length; i++)
            {
                GameObject wheel = CreatePart($"Wheel_{i + 1}", PrimitiveType.Cylinder, new Vector3(wheelX[i], -0.42f, 0f), new Vector3(0.42f, 0.19f, 0.42f), navy);
                wheel.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
                wheels[i] = wheel.transform;
                CreatePart($"Hub_{i + 1}", PrimitiveType.Cylinder, new Vector3(wheelX[i], -0.42f, -0.2f), new Vector3(0.2f, 0.205f, 0.2f), gold).transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            }

            Light headlight = new GameObject("TruckGlow").AddComponent<Light>();
            headlight.transform.SetParent(transform, false);
            headlight.transform.localPosition = new Vector3(1.55f, 0.05f, -0.55f);
            headlight.type = LightType.Point;
            headlight.color = Gold;
            headlight.range = 3f;
            headlight.intensity = 1.25f;
        }

        private GameObject CreatePart(string partName, PrimitiveType primitive, Vector3 localPosition, Vector3 localScale, Material material)
        {
            GameObject part = GameObject.CreatePrimitive(primitive);
            part.name = partName;
            part.transform.SetParent(transform, false);
            part.transform.localPosition = localPosition;
            part.transform.localScale = localScale;
            Collider collider = part.GetComponent<Collider>();
            if (collider != null) Destroy(collider);
            Renderer renderer = part.GetComponent<Renderer>();
            if (renderer != null && material != null) renderer.material = material;
            return part;
        }

        private static Material CreateMaterial(Color color, float metallic, float smoothness)
        {
            Shader shader = Shader.Find("Standard");
            if (shader == null) shader = Shader.Find("Universal Render Pipeline/Lit");
            if (shader == null) shader = Shader.Find("Sprites/Default");
            if (shader == null) return null;

            Material material = new Material(shader) { color = color };
            if (material.HasProperty("_Metallic")) material.SetFloat("_Metallic", metallic);
            if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", smoothness);
            if (material.HasProperty("_Smoothness")) material.SetFloat("_Smoothness", smoothness);
            return material;
        }
    }
}
