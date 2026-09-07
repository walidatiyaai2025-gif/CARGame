using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_MissionRewardStore
    {
        public const string EconomyKey = "cargo_v2_mission_economy_v1";
        public const string EconomyBackupKey = "cargo_v2_mission_economy_v1.lkg";
        public const string CorruptBackupKey = "cargo_v2_mission_economy_v1.corrupt";
        public const string UnsupportedBackupKey = "cargo_v2_mission_economy_v1.unsupported";
        private const int SchemaVersion = 1;
        private const int MaxSettledDeliveryIds = 4096;
        private const int MaxSpendReceipts = 128;

        [Serializable]
        private sealed class SchemaProbe
        {
            public int schemaVersion;
        }

        [Serializable]
        private sealed class SpendReceiptPayload
        {
            public string operationId;
            public long amount;
        }

        [Serializable]
        private sealed class EconomyPayload
        {
            public int schemaVersion = SchemaVersion;
            public long coins;
            public long xp;
            public List<int> rewardedMissionIds = new List<int>();
            public List<string> settledDeliveryIds = new List<string>();
            public List<SpendReceiptPayload> spendReceipts = new List<SpendReceiptPayload>();
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
        // delivery run id is paid at most once. Once the durable id ledger reaches
        // its defensive bound, settlement fails closed rather than evicting old ids
        // and making an ancient crash handoff payable again.
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

            if (payload.settledDeliveryIds.Count >= MaxSettledDeliveryIds) return false;
            if (!ApplyReward(payload, mission, stars)) return false;
            payload.settledDeliveryIds.Add(deliveryRunId);

            // Once a modern delivery has paid this mission, also seal the legacy
            // one-time ledger entry. This prevents an old no-run-id handoff from
            // paying the same completion again after migration, while modern replay
            // remains repeatable through unique deliveryRunId values.
            if (!payload.rewardedMissionIds.Contains(mission.missionId))
            {
                payload.rewardedMissionIds.Add(mission.missionId);
                payload.rewardedMissionIds.Sort();
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

        public static bool TryReadSpendCommit(
            long amount,
            string operationId,
            out bool committed,
            out Snapshot snapshot)
        {
            committed = false;
            snapshot = new Snapshot(0, 0);
            if (amount <= 0 || !ValidOperationId(operationId) || !TryLoad(out EconomyPayload payload)) return false;

            SpendReceiptPayload receipt = FindSpendReceipt(payload, operationId);
            if (receipt != null)
            {
                if (receipt.amount != amount) return false;
                committed = true;
            }

            snapshot = new Snapshot(payload.coins, payload.xp);
            return true;
        }

        // Crash-safe company transactions use a stable operation id. Replaying the
        // same id after a process interruption observes the persisted receipt and
        // never charges the same purchase/upgrade twice.
        public static bool TryEnsureCoinSpend(
            long amount,
            string operationId,
            out bool committed,
            out Snapshot snapshot)
        {
            committed = false;
            snapshot = new Snapshot(0, 0);
            if (amount <= 0 || !ValidOperationId(operationId) || !TryLoad(out EconomyPayload payload))
            {
                return false;
            }

            SpendReceiptPayload receipt = FindSpendReceipt(payload, operationId);
            if (receipt != null)
            {
                if (receipt.amount != amount) return false;
                committed = true;
                snapshot = new Snapshot(payload.coins, payload.xp);
                return true;
            }

            if (payload.coins < amount)
            {
                snapshot = new Snapshot(payload.coins, payload.xp);
                return true;
            }

            // Canonical fleet has far fewer than 128 possible purchase/upgrade
            // operations. Never evict an idempotency receipt merely to make room.
            if (payload.spendReceipts.Count >= MaxSpendReceipts) return false;

            payload.coins -= amount;
            payload.spendReceipts.Add(new SpendReceiptPayload
            {
                operationId = operationId,
                amount = amount,
            });

            if (!TrySave(payload)) return false;
            committed = true;
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
                   mission.coin1Star >= 0 && mission.coin3Star >= mission.coin1Star && mission.xp >= 0;
        }

        private static bool ValidDeliveryRunId(string deliveryRunId)
        {
            return !string.IsNullOrWhiteSpace(deliveryRunId) &&
                   Guid.TryParseExact(deliveryRunId, "N", out _);
        }

        private static bool ValidOperationId(string operationId)
        {
            return !string.IsNullOrWhiteSpace(operationId) &&
                   Guid.TryParseExact(operationId, "N", out _);
        }

        private static SpendReceiptPayload FindSpendReceipt(EconomyPayload payload, string operationId)
        {
            if (payload == null || payload.spendReceipts == null || string.IsNullOrWhiteSpace(operationId)) return null;
            for (int i = 0; i < payload.spendReceipts.Count; i++)
            {
                SpendReceiptPayload receipt = payload.spendReceipts[i];
                if (receipt != null && string.Equals(receipt.operationId, operationId, StringComparison.Ordinal))
                {
                    return receipt;
                }
            }
            return null;
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
                if (!TryReadSchema(json, out int schemaVersion))
                {
                    return RecoverFromBackup(json, out payload);
                }

                if (schemaVersion != SchemaVersion)
                {
                    PreserveUnsupported(json);
                    Debug.LogWarning(
                        $"[CARGO V2][LOGIC] Economy schema {schemaVersion} is unsupported by schema {SchemaVersion}; preserving it untouched and blocking mutations.");
                    return false;
                }

                EconomyPayload parsed = JsonUtility.FromJson<EconomyPayload>(json);
                if (!TryNormalize(parsed, out bool repaired))
                {
                    return RecoverFromBackup(json, out payload);
                }

                payload = parsed;
                if (repaired)
                {
                    PreserveCorrupt(json);
                    if (!TryWritePayload(payload, false)) return false;
                }
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Economy payload read failed safely: {exception.Message}");
                string raw = SafeRead(EconomyKey);
                return RecoverFromBackup(raw, out payload);
            }
        }

        private static bool TryNormalize(EconomyPayload payload, out bool repaired)
        {
            repaired = false;
            if (payload == null || payload.schemaVersion != SchemaVersion || payload.coins < 0 || payload.xp < 0) return false;

            if (payload.rewardedMissionIds == null)
            {
                payload.rewardedMissionIds = new List<int>();
                repaired = true;
            }
            if (payload.settledDeliveryIds == null)
            {
                payload.settledDeliveryIds = new List<string>();
                repaired = true;
            }
            if (payload.spendReceipts == null)
            {
                payload.spendReceipts = new List<SpendReceiptPayload>();
                repaired = true;
            }

            var missionIds = new HashSet<int>();
            var normalizedMissions = new List<int>();
            for (int i = 0; i < payload.rewardedMissionIds.Count; i++)
            {
                int missionId = payload.rewardedMissionIds[i];
                if (missionId < 1 || missionId > 20)
                {
                    repaired = true;
                    continue;
                }
                if (!missionIds.Add(missionId))
                {
                    repaired = true;
                    continue;
                }
                normalizedMissions.Add(missionId);
            }
            normalizedMissions.Sort();
            if (normalizedMissions.Count != payload.rewardedMissionIds.Count) repaired = true;
            payload.rewardedMissionIds = normalizedMissions;

            var deliveryIds = new HashSet<string>(StringComparer.Ordinal);
            var normalizedDeliveries = new List<string>();
            for (int i = 0; i < payload.settledDeliveryIds.Count; i++)
            {
                string deliveryId = payload.settledDeliveryIds[i];
                if (!ValidDeliveryRunId(deliveryId)) return false;
                if (!deliveryIds.Add(deliveryId))
                {
                    repaired = true;
                    continue;
                }
                normalizedDeliveries.Add(deliveryId);
            }
            if (normalizedDeliveries.Count > MaxSettledDeliveryIds) return false;
            payload.settledDeliveryIds = normalizedDeliveries;

            var spendById = new Dictionary<string, SpendReceiptPayload>(StringComparer.Ordinal);
            var normalizedReceipts = new List<SpendReceiptPayload>();
            for (int i = 0; i < payload.spendReceipts.Count; i++)
            {
                SpendReceiptPayload receipt = payload.spendReceipts[i];
                if (receipt == null || receipt.amount <= 0 || !ValidOperationId(receipt.operationId)) return false;

                if (spendById.TryGetValue(receipt.operationId, out SpendReceiptPayload existing))
                {
                    if (existing.amount != receipt.amount) return false;
                    repaired = true;
                    continue;
                }

                spendById.Add(receipt.operationId, receipt);
                normalizedReceipts.Add(receipt);
            }
            if (normalizedReceipts.Count > MaxSpendReceipts) return false;
            payload.spendReceipts = normalizedReceipts;
            return true;
        }

        private static bool RecoverFromBackup(string badPrimary, out EconomyPayload payload)
        {
            payload = null;
            PreserveCorrupt(badPrimary);
            string backupRaw = SafeRead(EconomyBackupKey);
            if (!TryParseCanonical(backupRaw, out EconomyPayload backup))
            {
                Debug.LogWarning("[CARGO V2][LOGIC] Economy primary is corrupt and no valid last-known-good snapshot exists; mutations are blocked to prevent balance loss.");
                return false;
            }

            payload = backup;
            try
            {
                PlayerPrefs.SetString(EconomyKey, backupRaw);
                PlayerPrefs.Save();
                Debug.LogWarning("[CARGO V2][LOGIC] Economy primary recovered from last-known-good snapshot.");
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Economy LKG is usable in memory but primary restore failed: {exception.Message}");
            }
            return true;
        }

        private static bool TrySave(EconomyPayload payload)
        {
            return TryWritePayload(payload, true);
        }

        private static bool TryWritePayload(EconomyPayload payload, bool backupCurrent)
        {
            if (!TryNormalize(payload, out _)) return false;

            try
            {
                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;

                if (backupCurrent)
                {
                    string currentRaw = SafeRead(EconomyKey);
                    if (TryParseCanonical(currentRaw, out _))
                    {
                        PlayerPrefs.SetString(EconomyBackupKey, currentRaw);
                        PlayerPrefs.Save();
                    }
                    else if (!PlayerPrefs.HasKey(EconomyBackupKey))
                    {
                        PlayerPrefs.SetString(EconomyBackupKey, JsonUtility.ToJson(NewPayload()));
                        PlayerPrefs.Save();
                    }
                }

                PlayerPrefs.SetString(EconomyKey, json);
                PlayerPrefs.Save();
                PlayerPrefs.SetString(EconomyBackupKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Economy payload write failed safely: {exception.Message}");
                return false;
            }
        }

        private static bool TryParseCanonical(string raw, out EconomyPayload payload)
        {
            payload = null;
            if (!TryReadSchema(raw, out int schemaVersion) || schemaVersion != SchemaVersion) return false;
            try
            {
                EconomyPayload parsed = JsonUtility.FromJson<EconomyPayload>(raw);
                if (!TryNormalize(parsed, out bool repaired) || repaired) return false;
                payload = parsed;
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        private static bool TryReadSchema(string raw, out int schemaVersion)
        {
            schemaVersion = 0;
            if (string.IsNullOrWhiteSpace(raw)) return false;
            try
            {
                SchemaProbe probe = JsonUtility.FromJson<SchemaProbe>(raw);
                if (probe == null) return false;
                schemaVersion = probe.schemaVersion;
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }

        private static string SafeRead(string key)
        {
            try { return PlayerPrefs.HasKey(key) ? PlayerPrefs.GetString(key, string.Empty) : string.Empty; }
            catch (Exception) { return string.Empty; }
        }

        private static void PreserveCorrupt(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            try
            {
                PlayerPrefs.SetString(CorruptBackupKey, raw);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Could not preserve corrupt economy payload: {exception.Message}");
            }
        }

        private static void PreserveUnsupported(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            try
            {
                PlayerPrefs.SetString(UnsupportedBackupKey, raw);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Could not preserve unsupported economy payload: {exception.Message}");
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
                spendReceipts = new List<SpendReceiptPayload>(),
            };
        }
    }
}
