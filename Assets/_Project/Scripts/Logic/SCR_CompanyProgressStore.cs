using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_CompanyProgressStore
    {
        private const string CompanyKey = "cargo_v2_company_profile_v1";
        private const string CorruptBackupKey = "cargo_v2_company_profile_corrupt_v1";
        private const string PendingTransactionKey = "cargo_v2_company_transaction_v1";
        private const string CorruptTransactionBackupKey = "cargo_v2_company_transaction_corrupt_v1";
        private const int SchemaVersion = 1;
        private const int TransactionSchemaVersion = 1;
        private const int MaxUpgradeLevel = 3;
        private const int PurchaseTransactionKind = 1;
        private const int UpgradeTransactionKind = 2;

        [Serializable]
        private sealed class OwnedTruckPayload
        {
            public string truckId;
            public int engineLevel;
            public int handlingLevel;
            public int durabilityLevel;
        }

        [Serializable]
        private sealed class CompanyPayload
        {
            public int schemaVersion = SchemaVersion;
            public string selectedTruckId;
            public List<OwnedTruckPayload> ownedTrucks = new List<OwnedTruckPayload>();
        }

        [Serializable]
        private sealed class PendingTransactionPayload
        {
            public int schemaVersion = TransactionSchemaVersion;
            public string operationId;
            public int kind;
            public string truckId;
            public int upgrade = -1;
            public int fromLevel;
            public int toLevel;
            public long coinCost;
        }

        public readonly struct TruckState
        {
            public TruckState(string truckId, int engine, int handling, int durability)
            {
                TruckId = truckId;
                EngineLevel = engine;
                HandlingLevel = handling;
                DurabilityLevel = durability;
            }

            public string TruckId { get; }
            public int EngineLevel { get; }
            public int HandlingLevel { get; }
            public int DurabilityLevel { get; }
        }

        public static string GetSelectedTruckId()
        {
            if (!TryLoad(out CompanyPayload payload)) return CargoV2LogisticsCatalog.StarterTruckId;
            return payload.selectedTruckId;
        }

        public static CargoV2TruckRuntimeStats GetSelectedRuntimeStats()
        {
            if (!TryLoad(out CompanyPayload payload))
            {
                return CargoV2LogisticsCatalog.GetRuntimeStats(
                    CargoV2LogisticsCatalog.GetTruck(CargoV2LogisticsCatalog.StarterTruckId), 0, 0, 0);
            }

            OwnedTruckPayload owned = FindOwned(payload, payload.selectedTruckId);
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(payload.selectedTruckId);
            if (owned == null || truck == null)
            {
                truck = CargoV2LogisticsCatalog.GetTruck(CargoV2LogisticsCatalog.StarterTruckId);
                return CargoV2LogisticsCatalog.GetRuntimeStats(truck, 0, 0, 0);
            }

            return CargoV2LogisticsCatalog.GetRuntimeStats(
                truck,
                owned.engineLevel,
                owned.handlingLevel,
                owned.durabilityLevel);
        }

        public static bool IsOwned(string truckId)
        {
            return TryLoad(out CompanyPayload payload) && FindOwned(payload, truckId) != null;
        }

        public static bool TryGetTruckState(string truckId, out TruckState state)
        {
            state = default;
            if (!TryLoad(out CompanyPayload payload)) return false;
            OwnedTruckPayload owned = FindOwned(payload, truckId);
            if (owned == null) return false;
            state = new TruckState(owned.truckId, owned.engineLevel, owned.handlingLevel, owned.durabilityLevel);
            return true;
        }

        public static bool TrySelectTruck(string truckId, out string reason)
        {
            reason = string.Empty;
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(truckId);
            if (truck == null)
            {
                reason = "Unknown truck.";
                return false;
            }

            if (!TryLoad(out CompanyPayload payload))
            {
                reason = "Company profile is unavailable.";
                return false;
            }

            if (FindOwned(payload, truckId) == null)
            {
                reason = "Truck is not owned.";
                return false;
            }

            payload.selectedTruckId = truckId;
            if (!TrySave(payload))
            {
                reason = "Truck selection could not be saved.";
                return false;
            }

            reason = $"{truck.displayName} selected.";
            return true;
        }

        public static bool TryBuyTruck(string truckId, out string reason)
        {
            reason = string.Empty;
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(truckId);
            if (truck == null)
            {
                reason = "Unknown truck.";
                return false;
            }

            if (!TryLoad(out CompanyPayload payload))
            {
                reason = "Company profile is unavailable.";
                return false;
            }

            if (FindOwned(payload, truckId) != null)
            {
                reason = "Truck is already owned.";
                return false;
            }

            if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy))
            {
                reason = "Economy state is unavailable.";
                return false;
            }

            if (economy.Xp < truck.unlockXp)
            {
                reason = $"Requires {truck.unlockXp:N0} XP.";
                return false;
            }

            if (economy.Coins < truck.purchasePrice)
            {
                reason = $"Requires {truck.purchasePrice:N0} coins.";
                return false;
            }

            PendingTransactionPayload pending = new PendingTransactionPayload
            {
                operationId = Guid.NewGuid().ToString("N"),
                kind = PurchaseTransactionKind,
                truckId = truckId,
                upgrade = -1,
                fromLevel = 0,
                toLevel = 0,
                coinCost = truck.purchasePrice,
            };

            if (!TryWritePendingTransaction(pending))
            {
                reason = "Purchase recovery journal could not be saved.";
                return false;
            }

            if (!TryResolvePendingTransaction(payload, pending, out bool applied, out reason))
            {
                if (string.IsNullOrWhiteSpace(reason)) reason = "Purchase remains pending recovery.";
                return false;
            }

            if (!applied) return false;
            reason = $"{truck.displayName} purchased and selected.";
            return true;
        }

        public static bool TryUpgradeSelected(CargoV2TruckUpgrade upgrade, out string reason)
        {
            reason = string.Empty;
            if (!TryLoad(out CompanyPayload payload))
            {
                reason = "Company profile is unavailable.";
                return false;
            }

            OwnedTruckPayload owned = FindOwned(payload, payload.selectedTruckId);
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(payload.selectedTruckId);
            if (owned == null || truck == null)
            {
                reason = "Selected truck is unavailable.";
                return false;
            }

            int current = GetUpgradeLevel(owned, upgrade);
            if (current >= MaxUpgradeLevel)
            {
                reason = "Upgrade is already MAX.";
                return false;
            }

            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(truck, upgrade, current);
            if (cost <= 0)
            {
                reason = "Upgrade balance is invalid.";
                return false;
            }

            if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy) || economy.Coins < cost)
            {
                reason = $"Requires {cost:N0} coins.";
                return false;
            }

            PendingTransactionPayload pending = new PendingTransactionPayload
            {
                operationId = Guid.NewGuid().ToString("N"),
                kind = UpgradeTransactionKind,
                truckId = truck.id,
                upgrade = (int)upgrade,
                fromLevel = current,
                toLevel = current + 1,
                coinCost = cost,
            };

            if (!TryWritePendingTransaction(pending))
            {
                reason = "Upgrade recovery journal could not be saved.";
                return false;
            }

            if (!TryResolvePendingTransaction(payload, pending, out bool applied, out reason))
            {
                if (string.IsNullOrWhiteSpace(reason)) reason = "Upgrade remains pending recovery.";
                return false;
            }

            if (!applied) return false;
            reason = $"{truck.displayName} {upgrade} upgraded to Lv.{current + 1}.";
            return true;
        }

        private static bool TryLoad(out CompanyPayload payload)
        {
            payload = null;
            try
            {
                if (!PlayerPrefs.HasKey(CompanyKey))
                {
                    payload = NewPayload();
                    if (!TrySave(payload)) return false;
                    return TryRecoverPendingTransaction(payload);
                }

                string json = PlayerPrefs.GetString(CompanyKey, string.Empty);
                payload = string.IsNullOrWhiteSpace(json) ? null : JsonUtility.FromJson<CompanyPayload>(json);
                if (!Validate(payload))
                {
                    BackupCorrupt(json);
                    payload = NewPayload();
                    if (!TrySave(payload)) return false;
                    return TryRecoverPendingTransaction(payload);
                }

                EnsureStarter(payload);
                if (FindOwned(payload, payload.selectedTruckId) == null)
                {
                    payload.selectedTruckId = CargoV2LogisticsCatalog.StarterTruckId;
                    if (!TrySave(payload)) return false;
                }

                return TryRecoverPendingTransaction(payload);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company profile read failed; using safe starter state: {exception.Message}");
                payload = NewPayload();
                if (!TrySave(payload)) return false;
                return TryRecoverPendingTransaction(payload);
            }
        }

        private static bool TryRecoverPendingTransaction(CompanyPayload payload)
        {
            if (!PlayerPrefs.HasKey(PendingTransactionKey)) return true;

            string json = PlayerPrefs.GetString(PendingTransactionKey, string.Empty);
            PendingTransactionPayload pending = null;
            try
            {
                pending = string.IsNullOrWhiteSpace(json)
                    ? null
                    : JsonUtility.FromJson<PendingTransactionPayload>(json);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company transaction journal parse failed: {exception.Message}");
            }

            if (!ValidatePendingTransaction(pending))
            {
                BackupCorruptTransaction(json);
                Debug.LogWarning("[CARGO V2][LOGIC] Corrupt company transaction journal was quarantined; no new debit was attempted.");
                return true;
            }

            if (!TryResolvePendingTransaction(payload, pending, out bool applied, out string reason))
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company transaction recovery is still pending: {reason}");
                return false;
            }

            if (applied)
            {
                Debug.Log($"[CARGO V2][LOGIC] Recovered company transaction {pending.operationId} without duplicate coin spend.");
            }
            return true;
        }

        private static bool TryResolvePendingTransaction(
            CompanyPayload payload,
            PendingTransactionPayload pending,
            out bool applied,
            out string reason)
        {
            applied = false;
            reason = string.Empty;
            if (!Validate(payload) || !ValidatePendingTransaction(pending))
            {
                reason = "Company transaction journal is invalid.";
                return false;
            }

            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(pending.truckId);
            if (truck == null)
            {
                reason = "Pending transaction truck is unavailable.";
                return false;
            }

            CargoV2TruckUpgrade upgrade = CargoV2TruckUpgrade.Engine;
            if (pending.kind == PurchaseTransactionKind)
            {
                if (truck.purchasePrice <= 0 || truck.purchasePrice != pending.coinCost)
                {
                    reason = "Pending purchase price no longer matches the authoritative catalog.";
                    return false;
                }

                if (!SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy) ||
                    economy.Xp < truck.unlockXp)
                {
                    reason = "Pending purchase no longer satisfies the authoritative unlock state.";
                    return false;
                }
            }
            else
            {
                upgrade = (CargoV2TruckUpgrade)pending.upgrade;
                long expectedCost = CargoV2LogisticsCatalog.GetUpgradeCost(truck, upgrade, pending.fromLevel);
                if (expectedCost <= 0 || expectedCost != pending.coinCost)
                {
                    reason = "Pending upgrade cost no longer matches the authoritative catalog.";
                    return false;
                }

                OwnedTruckPayload existing = FindOwned(payload, pending.truckId);
                if (existing == null)
                {
                    reason = "Pending upgrade truck is no longer owned.";
                    return false;
                }

                int level = GetUpgradeLevel(existing, upgrade);
                if (level != pending.fromLevel && level != pending.toLevel)
                {
                    reason = "Pending upgrade level no longer matches the recoverable state.";
                    return false;
                }
            }

            if (!SCR_MissionRewardStore.TryEnsureCoinSpend(
                    pending.coinCost,
                    pending.operationId,
                    out bool paymentCommitted,
                    out _))
            {
                reason = "Transaction payment state could not be persisted.";
                return false;
            }

            if (!paymentCommitted)
            {
                if (!TryClearPendingTransaction())
                {
                    reason = "Insufficient funds and transaction journal could not be cleared.";
                    return false;
                }
                reason = $"Requires {pending.coinCost:N0} coins.";
                return true;
            }

            if (pending.kind == PurchaseTransactionKind)
            {
                if (FindOwned(payload, pending.truckId) == null)
                {
                    payload.ownedTrucks.Add(NewOwned(pending.truckId));
                }
                payload.selectedTruckId = pending.truckId;
            }
            else
            {
                OwnedTruckPayload owned = FindOwned(payload, pending.truckId);
                int level = GetUpgradeLevel(owned, upgrade);
                if (level == pending.fromLevel)
                {
                    SetUpgradeLevel(owned, upgrade, pending.toLevel);
                }
            }

            if (!TrySave(payload))
            {
                reason = "Payment is committed; company state remains pending idempotent recovery.";
                return false;
            }

            if (!TryClearPendingTransaction())
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company transaction {pending.operationId} committed but journal cleanup will retry later.");
            }

            applied = true;
            return true;
        }

        private static bool TryWritePendingTransaction(PendingTransactionPayload pending)
        {
            if (!ValidatePendingTransaction(pending) || PlayerPrefs.HasKey(PendingTransactionKey)) return false;
            try
            {
                string json = JsonUtility.ToJson(pending);
                if (string.IsNullOrWhiteSpace(json)) return false;
                PlayerPrefs.SetString(PendingTransactionKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company transaction journal write failed safely: {exception.Message}");
                return false;
            }
        }

        private static bool TryClearPendingTransaction()
        {
            try
            {
                PlayerPrefs.DeleteKey(PendingTransactionKey);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company transaction journal cleanup failed safely: {exception.Message}");
                return false;
            }
        }

        private static bool ValidatePendingTransaction(PendingTransactionPayload pending)
        {
            if (pending == null || pending.schemaVersion != TransactionSchemaVersion ||
                string.IsNullOrWhiteSpace(pending.operationId) ||
                !Guid.TryParseExact(pending.operationId, "N", out _) ||
                string.IsNullOrWhiteSpace(pending.truckId) ||
                CargoV2LogisticsCatalog.GetTruck(pending.truckId) == null ||
                pending.coinCost <= 0)
            {
                return false;
            }

            if (pending.kind == PurchaseTransactionKind)
            {
                return pending.upgrade == -1 && pending.fromLevel == 0 && pending.toLevel == 0;
            }

            if (pending.kind != UpgradeTransactionKind || pending.upgrade < (int)CargoV2TruckUpgrade.Engine ||
                pending.upgrade > (int)CargoV2TruckUpgrade.Durability ||
                pending.fromLevel < 0 || pending.fromLevel >= MaxUpgradeLevel)
            {
                return false;
            }

            return pending.toLevel == pending.fromLevel + 1 && pending.toLevel <= MaxUpgradeLevel;
        }

        private static bool TrySave(CompanyPayload payload)
        {
            try
            {
                if (!Validate(payload)) return false;
                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;
                PlayerPrefs.SetString(CompanyKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company profile write failed safely: {exception.Message}");
                return false;
            }
        }

        private static CompanyPayload NewPayload()
        {
            return new CompanyPayload
            {
                schemaVersion = SchemaVersion,
                selectedTruckId = CargoV2LogisticsCatalog.StarterTruckId,
                ownedTrucks = new List<OwnedTruckPayload> { NewOwned(CargoV2LogisticsCatalog.StarterTruckId) },
            };
        }

        private static OwnedTruckPayload NewOwned(string truckId)
        {
            return new OwnedTruckPayload
            {
                truckId = truckId,
                engineLevel = 0,
                handlingLevel = 0,
                durabilityLevel = 0,
            };
        }

        private static bool Validate(CompanyPayload payload)
        {
            if (payload == null || payload.schemaVersion != SchemaVersion || payload.ownedTrucks == null) return false;
            if (payload.ownedTrucks.Count == 0 || payload.ownedTrucks.Count > CargoV2LogisticsCatalog.AllTrucks.Count) return false;

            var seen = new HashSet<string>(StringComparer.Ordinal);
            for (int i = 0; i < payload.ownedTrucks.Count; i++)
            {
                OwnedTruckPayload owned = payload.ownedTrucks[i];
                if (owned == null || CargoV2LogisticsCatalog.GetTruck(owned.truckId) == null || !seen.Add(owned.truckId)) return false;
                if (!ValidUpgrade(owned.engineLevel) || !ValidUpgrade(owned.handlingLevel) || !ValidUpgrade(owned.durabilityLevel)) return false;
            }

            return !string.IsNullOrWhiteSpace(payload.selectedTruckId) && CargoV2LogisticsCatalog.GetTruck(payload.selectedTruckId) != null;
        }

        private static void EnsureStarter(CompanyPayload payload)
        {
            if (FindOwned(payload, CargoV2LogisticsCatalog.StarterTruckId) == null)
            {
                payload.ownedTrucks.Insert(0, NewOwned(CargoV2LogisticsCatalog.StarterTruckId));
                TrySave(payload);
            }
        }

        private static OwnedTruckPayload FindOwned(CompanyPayload payload, string truckId)
        {
            if (payload == null || payload.ownedTrucks == null || string.IsNullOrEmpty(truckId)) return null;
            for (int i = 0; i < payload.ownedTrucks.Count; i++)
            {
                OwnedTruckPayload owned = payload.ownedTrucks[i];
                if (owned != null && string.Equals(owned.truckId, truckId, StringComparison.Ordinal)) return owned;
            }
            return null;
        }

        private static int GetUpgradeLevel(OwnedTruckPayload owned, CargoV2TruckUpgrade upgrade)
        {
            if (upgrade == CargoV2TruckUpgrade.Engine) return owned.engineLevel;
            if (upgrade == CargoV2TruckUpgrade.Handling) return owned.handlingLevel;
            return owned.durabilityLevel;
        }

        private static void SetUpgradeLevel(OwnedTruckPayload owned, CargoV2TruckUpgrade upgrade, int level)
        {
            if (upgrade == CargoV2TruckUpgrade.Engine) owned.engineLevel = level;
            else if (upgrade == CargoV2TruckUpgrade.Handling) owned.handlingLevel = level;
            else owned.durabilityLevel = level;
        }

        private static bool ValidUpgrade(int value) => value >= 0 && value <= MaxUpgradeLevel;

        private static void BackupCorrupt(string json)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(json)) PlayerPrefs.SetString(CorruptBackupKey, json);
                PlayerPrefs.DeleteKey(CompanyKey);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Could not preserve corrupt company payload: {exception.Message}");
            }
        }

        private static void BackupCorruptTransaction(string json)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(json)) PlayerPrefs.SetString(CorruptTransactionBackupKey, json);
                PlayerPrefs.DeleteKey(PendingTransactionKey);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Could not quarantine corrupt company transaction: {exception.Message}");
            }
        }
    }
}
