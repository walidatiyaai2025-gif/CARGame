using System;
using System.Collections.Generic;
using System.Globalization;
using UnityEngine;

namespace CargoV2.Data
{
    public sealed class SCR_LocalizationManager : MonoBehaviour
    {
        public enum Language
        {
            English = 0,
            Arabic = 1,
        }

        public static SCR_LocalizationManager Instance { get; private set; }
        public Language CurrentLanguage { get; private set; } = Language.English;
        public bool IsRtl => CurrentLanguage == Language.Arabic;
        public event Action<Language> LanguageChanged;

        private static bool sceneHookRegistered;

        private static readonly Dictionary<string, string> English = new Dictionary<string, string>(StringComparer.Ordinal)
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

            { "state.selected", "SELECTED" },
            { "state.completed", "DONE • COMPLETED" },
            { "state.available", "READY • AVAILABLE" },
            { "state.locked", "LOCKED" },
            { "world.energy", "ENERGY" },
            { "world.time", "TIME" },
            { "world.star1", "1 STAR" },
            { "world.star3", "3 STAR" },
            { "world.dataUnavailable", "MISSION DATA UNAVAILABLE" },

            { "deploy.action", "DEPLOY MISSION {0}" },
            { "deploy.active", "MISSION ACTIVE" },
            { "deploy.locked", "MISSION LOCKED" },
            { "deploy.lockedPrevious", "LOCKED — COMPLETE PREVIOUS MISSION" },
            { "deploy.starting", "DEPLOYING MISSION {0}…" },
            { "deploy.failed", "DEPLOY FAILED — TRY AGAIN" },
            { "deploy.startFailed", "MISSION START FAILED — TRY AGAIN" },
            { "deploy.alreadyActive", "MISSION ALREADY ACTIVE" },

            { "hud.contract", "CARGO V2 — CONTRACT {0}" },
            { "hud.damage", "Damage" },
            { "hud.time", "Time" },
            { "hud.cargoLoaded", "Cargo loaded • checkpoint {0}/3 • then delivery" },
            { "hud.pickup", "Drive into the cyan PICKUP zone" },
            { "hud.overCapacity", "OVER CAPACITY: {0} t / {1} t • reduced performance" },
            { "hud.pause", "PAUSE" },
            { "hud.paused", "PAUSED" },
            { "hud.resume", "RESUME" },
            { "hud.recover", "RECOVER" },
            { "hud.throttle", "THROTTLE" },
            { "hud.brakeReverse", "BRAKE / REV" },
            { "hud.abandon", "ABANDON CONTRACT" },
            { "hud.complete", "DELIVERY COMPLETE" },
            { "hud.failed", "DELIVERY FAILED" },
            { "hud.retry", "RETRY" },
            { "hud.worldMap", "BACK TO WORLD MAP" },
            { "hud.reward", "Reward: {0} coins • {1} XP" },
            { "hud.expired", "CONTRACT TIME EXPIRED" },
            { "hud.truckDisabled", "TRUCK DISABLED" },

            { "hq.title", "LOGISTICS HQ" },
            { "hq.companyRank", "Company Rank {0} • {1} coins • {2} XP" },
            { "hq.economyUnavailable", "Economy unavailable — retry after returning to the World Map" },
            { "hq.contract", "CONTRACT {0}" },
            { "hq.capacityOk", "Selected: {0} • capacity OK" },
            { "hq.underCapacity", "Selected truck is under-capacity • deployment remains available with reduced speed and acceleration" },
            { "hq.resumeDelivery", "RESUME DELIVERY {0}" },
            { "hq.resumeFailed", "Delivery could not resume safely" },
            { "hq.fleet", "FLEET" },
            { "hq.selected", "SELECTED" },
            { "hq.select", "SELECT" },
            { "hq.buy", "BUY" },
            { "hq.unlockBuy", "Unlock {0} XP • Buy {1} coins" },
            { "hq.upgrades", "UPGRADES — {0}" },
            { "hq.max", "MAX" },
            { "hq.requiresCoins", "Requires {0} coins" },

