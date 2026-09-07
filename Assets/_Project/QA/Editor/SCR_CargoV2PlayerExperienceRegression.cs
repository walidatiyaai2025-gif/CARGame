#if UNITY_EDITOR
using System;
using CargoV2.Data;
using CargoV2.UI;
using UnityEngine;

namespace CargoV2.QA.EditorTools
{
    public static class SCR_CargoV2PlayerExperienceRegression
    {
        private const string ProgressKey = "cargo_v2.progress.v1";
        private const string EconomyKey = "cargo_v2_mission_economy_v1";

        public static void ValidateOrThrow()
        {
            PrefSnapshot snapshot = PrefSnapshot.Capture();
            try
            {
                ValidateSettingsIsolationAndRecovery();
                ValidateSafeAreaLayouts();
            }
            finally
            {
                snapshot.Restore();
            }
        }

        private static void ValidateSettingsIsolationAndRecovery()
        {
            PlayerPrefs.DeleteKey(CargoV2PlayerSettings.SettingsKey);
            PlayerPrefs.DeleteKey(CargoV2PlayerSettings.CorruptBackupKey);
            const string progressSentinel = "PLAYER_EXPERIENCE_MUST_NOT_TOUCH_PROGRESS";
            const string economySentinel = "PLAYER_EXPERIENCE_MUST_NOT_TOUCH_ECONOMY";
            PlayerPrefs.SetString(ProgressKey, progressSentinel);
            PlayerPrefs.SetString(EconomyKey, economySentinel);
            PlayerPrefs.Save();

            CargoV2PlayerSettings.Snapshot defaults = CargoV2PlayerSettings.Load();
            if (defaults.Language != CargoV2PlayerSettings.Language.English ||
                defaults.Muted || !defaults.Haptics || defaults.ReducedMotion || defaults.LargeText)
            {
                throw new InvalidOperationException("Fresh player settings did not resolve to the approved safe defaults.");
            }

            CargoV2PlayerSettings.Snapshot expected = new CargoV2PlayerSettings.Snapshot(
                CargoV2PlayerSettings.Language.Arabic,
                0.6f,
                0.4f,
                0.7f,
                true,
                false,
                true,
                true);
            if (!CargoV2PlayerSettings.TrySave(expected))
            {
                throw new InvalidOperationException("Valid player settings could not be persisted.");
            }

            CargoV2PlayerSettings.Snapshot loaded = CargoV2PlayerSettings.Load();
            if (loaded.Language != expected.Language ||
                !Approximately(loaded.MasterVolume, expected.MasterVolume) ||
                !Approximately(loaded.SfxVolume, expected.SfxVolume) ||
                !Approximately(loaded.EngineVolume, expected.EngineVolume) ||
                loaded.Muted != expected.Muted ||
                loaded.Haptics != expected.Haptics ||
                loaded.ReducedMotion != expected.ReducedMotion ||
                loaded.LargeText != expected.LargeText)
            {
                throw new InvalidOperationException("Player settings round-trip changed a persisted preference.");
            }

            AssertGameplaySentinels(progressSentinel, economySentinel);

            const string corrupt = "{\"schemaVersion\":99,\"language\":7,\"masterVolume\":4.0}";
            PlayerPrefs.SetString(CargoV2PlayerSettings.SettingsKey, corrupt);
            PlayerPrefs.Save();
            CargoV2PlayerSettings.Snapshot recovered = CargoV2PlayerSettings.Load();
            if (recovered.Language != CargoV2PlayerSettings.Language.English ||
                !Approximately(recovered.MasterVolume, CargoV2PlayerSettings.DefaultMasterVolume))
            {
                throw new InvalidOperationException("Corrupt player settings did not recover to safe defaults.");
            }
            if (PlayerPrefs.HasKey(CargoV2PlayerSettings.SettingsKey))
            {
                throw new InvalidOperationException("Corrupt player settings were not removed from the active key.");
            }
            if (!string.Equals(PlayerPrefs.GetString(CargoV2PlayerSettings.CorruptBackupKey, string.Empty), corrupt, StringComparison.Ordinal))
            {
                throw new InvalidOperationException("Corrupt player settings were not quarantined for diagnostics.");
            }

            AssertGameplaySentinels(progressSentinel, economySentinel);
        }

