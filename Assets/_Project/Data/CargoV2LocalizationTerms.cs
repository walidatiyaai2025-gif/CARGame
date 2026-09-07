using System;
using System.Collections.Generic;

namespace CargoV2.Data
{
    public static class CargoV2LocalizationTerms
    {
        private static readonly Dictionary<string, string> ArabicTerms = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            { "Cairo", "القاهرة" },
            { "Dubai", "دبي" },
            { "Cairo Logistics Hub", "مركز القاهرة اللوجستي" },
            { "Giza Distribution Yard", "ساحة توزيع الجيزة" },
            { "Nasr City Freight Hub", "مركز شحن مدينة نصر" },
            { "New Cairo Logistics Park", "مجمع القاهرة الجديدة اللوجستي" },
            { "Cairo Airport Cargo", "شحن مطار القاهرة" },
            { "Helwan Industrial Depot", "مستودع حلوان الصناعي" },
            { "6th October Warehouse", "مستودع السادس من أكتوبر" },
            { "Obour Food Terminal", "محطة العبور الغذائية" },
            { "Ain Sokhna Connector", "وصلة العين السخنة" },
            { "Alexandria Inland Link", "وصلة الإسكندرية الداخلية" },
            { "Cairo International Depot", "مستودع القاهرة الدولي" },
            { "Dubai Logistics Hub", "مركز دبي اللوجستي" },
            { "Jebel Ali Container Yard", "ساحة حاويات جبل علي" },
            { "Dubai South Logistics District", "منطقة دبي الجنوب اللوجستية" },
            { "Al Quoz Freight Terminal", "محطة شحن القوز" },
            { "DXB Cargo Village", "قرية الشحن بمطار دبي" },
            { "Ras Al Khor Depot", "مستودع رأس الخور" },
            { "Dubai Industrial City", "مدينة دبي الصناعية" },
            { "Port Rashid Connector", "وصلة ميناء راشد" },
            { "Dubai Investment Park", "مجمع دبي للاستثمار" },
            { "JAFZA Heavy Cargo Gate", "بوابة الشحن الثقيل بجافزا" },
            { "Gulf International Depot", "مستودع الخليج الدولي" },
            { "General Freight", "شحن عام" },
            { "Fresh Produce", "منتجات طازجة" },
            { "Electronics", "إلكترونيات" },
            { "Industrial Machinery", "معدات صناعية" },
            { "Medical Supplies", "مستلزمات طبية" },
            { "Blue Container", "حاوية زرقاء" },
        };

        public static string Term(string value)
        {
            if (string.IsNullOrEmpty(value)) return string.Empty;
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            if (manager == null || !manager.IsRtl) return value;
            return ArabicTerms.TryGetValue(value, out string localized) ? localized : value;
        }

        public static string LogisticsLabel(string key)
        {
            bool rtl = SCR_LocalizationManager.Instance != null && SCR_LocalizationManager.Instance.IsRtl;
            switch (key)
            {
                case "hq.speed": return rtl ? "السرعة" : "Speed";
                case "hq.capacity": return rtl ? "السعة" : "Capacity";
                case "hq.durability": return rtl ? "المتانة" : "Durability";
                case "hq.engine": return rtl ? "المحرك" : "Engine";
                case "hq.handling": return rtl ? "التحكم" : "Handling";
                case "hq.purchased": return rtl ? "أضيفت للأسطول" : "added to fleet";
                case "hq.coins": return rtl ? "عملة" : "coins";
                case "hq.upgraded": return rtl ? "تمت ترقيته" : "upgraded";
                case "hq.bonus": return rtl ? "إضافي" : "bonus";
                case "hq.resumed": return rtl ? "تم استكمال التوصيل" : "Delivery resumed";
                case "splash.network": return rtl ? "شبكة شحن عالمية مميزة" : "PREMIUM GLOBAL CARGO NETWORK";
                case "splash.motto": return rtl ? "سلّم • توسع • تقدّم" : "DELIVER  ·  EXPAND  ·  DOMINATE";
                case "loading.route": return rtl ? "جاري تجهيز مسارك العالمي" : "PREPARING YOUR WORLD ROUTE";
                case "loading.retrying": return rtl ? "تعذر فتح المرحلة التالية • إعادة المحاولة…" : "NEXT STAGE UNAVAILABLE • RETRYING…";
                default: return key;
            }
        }
    }
}