            { "settings.title", "SETTINGS" },
            { "settings.language", "LANGUAGE" },
            { "settings.english", "ENGLISH" },
            { "settings.arabic", "ARABIC" },
            { "settings.master", "MASTER VOLUME" },
            { "settings.sfx", "SFX VOLUME" },
            { "settings.engine", "ENGINE VOLUME" },
            { "settings.mute", "MUTE" },
            { "settings.haptics", "HAPTICS" },
            { "settings.reducedMotion", "REDUCED MOTION" },
            { "settings.largeText", "LARGE TEXT" },
            { "settings.on", "ON" },
            { "settings.off", "OFF" },
            { "settings.close", "CLOSE" },
            { "settings.reset", "RESET SETTINGS" },
            { "settings.saveFailed", "Settings could not be saved. Previous settings remain active." },
            { "help.title", "DRIVER HELP" },
            { "help.worldMap", "World Map: select an AVAILABLE or COMPLETED mission, review requirements and rewards, then DEPLOY." },
            { "help.drive", "Drive: left/right steering, throttle, brake/reverse. RECOVER returns the truck to the last valid route checkpoint with a time/damage penalty." },
            { "help.route", "Route: PICKUP first, then checkpoints 1 → 2 → 3 in order, then enter the delivery zone." },
            { "help.pause", "Android Back pauses an active contract. From a result screen it returns to the World Map." },
            { "help.accessibility", "Reduced Motion steadies presentation and camera movement. Large Text enlarges HUD and menu text." },
            { "help.close", "GOT IT" },
        };

        private static readonly Dictionary<string, string> Arabic = new Dictionary<string, string>(StringComparer.Ordinal)
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

            { "state.selected", "محدد" },
            { "state.completed", "تم • مكتملة" },
            { "state.available", "جاهزة • متاحة" },
            { "state.locked", "مقفلة" },
            { "world.energy", "الطاقة" },
            { "world.time", "الوقت" },
            { "world.star1", "نجمة ١" },
            { "world.star3", "٣ نجوم" },
            { "world.dataUnavailable", "بيانات المهمة غير متاحة" },

            { "deploy.action", "ابدأ المهمة {0}" },
            { "deploy.active", "المهمة جارية" },
            { "deploy.locked", "المهمة مقفلة" },
            { "deploy.lockedPrevious", "مقفلة — أكمل المهمة السابقة" },
            { "deploy.starting", "جاري بدء المهمة {0}…" },
            { "deploy.failed", "تعذر بدء المهمة — حاول مجددًا" },
            { "deploy.startFailed", "فشل تشغيل المهمة — حاول مجددًا" },
            { "deploy.alreadyActive", "هناك مهمة جارية بالفعل" },

            { "hud.contract", "كارجو V2 — عقد {0}" },
            { "hud.damage", "الضرر" },
            { "hud.time", "الوقت" },
            { "hud.cargoLoaded", "تم تحميل الشحنة • نقطة {0}/٣ • ثم التسليم" },
            { "hud.pickup", "ادخل منطقة الاستلام السماوية لتحميل الشحنة" },
            { "hud.overCapacity", "حمولة زائدة: {0} طن / {1} طن • أداء أقل" },
            { "hud.pause", "إيقاف" },
            { "hud.paused", "متوقف مؤقتًا" },
            { "hud.resume", "متابعة" },
            { "hud.recover", "استعادة" },
            { "hud.throttle", "تسارع" },
            { "hud.brakeReverse", "فرامل / رجوع" },
            { "hud.abandon", "إلغاء العقد" },
            { "hud.complete", "تم التسليم" },
            { "hud.failed", "فشل التسليم" },
            { "hud.retry", "إعادة المحاولة" },
            { "hud.worldMap", "العودة للخريطة" },
            { "hud.reward", "المكافأة: {0} عملة • {1} XP" },
            { "hud.expired", "انتهى وقت العقد" },
            { "hud.truckDisabled", "الشاحنة متعطلة" },

            { "hq.title", "مقر الخدمات اللوجستية" },
            { "hq.companyRank", "تصنيف الشركة {0} • {1} عملة • {2} XP" },
            { "hq.economyUnavailable", "بيانات الرصيد غير متاحة — أعد المحاولة من الخريطة" },
            { "hq.contract", "عقد {0}" },
            { "hq.capacityOk", "المحدد: {0} • السعة مناسبة" },
            { "hq.underCapacity", "سعة الشاحنة أقل من المطلوب • يمكن البدء لكن بسرعة وتسارع أقل" },
            { "hq.resumeDelivery", "استكمال التوصيل {0}" },
            { "hq.resumeFailed", "تعذر استكمال التوصيل بأمان" },
            { "hq.fleet", "الأسطول" },
            { "hq.selected", "محدد" },
            { "hq.select", "اختيار" },
            { "hq.buy", "شراء" },
            { "hq.unlockBuy", "يتطلب {0} XP • السعر {1} عملة" },
            { "hq.upgrades", "ترقيات — {0}" },
            { "hq.max", "الحد الأقصى" },
            { "hq.requiresCoins", "يتطلب {0} عملة" },

