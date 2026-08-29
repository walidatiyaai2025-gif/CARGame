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
        private const int SchemaVersion = 1;
        private const int MaxUpgradeLevel = 3;

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

            if (!SCR_MissionRewardStore.TrySpendCoins(truck.purchasePrice, out _))
            {
                reason = "Purchase payment could not be committed.";
                return false;
            }

            payload.ownedTrucks.Add(NewOwned(truckId));
            payload.selectedTruckId = truckId;
            if (TrySave(payload))
            {
                reason = $"{truck.displayName} purchased and selected.";
                return true;
            }

            payload.ownedTrucks.RemoveAll(item => item != null && string.Equals(item.truckId, truckId, StringComparison.Ordinal));
            if (!SCR_MissionRewardStore.TryCreditCoins(truck.purchasePrice, out _))
            {
                Debug.LogError($"[CARGO V2][LOGIC] Critical purchase rollback failure for {truckId}; manual economy recovery may be required.");
            }
            reason = "Company save failed; purchase was rolled back.";
            return false;
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

            if (!SCR_MissionRewardStore.TrySpendCoins(cost, out _))
            {
                reason = "Upgrade payment could not be committed.";
                return false;
            }

            SetUpgradeLevel(owned, upgrade, current + 1);
            if (TrySave(payload))
            {
                reason = $"{truck.displayName} {upgrade} upgraded to Lv.{current + 1}.";
                return true;
            }

            SetUpgradeLevel(owned, upgrade, current);
            if (!SCR_MissionRewardStore.TryCreditCoins(cost, out _))
            {
                Debug.LogError($"[CARGO V2][LOGIC] Critical upgrade rollback failure for {truck.id}; manual economy recovery may be required.");
            }
            reason = "Company save failed; upgrade was rolled back.";
            return false;
        }

        private static bool TryLoad(out CompanyPayload payload)
        {
            payload = null;
            try
            {
                if (!PlayerPrefs.HasKey(CompanyKey))
                {
                    payload = NewPayload();
                    return TrySave(payload);
                }

                string json = PlayerPrefs.GetString(CompanyKey, string.Empty);
                payload = string.IsNullOrWhiteSpace(json) ? null : JsonUtility.FromJson<CompanyPayload>(json);
                if (!Validate(payload))
                {
                    BackupCorrupt(json);
                    payload = NewPayload();
                    return TrySave(payload);
                }

                EnsureStarter(payload);
                if (FindOwned(payload, payload.selectedTruckId) == null)
                {
                    payload.selectedTruckId = CargoV2LogisticsCatalog.StarterTruckId;
                    TrySave(payload);
                }
                return true;
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC] Company profile read failed; using safe starter state: {exception.Message}");
                payload = NewPayload();
                return TrySave(payload);
            }
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
    }
}
