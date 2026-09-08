using CargoV2.Data;
using UnityEngine;

namespace CargoV2.UI
{
    public static class CargoV2UiLayout
    {
        public const float ReferenceWidth = 1920f;
        public const float ReferenceHeight = 1080f;
        public const float MinimumTouchPixels = 84f;

        public static Rect SafeGuiRect => ToGuiRect(Screen.safeArea, Screen.height);

        public static Rect ToGuiRect(Rect screenSafeArea, float screenHeight)
        {
            float height = Mathf.Max(1f, screenHeight);
            Rect safe = screenSafeArea;
            safe.x = Mathf.Max(0f, safe.x);
            safe.y = Mathf.Max(0f, safe.y);
            safe.width = Mathf.Max(1f, safe.width);
            safe.height = Mathf.Max(1f, safe.height);
            return new Rect(safe.x, Mathf.Max(0f, height - safe.yMax), safe.width, safe.height);
        }

        public static float Scale(Rect safeGuiRect, bool largeText = false)
        {
            float widthScale = Mathf.Max(1f, safeGuiRect.width) / ReferenceWidth;
            float heightScale = Mathf.Max(1f, safeGuiRect.height) / ReferenceHeight;
            float scale = Mathf.Clamp(Mathf.Min(widthScale, heightScale), 0.72f, 1.35f);
            if (largeText) scale = Mathf.Min(1.48f, scale * 1.14f);
            return scale;
        }

        public static float CurrentScale
        {
            get
            {
                CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
                return Scale(SafeGuiRect, settings.LargeText);
            }
        }

        public static float TouchSize(float scale)
        {
            return Mathf.Max(MinimumTouchPixels, 96f * Mathf.Clamp(scale, 0.72f, 1.48f));
        }

        public static float Margin(float scale)
        {
            return Mathf.Max(12f, 18f * Mathf.Clamp(scale, 0.72f, 1.48f));
        }

        public static Rect TopLeftPanel(Rect safe, float width, float height, float scale)
        {
            float margin = Margin(scale);
            return ClampToSafe(new Rect(safe.x + margin, safe.y + margin, width, height), safe);
        }

        public static Rect TopRightPanel(Rect safe, float width, float height, float scale)
        {
            float margin = Margin(scale);
            return ClampToSafe(new Rect(safe.xMax - margin - width, safe.y + margin, width, height), safe);
        }

        public static Rect ClampToSafe(Rect rect, Rect safe)
        {
            float width = Mathf.Min(Mathf.Max(1f, rect.width), Mathf.Max(1f, safe.width));
            float height = Mathf.Min(Mathf.Max(1f, rect.height), Mathf.Max(1f, safe.height));
            float x = Mathf.Clamp(rect.x, safe.x, Mathf.Max(safe.x, safe.xMax - width));
            float y = Mathf.Clamp(rect.y, safe.y, Mathf.Max(safe.y, safe.yMax - height));
            return new Rect(x, y, width, height);
        }

        public static Rect BottomLeftTouch(Rect safe, int index, float scale)
        {
            float size = TouchSize(scale);
            float gap = Mathf.Max(8f, 10f * scale);
            float margin = Margin(scale);
            return new Rect(safe.x + margin + (index * (size + gap)), safe.yMax - margin - size, size, size);
        }

        public static Rect BottomRightTouch(Rect safe, int indexFromRight, float scale)
        {
            float size = TouchSize(scale);
            float gap = Mathf.Max(8f, 10f * scale);
            float margin = Margin(scale);
            return new Rect(safe.xMax - margin - size - (indexFromRight * (size + gap)), safe.yMax - margin - size, size, size);
        }

        public static Rect TopRightTouch(Rect safe, int indexFromRight, float scale)
        {
            float height = Mathf.Max(48f, 54f * scale);
            float width = Mathf.Max(96f, 112f * scale);
            float gap = Mathf.Max(8f, 10f * scale);
            float margin = Margin(scale);
            return new Rect(safe.xMax - margin - width - (indexFromRight * (width + gap)), safe.y + margin, width, height);
        }

        public static bool ContainsScreenTouch(Rect guiRect, Vector2 screenPoint)
        {
            Vector2 guiPoint = new Vector2(screenPoint.x, Screen.height - screenPoint.y);
            return guiRect.Contains(guiPoint);
        }
    }
}
