using System;
using UnityEngine;

namespace CargoV2.Data
{
    /// <summary>
    /// Player-facing preferences only. This store is deliberately isolated from
    /// progression, economy, fleet and active-delivery persistence.
    /// </summary>
    public static class CargoV2PlayerSettings
    {
        public enum Language
        {
            English = 0,
            Arabic = 1,
        }

        public readonly struct Snapshot
        {
            public Snapshot(
                Language language,
                float masterVolume,
                float sfxVolume,
                float engineVolume,
                bool muted,
                bool haptics,
                bool reducedMotion,
                bool largeText)
            {
                Language = language;
                MasterVolume = masterVolume;
                SfxVolume = sfxVolume;
                EngineVolume = engineVolume;
                Muted = muted;
                Haptics = haptics;
                ReducedMotion = reducedMotion;
                LargeText = largeText;
            }

            public Language Language { get; }
            public float MasterVolume { get; }
            public float SfxVolume { get; }
            public float EngineVolume { get; }
            public bool Muted { get; }
            public bool Haptics { get; }
            public bool ReducedMotion { get; }
            public bool LargeText { get; }
        }

        [Serializable]
        private sealed class Payload
        {
            public int schemaVersion = SchemaVersion;
            public int language;
            public float masterVolume = DefaultMasterVolume;
            public float sfxVolume = DefaultSfxVolume;
            public float engineVolume = DefaultEngineVolume;
            public bool muted;
            public bool haptics = true;
            public bool reducedMotion;
            public bool largeText;
        }

        public const int SchemaVersion = 1;
        public const string SettingsKey = "cargo_v2_player_settings_v1";
        public const string CorruptBackupKey = "cargo_v2_player_settings_corrupt_v1";
        public const float DefaultMasterVolume = 0.85f;
        public const float DefaultSfxVolume = 0.90f;
        public const float DefaultEngineVolume = 0.72f;

        public static event Action<Snapshot> Changed;

        public static Snapshot Load()
        {
            if (!PlayerPrefs.HasKey(SettingsKey)) return Defaults;

            string raw = string.Empty;
            try
            {
                raw = PlayerPrefs.GetString(SettingsKey, string.Empty);
                Payload payload = string.IsNullOrWhiteSpace(raw) ? null : JsonUtility.FromJson<Payload>(raw);
                if (TryNormalize(payload, out Snapshot snapshot)) return snapshot;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][SETTINGS] Player settings parse failed safely: {exception.Message}");
            }

            Quarantine(raw);
            return Defaults;
        }

        public static bool TrySave(Snapshot snapshot)
        {
            if (!Validate(snapshot)) return false;

            try
            {
                Payload payload = new Payload
                {
                    schemaVersion = SchemaVersion,
                    language = (int)snapshot.Language,
                    masterVolume = snapshot.MasterVolume,
                    sfxVolume = snapshot.SfxVolume,
                    engineVolume = snapshot.EngineVolume,
                    muted = snapshot.Muted,
                    haptics = snapshot.Haptics,
                    reducedMotion = snapshot.ReducedMotion,
                    largeText = snapshot.LargeText,
                };

                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;
                PlayerPrefs.SetString(SettingsKey, json);
                PlayerPrefs.Save();
                Changed?.Invoke(snapshot);
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][SETTINGS] Player settings write failed safely: {exception.Message}");
                return false;
            }
        }

        public static bool TryUpdate(
            Language? language = null,
            float? masterVolume = null,
            float? sfxVolume = null,
            float? engineVolume = null,
            bool? muted = null,
            bool? haptics = null,
            bool? reducedMotion = null,
            bool? largeText = null)
        {
            Snapshot current = Load();
            Snapshot next = new Snapshot(
                language ?? current.Language,
                masterVolume ?? current.MasterVolume,
                sfxVolume ?? current.SfxVolume,
                engineVolume ?? current.EngineVolume,
                muted ?? current.Muted,
                haptics ?? current.Haptics,
                reducedMotion ?? current.ReducedMotion,
                largeText ?? current.LargeText);
            return TrySave(next);
        }

        public static bool ResetToDefaults()
        {
            try
            {
                PlayerPrefs.DeleteKey(SettingsKey);
                PlayerPrefs.Save();
                Changed?.Invoke(Defaults);
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][SETTINGS] Player settings reset failed safely: {exception.Message}");
                return false;
            }
        }

        public static Snapshot Defaults => new Snapshot(
            Language.English,
            DefaultMasterVolume,
            DefaultSfxVolume,
            DefaultEngineVolume,
            false,
            true,
            false,
            false);

        private static bool TryNormalize(Payload payload, out Snapshot snapshot)
        {
            snapshot = Defaults;
            if (payload == null || payload.schemaVersion != SchemaVersion) return false;
            if (payload.language < (int)Language.English || payload.language > (int)Language.Arabic) return false;
            if (!FiniteUnit(payload.masterVolume) || !FiniteUnit(payload.sfxVolume) || !FiniteUnit(payload.engineVolume)) return false;

            snapshot = new Snapshot(
                (Language)payload.language,
                payload.masterVolume,
                payload.sfxVolume,
                payload.engineVolume,
                payload.muted,
                payload.haptics,
                payload.reducedMotion,
                payload.largeText);
            return true;
        }

        private static bool Validate(Snapshot snapshot)
        {
            return (snapshot.Language == Language.English || snapshot.Language == Language.Arabic) &&
                   FiniteUnit(snapshot.MasterVolume) &&
                   FiniteUnit(snapshot.SfxVolume) &&
                   FiniteUnit(snapshot.EngineVolume);
        }

        private static bool FiniteUnit(float value)
        {
            return !float.IsNaN(value) && !float.IsInfinity(value) && value >= 0f && value <= 1f;
        }

        private static void Quarantine(string raw)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(raw)) PlayerPrefs.SetString(CorruptBackupKey, raw);
                PlayerPrefs.DeleteKey(SettingsKey);
                PlayerPrefs.Save();
                Debug.LogWarning("[CARGO V2][SETTINGS] Invalid player settings were quarantined; safe defaults are active.");
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][SETTINGS] Settings quarantine failed safely: {exception.Message}");
            }
        }
    }
}
