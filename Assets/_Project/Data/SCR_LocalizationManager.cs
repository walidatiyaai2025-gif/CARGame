using System;
using System.Collections.Generic;
using UnityEngine;

namespace CargoV2.Data
{
    public sealed class SCR_LocalizationManager : MonoBehaviour
    {
        public enum Language
        {
            English,
            Arabic,
        }

        public static SCR_LocalizationManager Instance { get; private set; }
        public Language CurrentLanguage { get; private set; } = Language.English;
        public bool IsRtl => CurrentLanguage == Language.Arabic;
        public event Action<Language> LanguageChanged;

        private static readonly Dictionary<string, string> English = new Dictionary<string, string>
        {
            { "app.title", "CARGO V2" },
            { "loading", "Loading" },
            { "continue", "Continue" },
            { "skip", "Skip" },
            { "mission", "Mission" },
            { "reward", "Reward" },
            { "slots", "Slots" },
            { "store", "Store" },
            { "profile", "Profile" },
            { "onboarding.1", "Deliver cargo across the world" },
            { "onboarding.2", "Complete missions and earn rewards" },
            { "onboarding.3", "Unlock cities, cards and tournaments" },
        };

        private static readonly Dictionary<string, string> Arabic = new Dictionary<string, string>
        {
            { "app.title", "كارجو V2" },
            { "loading", "جاري التحميل" },
            { "continue", "متابعة" },
            { "skip", "تخطي" },
            { "mission", "مهمة" },
            { "reward", "مكافأة" },
            { "slots", "سلوتس" },
            { "store", "المتجر" },
            { "profile", "الملف الشخصي" },
            { "onboarding.1", "انقل الشحنات حول العالم" },
            { "onboarding.2", "أكمل المهام واحصل على المكافآت" },
            { "onboarding.3", "افتح المدن والبطاقات والبطولات" },
        };

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        public void SetLanguage(Language language)
        {
            if (CurrentLanguage == language) return;
            CurrentLanguage = language;
            LanguageChanged?.Invoke(language);
        }

        public string Get(string key)
        {
            Dictionary<string, string> table = IsRtl ? Arabic : English;
            return table.TryGetValue(key, out string value) ? value : key;
        }
    }
}
