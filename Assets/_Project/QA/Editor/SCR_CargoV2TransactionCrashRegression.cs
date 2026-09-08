#if UNITY_EDITOR
using System;
using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.QA.EditorTools
{
    public static class SCR_CargoV2TransactionCrashRegression
    {
        public static void ValidateOrThrow()
        {
            StringState economy = StringState.Capture(SCR_MissionRewardStore.EconomyKey);
            StringState economyLkg = StringState.Capture(SCR_MissionRewardStore.EconomyBackupKey);
            StringState company = StringState.Capture(SCR_CompanyProgressStore.CompanyKey);
            StringState companyLkg = StringState.Capture(SCR_CompanyProgressStore.CompanyBackupKey);
            StringState pending = StringState.Capture(SCR_CompanyProgressStore.PendingTransactionKey);
            try
            {
                TestUnpaidPurchaseCompletesExactlyOnce();
                TestCommittedPurchaseFinishesWithoutSecondDebit();
                TestCompanyCommittedPurchaseOnlyCleansJournal();
                TestCommittedUpgradeFinishesWithoutSecondDebit();
                TestCompanyCommittedUpgradeOnlyCleansJournal();
                TestInsufficientUpgradeClearsUnpaidJournalWithoutMutation();
            }
            finally
            {
                economy.Restore(SCR_MissionRewardStore.EconomyKey);
                economyLkg.Restore(SCR_MissionRewardStore.EconomyBackupKey);
                company.Restore(SCR_CompanyProgressStore.CompanyKey);
                companyLkg.Restore(SCR_CompanyProgressStore.CompanyBackupKey);
                pending.Restore(SCR_CompanyProgressStore.PendingTransactionKey);
                PlayerPrefs.Save();
            }
        }

        private static void TestUnpaidPurchaseCompletesExactlyOnce()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            string op = Guid.NewGuid().ToString("N");
            SeedStarterCompany();
            SeedEconomy(5000, 1000, string.Empty);
            SeedPurchaseJournal(op, titan.id, titan.purchasePrice);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Unpaid purchase journal should finish purchase after restart.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy), "Economy must remain readable after purchase recovery.");
            Require(economy.Coins == 5000 - titan.purchasePrice, "Recovered purchase must debit exactly once.");
            Require(SCR_MissionRewardStore.TryReadSpendCommit(titan.purchasePrice, op, out bool committed, out _) && committed,
                "Recovered purchase must persist stable spend receipt.");
            Require(!PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Recovered purchase journal must clear after company commit.");
        }

        private static void TestCommittedPurchaseFinishesWithoutSecondDebit()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            string op = Guid.NewGuid().ToString("N");
            SeedStarterCompany();
            SeedEconomy(3800, 1000, Receipt(op, titan.purchasePrice));
            SeedPurchaseJournal(op, titan.id, titan.purchasePrice);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Post-debit purchase crash must finish ownership.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 3800,
                "Post-debit purchase recovery must not charge again.");
        }

        private static void TestCompanyCommittedPurchaseOnlyCleansJournal()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            string op = Guid.NewGuid().ToString("N");
            SeedTitanCompany(0);
            SeedEconomy(3800, 1000, Receipt(op, titan.purchasePrice));
            SeedPurchaseJournal(op, titan.id, titan.purchasePrice);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Post-company-save purchase crash must retain selected owned truck.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 3800,
                "Journal-cleanup replay must not charge committed purchase again.");
            Require(!PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Cleanup replay must retire purchase journal.");
        }

        private static void TestCommittedUpgradeFinishesWithoutSecondDebit()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(titan, CargoV2TruckUpgrade.Engine, 0);
            string op = Guid.NewGuid().ToString("N");
            SeedTitanCompany(0);
            SeedEconomy(2700, 1000, Receipt(op, cost));
            SeedUpgradeJournal(op, titan.id, CargoV2TruckUpgrade.Engine, 0, 1, cost);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Post-debit upgrade crash must recover selected fleet.");
            Require(SCR_CompanyProgressStore.TryGetTruckState(titan.id, out SCR_CompanyProgressStore.TruckState state) && state.EngineLevel == 1,
                "Post-debit upgrade crash must apply recorded level exactly once.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 2700,
                "Post-debit upgrade recovery must not charge again.");
        }

        private static void TestCompanyCommittedUpgradeOnlyCleansJournal()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(titan, CargoV2TruckUpgrade.Engine, 0);
            string op = Guid.NewGuid().ToString("N");
            SeedTitanCompany(1);
            SeedEconomy(2700, 1000, Receipt(op, cost));
            SeedUpgradeJournal(op, titan.id, CargoV2TruckUpgrade.Engine, 0, 1, cost);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Post-company-save upgrade crash must remain readable.");
            Require(SCR_CompanyProgressStore.TryGetTruckState(titan.id, out SCR_CompanyProgressStore.TruckState state) && state.EngineLevel == 1,
                "Upgrade cleanup replay must not increment level twice.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 2700,
                "Upgrade cleanup replay must not charge twice.");
            Require(!PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Cleanup replay must retire upgrade journal.");
        }

        private static void TestInsufficientUpgradeClearsUnpaidJournalWithoutMutation()
        {
            Clear();
            CargoV2TruckSpec titan = RequireTruck("titan_x");
            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(titan, CargoV2TruckUpgrade.Engine, 0);
            string op = Guid.NewGuid().ToString("N");
            SeedTitanCompany(0);
            SeedEconomy(0, 1000, string.Empty);
            SeedUpgradeJournal(op, titan.id, CargoV2TruckUpgrade.Engine, 0, 1, cost);

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == titan.id, "Insufficient-fund recovery must leave valid fleet usable.");
            Require(SCR_CompanyProgressStore.TryGetTruckState(titan.id, out SCR_CompanyProgressStore.TruckState state) && state.EngineLevel == 0,
                "Unpaid insufficient upgrade must not mutate fleet level.");
            Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 0,
                "Unpaid insufficient upgrade must not create negative coins.");
            Require(!PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Provably unpaid insufficient journal should clear safely.");
        }

        private static CargoV2TruckSpec RequireTruck(string id)
        {
            CargoV2TruckSpec truck = CargoV2LogisticsCatalog.GetTruck(id);
            if (truck == null) throw new InvalidOperationException($"Missing canonical truck {id}.");
            return truck;
        }

        private static void SeedStarterCompany() => SeedCompany(0, false);
        private static void SeedTitanCompany(int engineLevel) => SeedCompany(engineLevel, true);

        private static void SeedCompany(int titanEngine, bool ownTitan)
        {
            string titan = ownTitan
                ? ",{\"truckId\":\"titan_x\",\"engineLevel\":" + titanEngine + ",\"handlingLevel\":0,\"durabilityLevel\":0}"
                : string.Empty;
            string selected = ownTitan ? "titan_x" : "atlas_s";
            string raw = "{\"schemaVersion\":1,\"selectedTruckId\":\"" + selected + "\",\"ownedTrucks\":[{\"truckId\":\"atlas_s\",\"engineLevel\":0,\"handlingLevel\":0,\"durabilityLevel\":0}" + titan + "]}";
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyKey, raw);
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyBackupKey, raw);
            PlayerPrefs.Save();
        }

        private static void SeedEconomy(long coins, long xp, string receiptJson)
        {
            string receipts = string.IsNullOrEmpty(receiptJson) ? "[]" : "[" + receiptJson + "]";
            string raw = "{\"schemaVersion\":1,\"coins\":" + coins + ",\"xp\":" + xp + ",\"rewardedMissionIds\":[],\"settledDeliveryIds\":[],\"spendReceipts\":" + receipts + "}";
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey, raw);
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyBackupKey, raw);
            PlayerPrefs.Save();
        }

        private static string Receipt(string op, long cost) =>
            "{\"operationId\":\"" + op + "\",\"amount\":" + cost + "}";

        private static void SeedPurchaseJournal(string op, string truck, long cost)
        {
            PlayerPrefs.SetString(SCR_CompanyProgressStore.PendingTransactionKey,
                "{\"schemaVersion\":1,\"operationId\":\"" + op + "\",\"kind\":1,\"truckId\":\"" + truck + "\",\"upgrade\":-1,\"fromLevel\":0,\"toLevel\":0,\"coinCost\":" + cost + "}");
            PlayerPrefs.Save();
        }

        private static void SeedUpgradeJournal(string op, string truck, CargoV2TruckUpgrade upgrade, int from, int to, long cost)
        {
            PlayerPrefs.SetString(SCR_CompanyProgressStore.PendingTransactionKey,
                "{\"schemaVersion\":1,\"operationId\":\"" + op + "\",\"kind\":2,\"truckId\":\"" + truck + "\",\"upgrade\":" + (int)upgrade + ",\"fromLevel\":" + from + ",\"toLevel\":" + to + ",\"coinCost\":" + cost + "}");
            PlayerPrefs.Save();
        }

        private static void Clear()
        {
            PlayerPrefs.DeleteKey(SCR_MissionRewardStore.EconomyKey);
            PlayerPrefs.DeleteKey(SCR_MissionRewardStore.EconomyBackupKey);
            PlayerPrefs.DeleteKey(SCR_CompanyProgressStore.CompanyKey);
            PlayerPrefs.DeleteKey(SCR_CompanyProgressStore.CompanyBackupKey);
            PlayerPrefs.DeleteKey(SCR_CompanyProgressStore.PendingTransactionKey);
            PlayerPrefs.Save();
        }

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
        }

        private readonly struct StringState
        {
            private readonly bool exists;
            private readonly string value;
            private StringState(bool exists, string value) { this.exists = exists; this.value = value; }
            public static StringState Capture(string key) => new StringState(PlayerPrefs.HasKey(key), PlayerPrefs.GetString(key, string.Empty));
            public void Restore(string key) { if (exists) PlayerPrefs.SetString(key, value); else PlayerPrefs.DeleteKey(key); }
        }
    }
}
#endif
