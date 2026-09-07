using System;
using System.Collections.Generic;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    public static class SCR_CompanyProgressStore
    {
        public const string CompanyKey = "cargo_v2_company_profile_v1";
        public const string CompanyBackupKey = "cargo_v2_company_profile_v1.lkg";
        public const string CorruptBackupKey = "cargo_v2_company_profile_corrupt_v1";
        public const string UnsupportedBackupKey = "cargo_v2_company_profile_unsupported_v1";
        public const string PendingTransactionKey = "cargo_v2_company_transaction_v1";
        public const string CorruptTransactionBackupKey = "cargo_v2_company_transaction_corrupt_v1";
        public const string UnsupportedTransactionBackupKey = "cargo_v2_company_transaction_unsupported_v1";

        private const int SchemaVersion = 1;
        private const int TransactionSchemaVersion = 1;
        private const int MaxUpgradeLevel = 3;
        private const int PurchaseTransactionKind = 1;
        private const int UpgradeTransactionKind = 2;

        [Serializable]
        private sealed class SchemaProbe
        {
            public int schemaVersion;
        }

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
            if (!TryLoad(out CompanyPayload payload)) return StarterStats();

            OwnedTruckPayload owned = FindOwned(payload, payload.selectedTruckId);
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(payload.selectedTruckId);
            if (owned == null || truck == null) return StarterStats();

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

            if (truck.purchasePrice <= 0 || economy.Coins < truck.purchasePrice)
            {
                reason = $"Requires {Math.Max(0, truck.purchasePrice):N0} coins.";
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
            if (upgrade < CargoV2TruckUpgrade.Engine || upgrade > CargoV2TruckUpgrade.Durability)
            {
                reason = "Unknown upgrade.";
                return false;
            }

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

                string raw = PlayerPrefs.GetString(CompanyKey, string.Empty);
                if (!TryReadSchema(raw, out int schemaVersion))
                {
                    PreserveCorrupt(raw);
                    if (!TryLoadBackup(out payload)) return false;
                    RestorePrimaryBestEffort(payload);
                    return TryRecoverPendingTransaction(payload);
                }

                if (schemaVersion != SchemaVersion)
                {
                    PreserveUnsupported(raw);
                    Debug.LogWarning(
                        $"[CARGO V2][LOGIC] Company schema {schemaVersion} is unsupported by schema {SchemaVersion}; preserving it untouched and blocking mutations.");
                    return false;
                }

                CompanyPayload parsed = JsonUtility.FromJson<CompanyPayload>(raw);
                if (parsed == null)
                {
                    PreserveCorrupt(raw);
                    if (!TryLoadBackup(out payload)) return false;
                    RestorePrimaryBestEffort(payload);
                    return TryRecoverPendingTransaction(payload);
                }

                payload = SalvageCurrentPayload(parsed, out bool repaired);
                if (payload == null)
                {
                    PreserveCorrupt(raw);
                    if (!TryLoadBackup(out payload)) return false;
                    RestorePrimaryBestEffort(payload);
                    return TryRecoverPendingTransaction(payload);
                }

                if (repaired)
                {
                    PreserveCorrupt(raw);
                    if (!TryWritePayload(payload, false)) return false;
                    Debug.LogWarning("[CARGO V2][LOGIC] Company profile was repaired without discarding valid fleet ownership or upgrades.");
                }

                return TryRecoverPendingTransaction(payload);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company profile read failed safely: {exception.Message}");
                string raw = SafeRead(CompanyKey);
                PreserveCorrupt(raw);
                if (!TryLoadBackup(out payload)) return false;
                RestorePrimaryBestEffort(payload);
                return TryRecoverPendingTransaction(payload);
            }
        }

        private static CompanyPayload SalvageCurrentPayload(CompanyPayload source, out bool repaired)
        {
            repaired = false;
            if (source == null || source.schemaVersion != SchemaVersion) return null;

            var byId = new Dictionary<string, OwnedTruckPayload>(StringComparer.Ordinal);
            if (source.ownedTrucks == null)
            {
                repaired = true;
            }
            else
            {
                for (int i = 0; i < source.ownedTrucks.Count; i++)
                {
                    OwnedTruckPayload candidate = source.ownedTrucks[i];
                    if (candidate == null || CargoV2LogisticsCatalog.GetTruck(candidate.truckId) == null)
                    {
                        repaired = true;
                        continue;
                    }

                    int engine = ClampUpgrade(candidate.engineLevel);
                    int handling = ClampUpgrade(candidate.handlingLevel);
                    int durability = ClampUpgrade(candidate.durabilityLevel);
                    if (engine != candidate.engineLevel || handling != candidate.handlingLevel || durability != candidate.durabilityLevel)
                    {
                        repaired = true;
                    }

                    if (byId.TryGetValue(candidate.truckId, out OwnedTruckPayload existing))
                    {
                        existing.engineLevel = Math.Max(existing.engineLevel, engine);
                        existing.handlingLevel = Math.Max(existing.handlingLevel, handling);
                        existing.durabilityLevel = Math.Max(existing.durabilityLevel, durability);
                        repaired = true;
                    }
                    else
                    {
                        byId.Add(candidate.truckId, new OwnedTruckPayload
                        {
                            truckId = candidate.truckId,
                            engineLevel = engine,
                            handlingLevel = handling,
                            durabilityLevel = durability,
                        });
                    }
                }
            }

            if (!byId.ContainsKey(CargoV2LogisticsCatalog.StarterTruckId))
            {
                byId.Add(CargoV2LogisticsCatalog.StarterTruckId, NewOwned(CargoV2LogisticsCatalog.StarterTruckId));
                repaired = true;
            }

            var ordered = new List<OwnedTruckPayload>();
            foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
            {
                if (truck != null && byId.TryGetValue(truck.id, out OwnedTruckPayload owned)) ordered.Add(owned);
            }

            string selected = source.selectedTruckId;
            if (string.IsNullOrWhiteSpace(selected) || !byId.ContainsKey(selected))
            {
                selected = CargoV2LogisticsCatalog.StarterTruckId;
                repaired = true;
            }

            if (source.ownedTrucks == null || source.ownedTrucks.Count != ordered.Count) repaired = true;

            return new CompanyPayload
            {
                schemaVersion = SchemaVersion,
                selectedTruckId = selected,
                ownedTrucks = ordered,
            };
        }

        private static bool TryRecoverPendingTransaction(CompanyPayload payload)
        {
            if (!PlayerPrefs.HasKey(PendingTransactionKey)) return true;

            string raw = SafeRead(PendingTransactionKey);
            if (!TryReadSchema(raw, out int schemaVersion))
            {
                PreserveCorruptTransaction(raw);
                Debug.LogWarning("[CARGO V2][LOGIC] Malformed company transaction journal was preserved and blocks new company mutations because prior payment state cannot be proven.");
                return false;
            }

            if (schemaVersion != TransactionSchemaVersion)
            {
                PreserveUnsupportedTransaction(raw);
                Debug.LogWarning(
                    $"[CARGO V2][LOGIC] Company transaction schema {schemaVersion} is unsupported; journal is preserved untouched and company mutations are blocked.");
                return false;
            }

            PendingTransactionPayload pending;
            try { pending = JsonUtility.FromJson<PendingTransactionPayload>(raw); }
            catch (Exception) { pending = null; }

            if (!ValidatePendingTransaction(pending))
            {
                PreserveCorruptTransaction(raw);
                if (CanProveTransactionUnpaid(pending))
                {
                    Debug.LogWarning("[CARGO V2][LOGIC] Invalid unpaid company transaction journal was quarantined and cleared; no debit had been committed.");
                    return TryClearPendingTransaction();
                }

                Debug.LogWarning("[CARGO V2][LOGIC] Invalid company transaction journal may reference committed payment; it is preserved and blocks mutation for safe recovery.");
                return false;
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

        private static bool CanProveTransactionUnpaid(PendingTransactionPayload pending)
        {
            if (pending == null || pending.coinCost <= 0 || !ValidOperationId(pending.operationId)) return false;
            return SCR_MissionRewardStore.TryReadSpendCommit(
                       pending.coinCost,
                       pending.operationId,
                       out bool committed,
                       out _) && !committed;
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

            if (!SCR_MissionRewardStore.TryReadSpendCommit(
                    pending.coinCost,
                    pending.operationId,
                    out bool paymentCommitted,
                    out SCR_MissionRewardStore.Snapshot economy))
            {
                reason = "Transaction payment state could not be read safely.";
                return false;
            }

            CargoV2TruckUpgrade upgrade = CargoV2TruckUpgrade.Engine;
            OwnedTruckPayload existing = FindOwned(payload, pending.truckId);

            if (!paymentCommitted)
            {
                // Until the spend receipt exists, current catalog/unlock/ownership
                // rules remain authoritative and the journal must still describe the
                // exact pre-state. After the receipt commits, the journal itself is
                // authoritative transaction intent so a later app/catalog update can
                // never strand a legitimate debit.
                if (pending.kind == PurchaseTransactionKind)
                {
                    if (existing != null)
                    {
                        reason = "Unpaid purchase journal conflicts with already-owned truck state.";
                        return false;
                    }
                    if (truck.purchasePrice <= 0 || truck.purchasePrice != pending.coinCost)
                    {
                        reason = "Pending purchase price no longer matches the authoritative catalog before payment.";
                        return false;
                    }
                    if (economy.Xp < truck.unlockXp)
                    {
                        reason = "Pending purchase no longer satisfies the authoritative unlock state before payment.";
                        return false;
                    }
                }
                else
                {
                    upgrade = (CargoV2TruckUpgrade)pending.upgrade;
                    long expectedCost = CargoV2LogisticsCatalog.GetUpgradeCost(truck, upgrade, pending.fromLevel);
                    if (expectedCost <= 0 || expectedCost != pending.coinCost)
                    {
                        reason = "Pending upgrade cost no longer matches the authoritative catalog before payment.";
                        return false;
                    }
                    if (existing == null || GetUpgradeLevel(existing, upgrade) != pending.fromLevel)
                    {
                        reason = "Unpaid upgrade journal no longer matches the exact pre-upgrade state.";
                        return false;
                    }
                }

                if (!SCR_MissionRewardStore.TryEnsureCoinSpend(
                        pending.coinCost,
                        pending.operationId,
                        out paymentCommitted,
                        out economy))
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
            }

            if (pending.kind == PurchaseTransactionKind)
            {
                if (existing == null) payload.ownedTrucks.Add(NewOwned(pending.truckId));
                payload.selectedTruckId = pending.truckId;
            }
            else
            {
                upgrade = (CargoV2TruckUpgrade)pending.upgrade;
                existing = FindOwned(payload, pending.truckId);
                if (existing == null)
                {
                    reason = "Committed upgrade payment cannot be applied because the recorded truck is no longer owned.";
                    return false;
                }

                int level = GetUpgradeLevel(existing, upgrade);
                if (level == pending.fromLevel)
                {
                    SetUpgradeLevel(existing, upgrade, pending.toLevel);
                }
                else if (level != pending.toLevel)
                {
                    reason = "Committed upgrade payment conflicts with an impossible fleet level; journal retained for investigation.";
                    return false;
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
                !ValidOperationId(pending.operationId) ||
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

            if (pending.kind != UpgradeTransactionKind ||
                pending.upgrade < (int)CargoV2TruckUpgrade.Engine ||
                pending.upgrade > (int)CargoV2TruckUpgrade.Durability ||
                pending.fromLevel < 0 || pending.fromLevel >= MaxUpgradeLevel)
            {
                return false;
            }

            return pending.toLevel == pending.fromLevel + 1 && pending.toLevel <= MaxUpgradeLevel;
        }

        private static bool TrySave(CompanyPayload payload)
        {
            return TryWritePayload(payload, true);
        }

        private static bool TryWritePayload(CompanyPayload payload, bool backupCurrent)
        {
            if (!Validate(payload)) return false;
            try
            {
                string json = JsonUtility.ToJson(payload);
                if (string.IsNullOrWhiteSpace(json)) return false;

                if (backupCurrent)
                {
                    string currentRaw = SafeRead(CompanyKey);
                    if (TryParseCanonical(currentRaw, out _))
                    {
                        PlayerPrefs.SetString(CompanyBackupKey, currentRaw);
                        PlayerPrefs.Save();
                    }
                    else if (!PlayerPrefs.HasKey(CompanyBackupKey))
                    {
                        PlayerPrefs.SetString(CompanyBackupKey, JsonUtility.ToJson(NewPayload()));
                        PlayerPrefs.Save();
                    }
                }

                PlayerPrefs.SetString(CompanyKey, json);
                PlayerPrefs.Save();
                PlayerPrefs.SetString(CompanyBackupKey, json);
                PlayerPrefs.Save();
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company profile write failed safely: {exception.Message}");
                return false;
            }
        }

        private static bool TryLoadBackup(out CompanyPayload payload)
        {
            return TryParseCanonical(SafeRead(CompanyBackupKey), out payload);
        }

        private static bool TryParseCanonical(string raw, out CompanyPayload payload)
        {
            payload = null;
            if (!TryReadSchema(raw, out int schemaVersion) || schemaVersion != SchemaVersion) return false;
            try
            {
                CompanyPayload parsed = JsonUtility.FromJson<CompanyPayload>(raw);
                if (!Validate(parsed)) return false;
                payload = parsed;
                return true;
            }
            catch (Exception)
            {
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

            return !string.IsNullOrWhiteSpace(payload.selectedTruckId) && FindOwned(payload, payload.selectedTruckId) != null;
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
            int safe = ClampUpgrade(level);
            if (upgrade == CargoV2TruckUpgrade.Engine) owned.engineLevel = safe;
            else if (upgrade == CargoV2TruckUpgrade.Handling) owned.handlingLevel = safe;
            else owned.durabilityLevel = safe;
        }

        private static int ClampUpgrade(int value) => Mathf.Clamp(value, 0, MaxUpgradeLevel);
        private static bool ValidUpgrade(int value) => value >= 0 && value <= MaxUpgradeLevel;
        private static bool ValidOperationId(string value) =>
            !string.IsNullOrWhiteSpace(value) && Guid.TryParseExact(value, "N", out _);

        private static CargoV2TruckRuntimeStats StarterStats()
        {
            return CargoV2LogisticsCatalog.GetRuntimeStats(
                CargoV2LogisticsCatalog.GetTruck(CargoV2LogisticsCatalog.StarterTruckId), 0, 0, 0);
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

        private static void RestorePrimaryBestEffort(CompanyPayload payload)
        {
            if (payload == null) return;
            try
            {
                PlayerPrefs.SetString(CompanyKey, JsonUtility.ToJson(payload));
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company LKG is usable in memory but primary restore failed: {exception.Message}");
            }
        }

        private static void PreserveCorrupt(string raw) => Preserve(raw, CorruptBackupKey, "corrupt company profile");
        private static void PreserveUnsupported(string raw) => Preserve(raw, UnsupportedBackupKey, "unsupported company profile");
        private static void PreserveCorruptTransaction(string raw) => Preserve(raw, CorruptTransactionBackupKey, "corrupt company transaction");
        private static void PreserveUnsupportedTransaction(string raw) => Preserve(raw, UnsupportedTransactionBackupKey, "unsupported company transaction");

        private static void Preserve(string raw, string key, string label)
        {
            if (string.IsNullOrWhiteSpace(raw)) return;
            try
            {
                PlayerPrefs.SetString(key, raw);
                PlayerPrefs.Save();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Could not preserve {label}: {exception.Message}");
            }
        }
    }
}
