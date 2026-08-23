using UnityEngine;
using UnityEngine.UI;

namespace CargoV2.QA
{
    public sealed class FPSCounter : MonoBehaviour
    {
        [SerializeField] private Text label;
        [SerializeField, Min(0.1f)] private float sampleWindowSeconds = 0.5f;

        private float elapsed;
        private int frames;
        private float currentFps;

        public float CurrentFps => currentFps;

        private void Update()
        {
            elapsed += Time.unscaledDeltaTime;
            frames++;

            if (elapsed < sampleWindowSeconds) return;

            currentFps = elapsed > 0f ? frames / elapsed : 0f;
            if (label != null) label.text = $"FPS {currentFps:0.0}";
            Debug.Log($"[CARGO V2][QA] FPS={currentFps:0.0}");
            elapsed = 0f;
            frames = 0;
        }
    }
}