            { "settings.title", "الإعدادات" },
            { "settings.language", "اللغة" },
            { "settings.english", "الإنجليزية" },
            { "settings.arabic", "العربية" },
            { "settings.master", "الصوت العام" },
            { "settings.sfx", "المؤثرات الصوتية" },
            { "settings.engine", "صوت المحرك" },
            { "settings.mute", "كتم الصوت" },
            { "settings.haptics", "الاهتزاز" },
            { "settings.reducedMotion", "تقليل الحركة" },
            { "settings.largeText", "نص كبير" },
            { "settings.on", "تشغيل" },
            { "settings.off", "إيقاف" },
            { "settings.close", "إغلاق" },
            { "settings.reset", "إعادة ضبط الإعدادات" },
            { "settings.saveFailed", "تعذر حفظ الإعدادات. ستبقى الإعدادات السابقة فعالة." },
            { "help.title", "مساعدة السائق" },
            { "help.worldMap", "الخريطة: اختر مهمة متاحة أو مكتملة، راجع المتطلبات والمكافآت، ثم ابدأ المهمة." },
            { "help.drive", "القيادة: يمين/يسار، تسارع، فرامل/رجوع. زر الاستعادة يعيد الشاحنة لآخر نقطة صالحة مع خصم وقت وزيادة ضرر." },
            { "help.route", "المسار: استلم الشحنة أولًا، ثم نقاط ١ ← ٢ ← ٣ بالترتيب، ثم ادخل منطقة التسليم." },
            { "help.pause", "زر الرجوع في أندرويد يوقف العقد مؤقتًا. في شاشة النتيجة يعيدك للخريطة." },
            { "help.accessibility", "تقليل الحركة يهدئ العرض وحركة الكاميرا. النص الكبير يكبر نصوص الواجهة." },
            { "help.close", "حسنًا" },
        };

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        private static void RegisterSceneHook()
        {
            if (sceneHookRegistered) return;
            sceneHookRegistered = true;
            EnsureInstance();
        }

        private static void EnsureInstance()
        {
            if (Instance != null) return;
            new GameObject("CARGO_V2_Localization").AddComponent<SCR_LocalizationManager>();
        }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
            CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
            CurrentLanguage = settings.Language == CargoV2PlayerSettings.Language.Arabic
                ? Language.Arabic
                : Language.English;
        }

        private void OnDestroy()
        {
            if (Instance == this) Instance = null;
        }

        public bool SetLanguage(Language language)
        {
            if (language != Language.English && language != Language.Arabic) return false;
            if (CurrentLanguage == language) return true;

            CargoV2PlayerSettings.Language stored = language == Language.Arabic
                ? CargoV2PlayerSettings.Language.Arabic
                : CargoV2PlayerSettings.Language.English;
            if (!CargoV2PlayerSettings.TryUpdate(language: stored)) return false;

            CurrentLanguage = language;
            LanguageChanged?.Invoke(language);
            return true;
        }

        public string Get(string key)
        {
            if (string.IsNullOrWhiteSpace(key)) return string.Empty;
            Dictionary<string, string> table = IsRtl ? Arabic : English;
            if (table.TryGetValue(key, out string value)) return value;
            return English.TryGetValue(key, out value) ? value : key;
        }

        public string Format(string key, params object[] args)
        {
            string format = Get(key);
            string value;
            try
            {
                value = string.Format(CultureInfo.InvariantCulture, format, args ?? Array.Empty<object>());
            }
            catch (FormatException)
            {
                value = format;
            }
            return LocalizeDigits(value);
        }

        public string FormatInteger(long value)
        {
            return LocalizeDigits(value.ToString("N0", CultureInfo.InvariantCulture));
        }

        public string FormatDecimal(float value, string format = "0.0")
        {
            if (float.IsNaN(value) || float.IsInfinity(value)) value = 0f;
            return LocalizeDigits(value.ToString(format, CultureInfo.InvariantCulture));
        }

        public string LocalizeDigits(string value)
        {
            if (!IsRtl || string.IsNullOrEmpty(value)) return value ?? string.Empty;

            char[] chars = value.ToCharArray();
            for (int i = 0; i < chars.Length; i++)
            {
                if (chars[i] >= '0' && chars[i] <= '9') chars[i] = (char)('٠' + (chars[i] - '0'));
                else if (chars[i] == '.') chars[i] = '٫';
            }
            return new string(chars);
        }

        public bool HasCompletePair(string key)
        {
            return !string.IsNullOrWhiteSpace(key) && English.ContainsKey(key) && Arabic.ContainsKey(key);
        }
    }
}
