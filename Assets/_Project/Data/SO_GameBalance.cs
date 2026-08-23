using System;
using System.Collections.Generic;
using UnityEngine;

namespace CargoV2.Data
{
    [CreateAssetMenu(fileName = "SO_GameBalance", menuName = "CARGO V2/Game Balance", order = 1)]
    public sealed class SO_GameBalance : ScriptableObject
    {
        [Serializable]
        public sealed class MissionBalance
        {
            public int missionId;
            public string city;
            public int cityIndex;
            public int energyCost;
            public int timeSeconds;
            public int coin1Star;
            public int coin3Star;
            public int xp;
        }

        [Serializable]
        public sealed class StoreProductBalance
        {
            public string id;
            public string label;
            public long coins;
            public double usd;
            public bool oneTime;
        }

        [Serializable]
        public sealed class SlotTierBalance
        {
            public string id;
            public int multiplier;
            public int costCoins;
            [Range(0f, 1f)] public float rtp;
            public int bigWinMin;
            public int bigWinMax;
        }

        public const int DefaultEnergyCost = 1;

        [Header("Missions")]
        public List<MissionBalance> missions = new List<MissionBalance>();

        [Header("Store")]
        public List<StoreProductBalance> storeProducts = new List<StoreProductBalance>();

        [Header("Slots")]
        public List<SlotTierBalance> slotTiers = new List<SlotTierBalance>();

        private static readonly int[] Times = { 30, 35, 40, 45, 50, 55, 60, 65, 70, 75 };
        private static readonly int[] Coin1Star = { 300, 350, 400, 450, 500, 550, 600, 650, 700, 750 };
        private static readonly int[] Coin3Star = { 500, 600, 700, 800, 900, 1000, 1200, 1400, 1600, 2000 };
        private static readonly int[] Xp = { 20, 25, 30, 35, 40, 45, 50, 55, 60, 70 };

        private void OnEnable()
        {
            if (missions == null || missions.Count != 20 || storeProducts == null || storeProducts.Count == 0 || slotTiers == null || slotTiers.Count != 3)
            {
                ResetToApprovedDefaults();
            }
        }

        [ContextMenu("Reset To CARGO V2 Approved Defaults")]
        public void ResetToApprovedDefaults()
        {
            missions = new List<MissionBalance>(20);
            AddCityMissions("Cairo", 1, 1);
            AddCityMissions("Dubai", 11, 11);

            storeProducts = new List<StoreProductBalance>
            {
                Product("coins_100k", "100K Coins", 100000, 1.99, false),
                Product("coins_500k", "500K Coins", 500000, 4.99, false),
                Product("coins_2m", "2M Coins", 2000000, 9.99, false),
                Product("coins_10m", "10M Coins", 10000000, 39.99, false),
                Product("hearts", "Hearts", 0, 2.99, false),
                Product("remove_ads", "Remove Ads", 0, 4.99, false),
                Product("starter", "Starter Pack - 1M Coins", 1000000, 0.99, true),
            };

            slotTiers = new List<SlotTierBalance>
            {
                Slot("x20", 20, 200, 0.94f, 10000, 100000),
                Slot("x50", 50, 500, 0.95f, 25000, 500000),
                Slot("x100", 100, 1000, 0.96f, 50000, 1000000),
            };
        }

        public MissionBalance GetMission(int missionId)
        {
            if (missions == null) return null;
            for (int i = 0; i < missions.Count; i++)
            {
                if (missions[i].missionId == missionId) return missions[i];
            }
            return null;
        }

        private void AddCityMissions(string city, int firstMissionId, int firstCityIndex)
        {
            for (int i = 0; i < 10; i++)
            {
                missions.Add(new MissionBalance
                {
                    missionId = firstMissionId + i,
                    city = city,
                    cityIndex = firstCityIndex + i,
                    energyCost = DefaultEnergyCost,
                    timeSeconds = Times[i],
                    coin1Star = Coin1Star[i],
                    coin3Star = Coin3Star[i],
                    xp = Xp[i],
                });
            }
        }

        private static StoreProductBalance Product(string id, string label, long coins, double usd, bool oneTime)
        {
            return new StoreProductBalance { id = id, label = label, coins = coins, usd = usd, oneTime = oneTime };
        }

        private static SlotTierBalance Slot(string id, int multiplier, int costCoins, float rtp, int bigWinMin, int bigWinMax)
        {
            return new SlotTierBalance
            {
                id = id,
                multiplier = multiplier,
                costCoins = costCoins,
                rtp = rtp,
                bigWinMin = bigWinMin,
                bigWinMax = bigWinMax,
            };
        }
    }
}
