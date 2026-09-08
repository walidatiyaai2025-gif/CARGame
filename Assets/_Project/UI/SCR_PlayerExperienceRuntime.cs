using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_PlayerExperienceRuntime : MonoBehaviour
    {
        private static SCR_PlayerExperienceRuntime instance;

        private bool settingsOpen;
        private bool helpOpen;
        private string status = string.Empty;
        private float statusUntil;
        private Rect settingsButtonRect;
        private Rect helpButtonRect;
        private Rect modalRect;

        public static bool HasModalOpen => instance != null && (instance.settingsOpen || instance.helpOpen);

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
        {
            if (instance != null) return;
            GameObject host = new GameObject("CARGO_V2_PlayerExperience");
            instance = host.AddComponent<SCR_PlayerExperienceRuntime>();
            DontDestroyOnLoad(host);
        }

        private void Awake()
        {
            if (instance != null && instance != this)
            {
                Destroy(gameObject);
                return;
            }
            instance = this;
            DontDestroyOnLoad(gameObject);
        }

        private void Update()
        {
            // Mission runtime consumes Back first while a contract is active so a
            // modal close can never also resume/abandon the contract in the same key press.
            if (!SCR_MissionRuntimeDirector.IsRunning && HasModalOpen && Input.GetKeyDown(KeyCode.Escape))
            {
                TryHandleBack();
            }
        }

        private void OnDestroy()
        {
            if (instance == this) instance = null;
        }

        public static void OpenSettings()
        {
            EnsureInstance();
            instance.settingsOpen = true;
            instance.helpOpen = false;
            SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
        }

        public static void OpenHelp()
        {
            EnsureInstance();
            instance.helpOpen = true;
            instance.settingsOpen = false;
            SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
        }

        public static void CloseModal()
        {
            if (instance == null) return;
            instance.settingsOpen = false;
            instance.helpOpen = false;
            SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
        }

        public static bool TryHandleBack()
        {
            if (!HasModalOpen) return false;
            CloseModal();
            return true;
        }

        public static bool IsPointOverOverlay(Vector2 guiPoint)
        {
            if (instance == null) return false;
            if (instance.settingsOpen || instance.helpOpen) return true;
            if (!instance.IsWorldMapAvailable()) return false;
            return instance.settingsButtonRect.Contains(guiPoint) || instance.helpButtonRect.Contains(guiPoint);
        }

        private static void EnsureInstance()
        {
            if (instance != null) return;
            GameObject host = new GameObject("CARGO_V2_PlayerExperience");
            instance = host.AddComponent<SCR_PlayerExperienceRuntime>();
            DontDestroyOnLoad(host);
        }

        private bool IsWorldMapAvailable()
        {
            return !SCR_MissionRuntimeDirector.IsRunning && FindObjectOfType<SCR_WorldMapRouteController>() != null;
        }

        private void OnGUI()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
            float scale = CargoV2UiLayout.Scale(safe, settings.LargeText);

            if (IsWorldMapAvailable() && !settingsOpen && !helpOpen)
            {
                DrawWorldMapButtons(safe, scale);
            }
            else
            {
                settingsButtonRect = default;
                helpButtonRect = default;
            }

            if (settingsOpen) DrawSettings(safe, scale, settings);
            else if (helpOpen) DrawHelp(safe, scale);
            else modalRect = default;
        }

        private void DrawWorldMapButtons(Rect safe, float scale)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float height = Mathf.Max(48f, 54f * scale);
            float width = Mathf.Max(108f, 128f * scale);
            float gap = Mathf.Max(8f, 10f * scale);
            settingsButtonRect = new Rect(safe.x + margin, safe.y + margin, width, height);
            helpButtonRect = new Rect(settingsButtonRect.xMax + gap, settingsButtonRect.y, width, height);

            GUIStyle button = ButtonStyle(scale);
            if (GUI.Button(settingsButtonRect, L("settings.title"), button)) OpenSettings();
            if (GUI.Button(helpButtonRect, L("help.title"), button)) OpenHelp();
        }

        private void DrawSettings(Rect safe, float scale, CargoV2PlayerSettings.Snapshot settings)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float width = Mathf.Min(safe.width - margin * 2f, Mathf.Max(430f, 640f * scale));
            float height = Mathf.Min(safe.height - margin * 2f, Mathf.Max(500f, 720f * scale));
            modalRect = new Rect(safe.center.x - width * 0.5f, safe.center.y - height * 0.5f, width, height);
            modalRect = CargoV2UiLayout.ClampToSafe(modalRect, safe);

            GUIStyle box = BoxStyle(scale);
            GUIStyle header = HeaderStyle(scale);
            GUIStyle label = LabelStyle(scale);
            GUIStyle button = ButtonStyle(scale);
            float buttonHeight = Mathf.Max(42f, 50f * scale);

            GUILayout.BeginArea(modalRect, box);
            GUILayout.Label(L("settings.title"), header, GUILayout.Height(buttonHeight));

            GUILayout.Label(L("settings.language"), label);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button(L("settings.english"), button, GUILayout.Height(buttonHeight)))
            {
                SetLanguage(SCR_LocalizationManager.Language.English);
            }
            if (GUILayout.Button(L("settings.arabic"), button, GUILayout.Height(buttonHeight)))
            {
                SetLanguage(SCR_LocalizationManager.Language.Arabic);
            }
            GUILayout.EndHorizontal();

            settings = CargoV2PlayerSettings.Load();
            DrawVolumeRow("settings.master", settings.MasterVolume, 0);
            DrawVolumeRow("settings.sfx", settings.SfxVolume, 1);
            DrawVolumeRow("settings.engine", settings.EngineVolume, 2);
            settings = CargoV2PlayerSettings.Load();
            DrawToggleRow("settings.mute", settings.Muted, value => SaveBool(0, value), scale);
            DrawToggleRow("settings.haptics", settings.Haptics, value => SaveBool(1, value), scale);
            DrawToggleRow("settings.reducedMotion", settings.ReducedMotion, value => SaveBool(2, value), scale);
            DrawToggleRow("settings.largeText", settings.LargeText, value => SaveBool(3, value), scale);

            if (!string.IsNullOrEmpty(status) && Time.unscaledTime <= statusUntil)
            {
                GUILayout.Label(status, label);
            }

            GUILayout.FlexibleSpace();
            GUILayout.BeginHorizontal();
            if (GUILayout.Button(L("settings.reset"), button, GUILayout.Height(buttonHeight)))
            {
                if (CargoV2PlayerSettings.ResetToDefaults())
                {
                    SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
                    SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
                    if (manager != null && manager.CurrentLanguage != SCR_LocalizationManager.Language.English)
                    {
                        manager.SetLanguage(SCR_LocalizationManager.Language.English);
                    }
                }
                else SetStatus(L("settings.saveFailed"));
            }
            if (GUILayout.Button(L("settings.close"), button, GUILayout.Height(buttonHeight))) CloseModal();
            GUILayout.EndHorizontal();
            GUILayout.EndArea();
        }

        private void DrawHelp(Rect safe, float scale)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float width = Mathf.Min(safe.width - margin * 2f, Mathf.Max(520f, 760f * scale));
            float height = Mathf.Min(safe.height - margin * 2f, Mathf.Max(420f, 610f * scale));
            modalRect = new Rect(safe.center.x - width * 0.5f, safe.center.y - height * 0.5f, width, height);
            modalRect = CargoV2UiLayout.ClampToSafe(modalRect, safe);

            GUIStyle box = BoxStyle(scale);
            GUIStyle header = HeaderStyle(scale);
            GUIStyle label = LabelStyle(scale);
            label.wordWrap = true;
            GUIStyle button = ButtonStyle(scale);
            float buttonHeight = Mathf.Max(44f, 52f * scale);

            GUILayout.BeginArea(modalRect, box);
            GUILayout.Label(L("help.title"), header, GUILayout.Height(buttonHeight));
            GUILayout.Label(L("help.worldMap"), label);
            GUILayout.Space(8f * scale);
            GUILayout.Label(L("help.drive"), label);
            GUILayout.Space(8f * scale);
            GUILayout.Label(L("help.route"), label);
            GUILayout.Space(8f * scale);
            GUILayout.Label(L("help.pause"), label);
            GUILayout.Space(8f * scale);
            GUILayout.Label(L("help.accessibility"), label);
            GUILayout.FlexibleSpace();
            if (GUILayout.Button(L("help.close"), button, GUILayout.Height(buttonHeight))) CloseModal();
            GUILayout.EndArea();
        }

        private void DrawVolumeRow(string key, float value, int channel)
        {
            CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
            float scale = CargoV2UiLayout.Scale(CargoV2UiLayout.SafeGuiRect, settings.LargeText);
            GUIStyle label = LabelStyle(scale);
            GUIStyle button = ButtonStyle(scale);
            float height = Mathf.Max(42f, 48f * scale);

            GUILayout.BeginHorizontal();
            GUILayout.Label($"{L(key)}  {Percent(value)}", label, GUILayout.ExpandWidth(true), GUILayout.Height(height));
            if (GUILayout.Button("−", button, GUILayout.Width(Mathf.Max(52f, 60f * scale)), GUILayout.Height(height)))
            {
                SaveVolume(channel, Mathf.Clamp01(value - 0.1f));
            }
            if (GUILayout.Button("+", button, GUILayout.Width(Mathf.Max(52f, 60f * scale)), GUILayout.Height(height)))
            {
                SaveVolume(channel, Mathf.Clamp01(value + 0.1f));
            }
            GUILayout.EndHorizontal();
        }

        private void DrawToggleRow(string key, bool value, System.Action<bool> setter, float scale)
        {
            GUIStyle label = LabelStyle(scale);
            GUIStyle button = ButtonStyle(scale);
            float height = Mathf.Max(42f, 48f * scale);
            GUILayout.BeginHorizontal();
            GUILayout.Label(L(key), label, GUILayout.ExpandWidth(true), GUILayout.Height(height));
            if (GUILayout.Button(L(value ? "settings.on" : "settings.off"), button,
                    GUILayout.Width(Mathf.Max(104f, 124f * scale)), GUILayout.Height(height)))
            {
                setter?.Invoke(!value);
            }
            GUILayout.EndHorizontal();
        }

        private void SaveVolume(int channel, float value)
        {
            bool saved;
            if (channel == 0) saved = CargoV2PlayerSettings.TryUpdate(masterVolume: value);
            else if (channel == 1) saved = CargoV2PlayerSettings.TryUpdate(sfxVolume: value);
            else saved = CargoV2PlayerSettings.TryUpdate(engineVolume: value);
            if (saved) SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
            else SetStatus(L("settings.saveFailed"));
        }

        private void SaveBool(int setting, bool value)
        {
            bool saved;
            if (setting == 0) saved = CargoV2PlayerSettings.TryUpdate(muted: value);
            else if (setting == 1) saved = CargoV2PlayerSettings.TryUpdate(haptics: value);
            else if (setting == 2) saved = CargoV2PlayerSettings.TryUpdate(reducedMotion: value);
            else saved = CargoV2PlayerSettings.TryUpdate(largeText: value);
            if (saved) SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
            else SetStatus(L("settings.saveFailed"));
        }

        private void SetLanguage(SCR_LocalizationManager.Language language)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            bool saved = manager != null
                ? manager.SetLanguage(language)
                : CargoV2PlayerSettings.TryUpdate(
                    language: language == SCR_LocalizationManager.Language.Arabic
                        ? CargoV2PlayerSettings.Language.Arabic
                        : CargoV2PlayerSettings.Language.English);
            if (saved) SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
            else SetStatus(L("settings.saveFailed"));
        }

        private void SetStatus(string message)
        {
            status = message ?? string.Empty;
            statusUntil = Time.unscaledTime + 4f;
            SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Error);
        }

        private static string L(string key)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.Get(key) : key;
        }

        private static string Percent(float value)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            string raw = Mathf.RoundToInt(Mathf.Clamp01(value) * 100f) + "%";
            return manager != null ? manager.LocalizeDigits(raw) : raw;
        }

        private static GUIStyle BoxStyle(float scale)
        {
            GUIStyle style = new GUIStyle(GUI.skin.box)
            {
                padding = new RectOffset(
                    Mathf.RoundToInt(18f * scale), Mathf.RoundToInt(18f * scale),
                    Mathf.RoundToInt(16f * scale), Mathf.RoundToInt(16f * scale)),
            };
            return style;
        }

        private static GUIStyle HeaderStyle(float scale)
        {
            return new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(27f * scale), 20, 42),
                fontStyle = FontStyle.Bold,
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
            };
        }

        private static GUIStyle LabelStyle(float scale)
        {
            bool rtl = SCR_LocalizationManager.Instance != null && SCR_LocalizationManager.Instance.IsRtl;
            return new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(20f * scale), 16, 32),
                alignment = rtl ? TextAnchor.MiddleRight : TextAnchor.MiddleLeft,
                wordWrap = true,
            };
        }

        private static GUIStyle ButtonStyle(float scale)
        {
            return new GUIStyle(GUI.skin.button)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(19f * scale), 16, 30),
                fontStyle = FontStyle.Bold,
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
            };
        }
    }
}
