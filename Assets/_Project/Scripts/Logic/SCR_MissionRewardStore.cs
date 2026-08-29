using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_MissionRewardStore
    {
        private const string EconomyKey = "cargo_v2_mission_economy_v1";
        private const int SchemaVersion = 1;
        private const int MaxSettledDeliveryIds = 256;

        [Serializable]
        private sealed class EconomyPayload
        {
            public int schemaVersion = SchemaVersion;
            public long coins;
            public long xp;
            public List<int> rewardedMissionIds = new List<int>();
            public List<string> settledDeliveryIds = new List<string>();
        }

        public readonly struct Snapshot
        {
            public Snapshot(long coins, long xp)
            {
                Coins = coins;
                Xp = xp;
            }

            public long Coins { get; }
            public long Xp { get; }
        }

        // Legacy one-time mission settlement retained for migration/older handoffs.
        public static bool TrySettleMission(
            SO_GameBalance.MissionBalance mission,
            out bool granted,
            out Snapshot snapshot)
        {
            return TrySettleMission(mission, 1, out granted, out snapshot);
        }

        public static bool TrySettleMission(
            SO_GameBalance.MissionBalance mission,
            int stars,
            out bool granted,
            out Snapshot snapshot)
        {
            granted = false;
            snapshot = new Snapshot(0, 0);
            if (!ValidMission(mission) || !TryLoad(out EconomyPayload payload)) return false;

            if (payload.rewardedMissionIds.Contains(mission.missionId))
            {
                snapshot = new Snapshot(payload.coins, payload.xp);
                return true;
            }

            if (!ApplyReward(payload, mission, stars)) return false;
            payload.rewardedMissionIds.Add(mission.missionId);
            payload.rewardedMissionIds.Sort();
            if (!TrySave(payload)) return false;

            granted = true;
            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        // Current trucking settlement. A contract can be replayed, but a specific
        // delivery run id is paid at most once. This gives the logistics economy a
        // renewable income loop without turning crash/retry handoffs into double-grants.
        public static bool TrySettleDelivery(
            SO_GameBalance.MissionBalance mission,
            int stars,
            string deliveryRunId,
            out bool granted,
            out Snapshot snapshot)
        {
            granted = false;
            snapshot = new Snapshot(0, 0);
            if (!ValidMission(mission) || !ValidDeliveryRunId(deliveryRunId) ||
                !TryLoad(out EconomyPayload payload))
            {
                return false;
            }

            if (payload.settledDeliveryIds.Contains(deliveryRunId))
            {
                snapshot = new Snapshot(payload.coins, payload.xp);
                return true;
            }

            if (!ApplyReward(payload, mission, stars)) return false;
            payload.settledDeliveryIds.Add(deliveryRunId);
            if (payload.settledDeliveryIds.Count > MaxSettledDeliveryIds)
            {
                payload.settledDeliveryIds.RemoveRange(0, payload.settledDeliveryIds.Count - MaxSettledDeliveryIds);
            }

            if (!TrySave(payload)) return false;
            granted = true;
            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        public static long GetCoinReward(SO_GameBalance.MissionBalance mission, int stars)
        {
            if (mission == null) return 0;
            if (stars >= 3) return Math.Max(0, mission.coin3Star);
            if (stars == 2)
            {
                long low = Math.Max(0, mission.coin1Star);
                long high = Math.Max(low, mission.coin3Star);
                return low + ((high - low) / 2L);
            }
            return Math.Max(0, mission.coin1Star);
        }

        public static bool TrySpendCoins(long amount, out Snapshot snapshot)
        {
            snapshot = new Snapshot(0, 0);
            if (amount < 0 || !TryLoad(out EconomyPayload payload)) return false;
            if (payload.coins < amount)
            {
                snapshot = new Snapshot(payload.coins, payload.xp);
                return false;
            }

            payload.coins -= amount;
            if (!TrySave(payload)) return false;
            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        public static bool TryCreditCoins(long amount, out Snapshot snapshot)
        {
            snapshot = new Snapshot(0, 0);
            if (amount < 0 || !TryLoad(out EconomyPayload payload)) return false;
            try
            {
                checked { payload.coins += amount; }
            }
            catch (OverflowException)
            {
                return false;
            }

            if (!TrySave(payload)) return false;
            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        public static bool TryReadSnapshot(out Snapshot snapshot)
        {
            snapshot = new Snapshot(0, 0);
            if (!TryLoad(out EconomyPayload payload)) return false;
            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        private static bool ApplyReward(EconomyPayload payload, SO_GameBalance.MissionBalance mission, int stars)
        {
            long coinReward = GetCoinReward(mission, stars);
            try
            {
                checked
                {
                    payload.coins += coinReward;
                    payload.xp += mission.xp;
                }
            }
            catch (OverflowException)
            {
                return false;
            }
            return true;
        }

        private static bool ValidMission(SO_GameBalance.MissionBalance mission)
        {
            return mission != null && mission.missionId >= 1 && mission.missionId <= 20 &&
                   mission.coin1Star >= 0 && mission.coin3Star >= 0 && mission.xp >= 0;
        }

        private static bool ValidDeliveryRunId(string deliveryRunId)
        {
            return !string.IsNullOrWhiteSpace(deliveryRunId) &&
                   Guid.TryParseExact(deliveryRunId, "N", out _);
        }

        private static bool TryLoad(out EconomyPayload payload)
        {
            payload = null;
            try
            {
                if (!PlayerPrefs.HasKey(EconomyKey))
                {
                    payload = NewPayload();
                    return true;
                }

                string json = PlayerPrefs.GetString(EconomyKey, string.Empty);
                if (string.IsNullOrWhiteSpace(json)) return false;
                payload = JsonUtility.FromJson<EconomyPayload>(json);
                if (payload == null || payload.schemaVersion != SchemaVersion || payload.coins < 0 || payload.xp < 0)
                {
                    payload = null;
                    return false;
                }

                if (payload.rewardedMissionIds == null) payload.rewardedMissionIds = new List<int>();
                if (payload.settledDeliveryIds == null) payload.settledDeliveryIds = new List<string>();

                var missionIds = new HashSet<int>();
                for (int i = 0; i < payload.rewardedMissionIds.Count; i++)
                {
                    int missionId = payload.rewardedMissionIds[i];
                    if (missionId < 1 || missionId > 20 || !missionIds.Add(missionId))
                    {
                        payload = null;
                        return false;
                    }
                }

                var deliveryIds = new HashSet<string>(StringComparer.Ordinal);
                for (int i = 0; i < payload.settledDeliveryIds.Count; i++)
                {
                    string deliveryId = payload.settledDeliveryIds[i];
                    if (!ValidDeliveryRunId(deliveryId) || !deliveryIds.Add(deliveryId))
                    {
                        payload = null;
                        return false;
                    }
                }
                if (payload.settledDeliveryIds.Count > MaxSettledDeliveryIds)
                {
                    payload = null;
                    return false;
                }

                payload.rewardedMissionIds.Sort();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Economy payload read failed safely: {exception.Message}");
                payload = null;
                return false;
            }
        }

        private static bool TrySave(EconomyPayload payload)
        {
            try
            {
                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;
                PlayerPrefs.SetString(EconomyKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Economy payload write failed safely: {exception.Message}");
                return false;
            }
        }

        private static EconomyPayload NewPayload()
        {
            return new EconomyPayload
            {
                schemaVersion = SchemaVersion,
                coins = 0,
                xp = 0,
                rewardedMissionIds = new List<int>(),
                settledDeliveryIds = new List<string>(),
            };
        }
    }
}