        private static void ValidateSafeAreaLayouts()
        {
            LayoutCase[] cases =
            {
                new LayoutCase("1080p", 1920f, 1080f, new Rect(0f, 0f, 1920f, 1080f)),
                new LayoutCase("wide-notch", 2340f, 1080f, new Rect(96f, 0f, 2148f, 1080f)),
                new LayoutCase("720p", 1280f, 720f, new Rect(0f, 0f, 1280f, 720f)),
                new LayoutCase("ultrawide", 2560f, 1080f, new Rect(60f, 0f, 2440f, 1080f)),
                new LayoutCase("high-density-cutout", 2960f, 1440f, new Rect(120f, 36f, 2720f, 1368f)),
            };

            for (int i = 0; i < cases.Length; i++)
            {
                LayoutCase test = cases[i];
                Rect safe = CargoV2UiLayout.ToGuiRect(test.ScreenSafeArea, test.ScreenHeight);
                float normalScale = CargoV2UiLayout.Scale(safe, false);
                float largeScale = CargoV2UiLayout.Scale(safe, true);
                if (largeScale + 0.001f < normalScale)
                {
                    throw new InvalidOperationException($"{test.Name}: Large Text reduced UI scale.");
                }

                Rect left = CargoV2UiLayout.BottomLeftTouch(safe, 0, normalScale);
                Rect right = CargoV2UiLayout.BottomLeftTouch(safe, 1, normalScale);
                Rect brake = CargoV2UiLayout.BottomRightTouch(safe, 1, normalScale);
                Rect throttle = CargoV2UiLayout.BottomRightTouch(safe, 0, normalScale);
                Rect pause = CargoV2UiLayout.TopRightTouch(safe, 0, normalScale);
                Rect recover = CargoV2UiLayout.TopRightTouch(safe, 1, normalScale);
                Rect hud = CargoV2UiLayout.TopLeftPanel(
                    safe,
                    Mathf.Min(safe.width * 0.58f, Mathf.Max(390f, 590f * normalScale)),
                    Mathf.Min(safe.height * 0.46f, Mathf.Max(230f, 310f * normalScale)),
                    normalScale);

                AssertInside(test.Name, safe, left, "left steering");
                AssertInside(test.Name, safe, right, "right steering");
                AssertInside(test.Name, safe, brake, "brake/reverse");
                AssertInside(test.Name, safe, throttle, "throttle");
                AssertInside(test.Name, safe, pause, "pause");
                AssertInside(test.Name, safe, recover, "recover");
                AssertInside(test.Name, safe, hud, "HUD");

                if (left.width < CargoV2UiLayout.MinimumTouchPixels ||
                    right.width < CargoV2UiLayout.MinimumTouchPixels ||
                    brake.width < CargoV2UiLayout.MinimumTouchPixels ||
                    throttle.width < CargoV2UiLayout.MinimumTouchPixels)
                {
                    throw new InvalidOperationException($"{test.Name}: driving touch target fell below minimum size.");
                }
                if (left.Overlaps(right) || brake.Overlaps(throttle) || pause.Overlaps(recover))
                {
                    throw new InvalidOperationException($"{test.Name}: adjacent controls overlap.");
                }
                if (left.Overlaps(brake) || right.Overlaps(throttle))
                {
                    throw new InvalidOperationException($"{test.Name}: steering and pedal control clusters overlap.");
                }
            }
        }

        private static void AssertInside(string testName, Rect safe, Rect rect, string label)
        {
            const float epsilon = 0.5f;
            if (rect.xMin < safe.xMin - epsilon || rect.yMin < safe.yMin - epsilon ||
                rect.xMax > safe.xMax + epsilon || rect.yMax > safe.yMax + epsilon)
            {
                throw new InvalidOperationException($"{testName}: {label} escaped the safe area. safe={safe}, rect={rect}");
            }
        }

        private static bool Approximately(float left, float right)
        {
            return Mathf.Abs(left - right) <= 0.0001f;
        }

        private static void AssertGameplaySentinels(string progress, string economy)
        {
            if (!string.Equals(PlayerPrefs.GetString(ProgressKey, string.Empty), progress, StringComparison.Ordinal) ||
                !string.Equals(PlayerPrefs.GetString(EconomyKey, string.Empty), economy, StringComparison.Ordinal))
            {
                throw new InvalidOperationException("Player settings mutated progression or economy persistence.");
            }
        }

        private readonly struct LayoutCase
        {
            public LayoutCase(string name, float screenWidth, float screenHeight, Rect screenSafeArea)
            {
                Name = name;
                ScreenWidth = screenWidth;
                ScreenHeight = screenHeight;
                ScreenSafeArea = screenSafeArea;
            }

            public string Name { get; }
            public float ScreenWidth { get; }
            public float ScreenHeight { get; }
            public Rect ScreenSafeArea { get; }
        }

        private sealed class PrefSnapshot
        {
            private readonly StringState settings = StringState.Capture(CargoV2PlayerSettings.SettingsKey);
            private readonly StringState corrupt = StringState.Capture(CargoV2PlayerSettings.CorruptBackupKey);
            private readonly StringState progress = StringState.Capture(ProgressKey);
            private readonly StringState economy = StringState.Capture(EconomyKey);

            public static PrefSnapshot Capture() => new PrefSnapshot();

            public void Restore()
            {
                settings.Restore(CargoV2PlayerSettings.SettingsKey);
                corrupt.Restore(CargoV2PlayerSettings.CorruptBackupKey);
                progress.Restore(ProgressKey);
                economy.Restore(EconomyKey);
                PlayerPrefs.Save();
            }
        }

        private readonly struct StringState
        {
            private readonly bool exists;
            private readonly string value;

            private StringState(bool exists, string value)
            {
                this.exists = exists;
                this.value = value;
            }

            public static StringState Capture(string key)
            {
                return new StringState(PlayerPrefs.HasKey(key), PlayerPrefs.GetString(key, string.Empty));
            }

            public void Restore(string key)
            {
                if (exists) PlayerPrefs.SetString(key, value);
                else PlayerPrefs.DeleteKey(key);
            }
        }
    }
}
#endif
