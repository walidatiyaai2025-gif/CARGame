#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Reflection;
using CargoV2.Data;
using CargoV2.Logic;
using UnityEditor;
using UnityEngine;

namespace CargoV2.QA.EditorTools
{
    public static class SCR_CargoV2HostileStateRegression
    {
        private const string SettingsKey = "cargo_v2_player_settings_v1";

        private static readonly string[] StringKeys =
        {
            SCR_SaveManager.ProgressKey,
            SCR_SaveManager.ProgressBackupKey,
            SCR_SaveManager.CorruptBackupKey,
            SCR_MissionRewardStore.EconomyKey,
            SCR_MissionRewardStore.EconomyBackupKey,
            SCR_MissionRewardStore.CorruptBackupKey,
            SCR_MissionRewardStore.UnsupportedBackupKey,
            SCR_CompanyProgressStore.CompanyKey,
            SCR_CompanyProgressStore.CompanyBackupKey,
            SCR_CompanyProgressStore.CorruptBackupKey,
            SCR_CompanyProgressStore.UnsupportedBackupKey,
            SCR_CompanyProgressStore.PendingTransactionKey,
            SCR_CompanyProgressStore.CorruptTransactionBackupKey,
            SCR_CompanyProgressStore.UnsupportedTransactionBackupKey,
            SCR_ActiveDeliveryStore.ActiveDeliveryKey,
            SCR_ActiveDeliveryStore.CorruptBackupKey,
            SCR_ActiveDeliveryStore.UnsupportedBackupKey,
            SCR_MissionCompletionHandoffBridge.CompletionDeliveryRunKey,
            SCR_MissionCompletionHandoffBridge.ActiveDeliveryRunKey,
            SettingsKey,
        };

        private static readonly string[] IntKeys =
        {
            SCR_MissionCompletionHandoffBridge.CompletionHandoffKey,
            SCR_MissionCompletionHandoffBridge.CompletionStarsKey,
        };

        [MenuItem("CARGO V2/QA/Run Hostile State Reliability Regression")]
        public static void RunMenu()
        {
            ValidateOrThrow();
            Debug.Log("[CARGO V2][QA][EDITMODE][PASS] Hostile-state reliability regression passed.");
        }

        public static void ValidateOrThrow()
        {
            PrefSnapshot snapshot = PrefSnapshot.Capture();
            try
            {
                TestFreshInstall();
                TestProgressHostileSchemas();
                TestEconomyIdempotencyAndCorruption();
                TestCompanySalvageAndFutureSchema();
                TestCommittedTransactionCatalogDrift();
                TestUnpaidTransactionCatalogDrift();
                TestActiveDeliveryValidationAndQuarantine();
                TestCompletionCrashCleanupAndInvalidHandoffIsolation();
                TestFiniteEconomyAndContractMath();
            }
            finally
            {
                ClearScenario();
                snapshot.Restore();
            }
        }

        private static void TestFreshInstall()
        {
            ClearScenario();
            GameObject root = new GameObject("CARGO_V2_Hostile_Fresh");
            try
            {
                SCR_SaveManager save = root.AddComponent<SCR_SaveManager>();
                SCR_SaveManager.ProgressPayload progress = save.LoadProgress(20);
                Require(save.LastLoadState == SCR_SaveManager.ProgressLoadState.Fresh, "Fresh progress must be classified Fresh.");
                Require(progress.highestCompletedMissionId == 0 && progress.selectedMissionId == 1, "Fresh progress defaults must unlock only mission 1.");
                Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy), "Fresh economy must be readable.");
                Require(economy.Coins == 0 && economy.Xp == 0, "Fresh economy must start at zero without a migration grant.");
                Require(SCR_CompanyProgressStore.GetSelectedTruckId() == CargoV2LogisticsCatalog.StarterTruckId, "Fresh company must select starter truck.");
                Require(SCR_CompanyProgressStore.IsOwned(CargoV2LogisticsCatalog.StarterTruckId), "Fresh company must own starter truck.");
                Require(!SCR_ActiveDeliveryStore.HasActiveDelivery, "Fresh install must not invent an active delivery.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(root);
            }
        }

        private static void TestProgressHostileSchemas()
        {
            ClearScenario();
            GameObject root = new GameObject("CARGO_V2_Hostile_Progress");
            try
            {
                SCR_SaveManager save = root.AddComponent<SCR_SaveManager>();
                const string future = "{\"schemaVersion\":99,\"highestCompletedMissionId\":17,\"selectedMissionId\":18}";
                PlayerPrefs.SetString(SCR_SaveManager.ProgressKey, future);
                PlayerPrefs.Save();
                save.LoadProgress(20);
                Require(save.LastLoadState == SCR_SaveManager.ProgressLoadState.FutureSchemaBlocked, "Future progress schema must block.");
                Require(!save.SaveProgress(0, 1, 20), "Future progress schema must refuse write-back.");
                Require(PlayerPrefs.GetString(SCR_SaveManager.ProgressKey) == future, "Future progress raw payload must remain byte-for-byte intact.");

                const string lkg = "{\"schemaVersion\":1,\"highestCompletedMissionId\":5,\"selectedMissionId\":6}";
                const string malformed = "{broken-json";
                PlayerPrefs.SetString(SCR_SaveManager.ProgressBackupKey, lkg);
                PlayerPrefs.SetString(SCR_SaveManager.ProgressKey, malformed);
                PlayerPrefs.Save();
                SCR_SaveManager.ProgressPayload recovered = save.LoadProgress(20);
                Require(save.LastLoadState == SCR_SaveManager.ProgressLoadState.RecoveredBackup, "Malformed progress must recover LKG when present.");
                Require(recovered.highestCompletedMissionId == 5 && recovered.selectedMissionId == 6, "Recovered progress must preserve LKG progression.");
                Require(PlayerPrefs.GetString(SCR_SaveManager.CorruptBackupKey) == malformed, "Malformed progress must be preserved for forensics.");

                PlayerPrefs.DeleteKey(SCR_SaveManager.ProgressBackupKey);
                PlayerPrefs.SetString(SCR_SaveManager.ProgressKey, malformed);
                PlayerPrefs.Save();
                save.LoadProgress(20);
                Require(save.LastLoadState == SCR_SaveManager.ProgressLoadState.CorruptBlocked, "Malformed progress without LKG must block rather than reset.");
                Require(!save.SaveProgress(0, 1, 20), "Blocked malformed progress must not be overwritten with defaults.");
                Require(PlayerPrefs.GetString(SCR_SaveManager.ProgressKey) == malformed, "Blocked malformed progress raw payload must remain intact.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(root);
            }
        }

        private static void TestEconomyIdempotencyAndCorruption()
        {
            ClearScenario();
            SO_GameBalance balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            try
            {
                balance.ResetToApprovedDefaults();
                SO_GameBalance.MissionBalance mission = balance.GetMission(1);
                Require(mission != null, "Mission 1 balance must exist.");

                string run1 = Guid.NewGuid().ToString("N");
                string run2 = Guid.NewGuid().ToString("N");
                Require(SCR_MissionRewardStore.TrySettleDelivery(mission, 1, run1, out bool granted1, out SCR_MissionRewardStore.Snapshot after1) && granted1,
                    "First modern delivery run must settle once.");
                Require(SCR_MissionRewardStore.TrySettleDelivery(mission, 1, run1, out bool grantedDuplicate, out SCR_MissionRewardStore.Snapshot duplicate) && !grantedDuplicate,
                    "Exact delivery run replay must be idempotent.");
                Require(duplicate.Coins == after1.Coins && duplicate.Xp == after1.Xp, "Duplicate delivery run must not change totals.");
                Require(SCR_MissionRewardStore.TrySettleDelivery(mission, 1, run2, out bool granted2, out SCR_MissionRewardStore.Snapshot after2) && granted2,
                    "A new delivery run of the same contract must remain repeatably earnable.");
                Require(after2.Coins > after1.Coins && after2.Xp > after1.Xp, "Repeatable contract must increase earnings for a distinct run id.");
                Require(SCR_MissionRewardStore.TrySettleMission(mission, 1, out bool legacyGranted, out SCR_MissionRewardStore.Snapshot afterLegacy) && !legacyGranted,
                    "Legacy one-time handoff after modern settlement must not re-award migration reward.");
                Require(afterLegacy.Coins == after2.Coins && afterLegacy.Xp == after2.Xp, "Legacy replay must not alter modern totals.");

                string delivery = Guid.NewGuid().ToString("N");
                string spend = Guid.NewGuid().ToString("N");
                string repairable = "{\"schemaVersion\":1,\"coins\":1234,\"xp\":77,\"rewardedMissionIds\":[1,1,99],\"settledDeliveryIds\":[\"" + delivery + "\",\"" + delivery + "\"],\"spendReceipts\":[{\"operationId\":\"" + spend + "\",\"amount\":50},{\"operationId\":\"" + spend + "\",\"amount\":50}]}";
                PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey, repairable);
                PlayerPrefs.Save();
                Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot normalized), "Repairable duplicate economy IDs must normalize instead of deleting the ledger.");
                Require(normalized.Coins == 1234 && normalized.Xp == 77, "Economy normalization must preserve coins and XP.");
                Require(PlayerPrefs.GetString(SCR_MissionRewardStore.CorruptBackupKey) == repairable, "Repairable economy source must be preserved before normalization.");

                string conflicting = "{\"schemaVersion\":1,\"coins\":1234,\"xp\":77,\"rewardedMissionIds\":[],\"settledDeliveryIds\":[],\"spendReceipts\":[{\"operationId\":\"" + spend + "\",\"amount\":50},{\"operationId\":\"" + spend + "\",\"amount\":60}]}";
                PlayerPrefs.DeleteKey(SCR_MissionRewardStore.EconomyBackupKey);
                PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey, conflicting);
                PlayerPrefs.Save();
                Require(!SCR_MissionRewardStore.TryReadSnapshot(out _), "Conflicting duplicate spend receipts must fail closed without an LKG.");
                Require(PlayerPrefs.GetString(SCR_MissionRewardStore.EconomyKey) == conflicting, "Conflicting economy primary must not be zero-reset.");

                string overflow = "{\"schemaVersion\":1,\"coins\":" + long.MaxValue + ",\"xp\":0,\"rewardedMissionIds\":[],\"settledDeliveryIds\":[],\"spendReceipts\":[]}";
                PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey, overflow);
                PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyBackupKey, overflow);
                PlayerPrefs.Save();
                string overflowRun = Guid.NewGuid().ToString("N");
                Require(!SCR_MissionRewardStore.TrySettleDelivery(mission, 1, overflowRun, out _, out _), "Reward overflow must fail without wrapping.");
                Require(PlayerPrefs.GetString(SCR_MissionRewardStore.EconomyKey) == overflow, "Overflow failure must not mutate persisted totals.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(balance);
            }
        }

        private static void TestCompanySalvageAndFutureSchema()
        {
            ClearScenario();
            const string hostile = "{\"schemaVersion\":1,\"selectedTruckId\":\"ghost\",\"ownedTrucks\":[{\"truckId\":\"titan_x\",\"engineLevel\":1,\"handlingLevel\":2,\"durabilityLevel\":0},{\"truckId\":\"titan_x\",\"engineLevel\":99,\"handlingLevel\":-5,\"durabilityLevel\":3},{\"truckId\":\"ghost\",\"engineLevel\":3,\"handlingLevel\":3,\"durabilityLevel\":3}]}";
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyKey, hostile);
            PlayerPrefs.Save();

            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == CargoV2LogisticsCatalog.StarterTruckId, "Invalid selected truck must recover to owned starter.");
            Require(SCR_CompanyProgressStore.IsOwned("titan_x"), "Valid fleet ownership must survive neighboring corrupt records.");
            Require(SCR_CompanyProgressStore.TryGetTruckState("titan_x", out SCR_CompanyProgressStore.TruckState titan), "Salvaged TITAN state must remain readable.");
            Require(titan.EngineLevel == 3 && titan.HandlingLevel == 2 && titan.DurabilityLevel == 3, "Duplicate truck records must merge conservatively using clamped maximum upgrades.");
            Require(PlayerPrefs.GetString(SCR_CompanyProgressStore.CorruptBackupKey) == hostile, "Original hostile company payload must be preserved before salvage.");

            const string future = "{\"schemaVersion\":77,\"selectedTruckId\":\"titan_x\",\"ownedTrucks\":[]}";
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyKey, future);
            PlayerPrefs.Save();
            Require(SCR_CompanyProgressStore.GetSelectedTruckId() == CargoV2LogisticsCatalog.StarterTruckId, "Unsupported company schema must expose safe runtime fallback only.");
            Require(PlayerPrefs.GetString(SCR_CompanyProgressStore.CompanyKey) == future, "Unsupported company schema primary must remain untouched.");
            Require(PlayerPrefs.GetString(SCR_CompanyProgressStore.UnsupportedBackupKey) == future, "Unsupported company schema must be preserved separately.");
        }

        private static void TestCommittedTransactionCatalogDrift()
        {
            ClearScenario();
            CargoV2TruckSpec titan = CargoV2LogisticsCatalog.GetTruck("titan_x");
            Require(titan != null && titan.purchasePrice > 0, "TITAN catalog record must exist.");
            long recordedCost = titan.purchasePrice;
            string op = Guid.NewGuid().ToString("N");

            SeedCompanyStarter();
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey,
                EconomyJson(800, 1000, "[],", "[],", "[{\"operationId\":\"" + op + "\",\"amount\":" + recordedCost + "}]"));
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyBackupKey,
                EconomyJson(800, 1000, "[],", "[],", "[{\"operationId\":\"" + op + "\",\"amount\":" + recordedCost + "}]"));
            PlayerPrefs.SetString(SCR_CompanyProgressStore.PendingTransactionKey,
                PurchaseJournal(op, "titan_x", recordedCost));
            PlayerPrefs.Save();

            long original = titan.purchasePrice;
            try
            {
                titan.purchasePrice = original + 777;
                Require(SCR_CompanyProgressStore.GetSelectedTruckId() == "titan_x", "Committed purchase must finish recorded intent even after catalog price drift.");
                Require(SCR_CompanyProgressStore.IsOwned("titan_x"), "Committed purchase recovery must restore ownership.");
                Require(!PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Recovered committed purchase journal must clear.");
                Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy) && economy.Coins == 800,
                    "Committed purchase recovery must not debit a second time.");
            }
            finally
            {
                titan.purchasePrice = original;
            }
        }

        private static void TestUnpaidTransactionCatalogDrift()
        {
            ClearScenario();
            CargoV2TruckSpec titan = CargoV2LogisticsCatalog.GetTruck("titan_x");
            Require(titan != null && titan.purchasePrice > 0, "TITAN catalog record must exist.");
            long recordedCost = titan.purchasePrice;
            string op = Guid.NewGuid().ToString("N");

            SeedCompanyStarter();
            string economy = EconomyJson(5000, 1000, "[],", "[],", "[]");
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyKey, economy);
            PlayerPrefs.SetString(SCR_MissionRewardStore.EconomyBackupKey, economy);
            PlayerPrefs.SetString(SCR_CompanyProgressStore.PendingTransactionKey,
                PurchaseJournal(op, "titan_x", recordedCost));
            PlayerPrefs.Save();

            long original = titan.purchasePrice;
            try
            {
                titan.purchasePrice = original + 777;
                Require(SCR_CompanyProgressStore.GetSelectedTruckId() == CargoV2LogisticsCatalog.StarterTruckId,
                    "Unpaid journal with catalog drift must not apply a stale purchase.");
                Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot after) && after.Coins == 5000,
                    "Unpaid catalog-drift recovery must not debit coins.");
                Require(PlayerPrefs.HasKey(SCR_CompanyProgressStore.PendingTransactionKey), "Unpaid conflicting journal must remain for deterministic recovery/investigation.");
            }
            finally
            {
                titan.purchasePrice = original;
            }
        }

        private static void TestActiveDeliveryValidationAndQuarantine()
        {
            ClearScenario();
            Vector3 origin = new Vector3(1000f, 0.7f, 1002f);
            Require(SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId, origin, 0f, 100f, 0f, false, 0),
                "Valid pre-pickup delivery must save.");
            Require(SCR_ActiveDeliveryStore.TryLoad(1, out SCR_ActiveDeliveryStore.Snapshot valid) && valid.CheckpointIndex == 0 && !valid.CargoLoaded,
                "Valid active delivery must round-trip.");
            Require(!SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId, origin, 0f, -1f, 0f, false, 0),
                "Negative remaining time must be rejected, not clamped.");
            Require(!SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId, origin, 0f, 100f, 101f, true, 1),
                "Damage above 100 must be rejected, not clamped.");
            Require(!SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId, new Vector3(float.NaN, 0f, 0f), 0f, 100f, 0f, false, 0),
                "NaN active position must be rejected.");
            Require(!SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId, origin, 0f, 100f, 0f, false, 2),
                "Checkpoint progress without cargo must be rejected.");

            string impossible = "{\"schemaVersion\":1,\"missionId\":1,\"truckId\":\"atlas_s\",\"x\":1000,\"y\":0.7,\"z\":1060,\"yaw\":0,\"remainingSeconds\":100,\"damage\":0,\"cargoLoaded\":false,\"checkpointIndex\":2,\"savedUtcTicks\":1}";
            PlayerPrefs.SetString(SCR_ActiveDeliveryStore.ActiveDeliveryKey, impossible);
            PlayerPrefs.Save();
            Require(!SCR_ActiveDeliveryStore.TryLoadAny(out _), "Impossible active run must not resume.");
            Require(!PlayerPrefs.HasKey(SCR_ActiveDeliveryStore.ActiveDeliveryKey), "Impossible active run must be removed from live resume state.");
            Require(PlayerPrefs.GetString(SCR_ActiveDeliveryStore.CorruptBackupKey) == impossible, "Impossible active run must be quarantined, not destroyed.");

            string future = "{\"schemaVersion\":9,\"missionId\":1}";
            PlayerPrefs.SetString(SCR_ActiveDeliveryStore.ActiveDeliveryKey, future);
            PlayerPrefs.Save();
            Require(!SCR_ActiveDeliveryStore.TryLoadAny(out _), "Future active-delivery schema must not be interpreted by old code.");
            Require(PlayerPrefs.GetString(SCR_ActiveDeliveryStore.UnsupportedBackupKey) == future, "Future active run raw data must be preserved.");
        }

        private static void TestCompletionCrashCleanupAndInvalidHandoffIsolation()
        {
            ClearScenario();
            GameObject root = new GameObject("CARGO_V2_Hostile_Completion");
            try
            {
                SCR_SaveManager save = root.AddComponent<SCR_SaveManager>();
                SCR_WorldMapRouteController route = root.AddComponent<SCR_WorldMapRouteController>();
                SCR_MissionCompletionHandoffBridge completion = root.AddComponent<SCR_MissionCompletionHandoffBridge>();
                Require(save.SaveProgress(0, 1, route.MissionCount), "Completion scenario progress seed must save.");

                string run = Guid.NewGuid().ToString("N");
                Require(SCR_ActiveDeliveryStore.TrySave(1, CargoV2LogisticsCatalog.StarterTruckId,
                    new Vector3(1000f, 0.7f, 1002f), 0f, 100f, 0f, true, 3),
                    "Completion crash scenario active snapshot must save.");
                PlayerPrefs.SetString(SCR_MissionCompletionHandoffBridge.ActiveDeliveryRunKey, run);
                PlayerPrefs.SetInt(SCR_MissionCompletionHandoffBridge.CompletionHandoffKey, 1);
                PlayerPrefs.SetInt(SCR_MissionCompletionHandoffBridge.CompletionStarsKey, 1);
                PlayerPrefs.SetString(SCR_MissionCompletionHandoffBridge.CompletionDeliveryRunKey, run);
                PlayerPrefs.Save();

                Require(InvokeConsume(completion), "Crash-recovered valid completion handoff must settle.");
                Require(!SCR_ActiveDeliveryStore.HasActiveDelivery, "Successful recovered settlement must clear stale active-delivery snapshot.");
                Require(!PlayerPrefs.HasKey(SCR_MissionCompletionHandoffBridge.ActiveDeliveryRunKey), "Successful recovered settlement must retire active run identity.");
                Require(SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot firstEconomy) && firstEconomy.Coins > 0,
                    "Recovered completion must persist its reward.");

                // Invalid completion metadata must never destroy a separate resumable delivery identity.
                string validRun = Guid.NewGuid().ToString("N");
                Require(SCR_ActiveDeliveryStore.TrySave(2, CargoV2LogisticsCatalog.StarterTruckId,
                    new Vector3(1000f, 0.7f, 1002f), 0f, 100f, 0f, false, 0),
                    "Independent active delivery must save before invalid handoff test.");
                PlayerPrefs.SetString(SCR_MissionCompletionHandoffBridge.ActiveDeliveryRunKey, validRun);
                PlayerPrefs.SetInt(SCR_MissionCompletionHandoffBridge.CompletionHandoffKey, 99);
                PlayerPrefs.SetString(SCR_MissionCompletionHandoffBridge.CompletionDeliveryRunKey, Guid.NewGuid().ToString("N"));
                PlayerPrefs.Save();
                Require(!InvokeConsume(completion), "Out-of-range completion handoff must be rejected.");
                Require(PlayerPrefs.GetString(SCR_MissionCompletionHandoffBridge.ActiveDeliveryRunKey) == validRun,
                    "Rejected completion handoff must preserve unrelated active-delivery identity.");
                Require(SCR_ActiveDeliveryStore.HasActiveDelivery, "Rejected completion handoff must not delete unrelated active-delivery snapshot.");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(root);
            }
        }

        private static void TestFiniteEconomyAndContractMath()
        {
            SO_GameBalance balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            try
            {
                balance.ResetToApprovedDefaults();
                Require(CargoV2LogisticsCatalog.Validate(out string error), "Canonical logistics catalog must validate: " + error);
                foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
                {
                    Require(truck != null && truck.cargoCapacityTons > 0f && Finite(truck.cargoCapacityTons), "Truck capacity must be finite and positive.");
                    int[] levels = { -100, 0, 1, 3, 100 };
                    for (int i = 0; i < levels.Length; i++)
                    {
                        CargoV2TruckRuntimeStats stats = CargoV2LogisticsCatalog.GetRuntimeStats(truck, levels[i], levels[i], levels[i]);
                        Require(Finite(stats.TopSpeedMetersPerSecond) && stats.TopSpeedMetersPerSecond > 0f, "Runtime top speed must stay finite/positive.");
                        Require(Finite(stats.AccelerationMetersPerSecondSquared) && stats.AccelerationMetersPerSecondSquared > 0f, "Runtime acceleration must stay finite/positive.");
                        Require(Finite(stats.SteeringDegreesPerSecond) && stats.SteeringDegreesPerSecond > 0f, "Runtime steering must stay finite/positive.");
                        Require(Finite(stats.CargoCapacityTons) && stats.CargoCapacityTons > 0f, "Runtime capacity must stay finite/positive.");
                        Require(Finite(stats.Durability) && stats.Durability > 0f, "Runtime durability must stay finite/positive.");
                    }
                }

                Require(balance.missions != null && balance.missions.Count == 20, "Canonical mission count must remain 20.");
                for (int i = 0; i < balance.missions.Count; i++)
                {
                    SO_GameBalance.MissionBalance mission = balance.missions[i];
                    CargoV2ContractSpec contract = CargoV2LogisticsCatalog.BuildContract(mission);
                    Require(contract != null && Finite(contract.cargoWeightTons) && contract.cargoWeightTons > 0f,
                        "Every contract cargo weight must be finite/positive.");
                    Require(contract.timeSeconds > 0 && contract.distanceKm > 0, "Every contract must have positive time/distance.");
                    Require(CargoV2LogisticsCatalog.GetTruck(contract.recommendedTruckId) != null, "Every contract must resolve a recommended truck.");
                    bool capable = false;
                    foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
                    {
                        if (truck.cargoCapacityTons >= contract.cargoWeightTons) { capable = true; break; }
                    }
                    Require(capable, "Every contract must have at least one physically capable truck.");
                }
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(balance);
            }
        }

        private static bool InvokeConsume(SCR_MissionCompletionHandoffBridge completion)
        {
            MethodInfo consume = typeof(SCR_MissionCompletionHandoffBridge).GetMethod(
                "ConsumePendingHandoff", BindingFlags.Instance | BindingFlags.NonPublic);
            if (consume == null) throw new MissingMethodException("ConsumePendingHandoff");
            object result = consume.Invoke(completion, null);
            return result is bool accepted && accepted;
        }

        private static void SeedCompanyStarter()
        {
            string raw = "{\"schemaVersion\":1,\"selectedTruckId\":\"atlas_s\",\"ownedTrucks\":[{\"truckId\":\"atlas_s\",\"engineLevel\":0,\"handlingLevel\":0,\"durabilityLevel\":0}]}";
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyKey, raw);
            PlayerPrefs.SetString(SCR_CompanyProgressStore.CompanyBackupKey, raw);
        }

        private static string PurchaseJournal(string operationId, string truckId, long cost)
        {
            return "{\"schemaVersion\":1,\"operationId\":\"" + operationId + "\",\"kind\":1,\"truckId\":\"" + truckId + "\",\"upgrade\":-1,\"fromLevel\":0,\"toLevel\":0,\"coinCost\":" + cost + "}";
        }

        private static string EconomyJson(long coins, long xp, string rewarded, string deliveries, string receipts)
        {
            return "{\"schemaVersion\":1,\"coins\":" + coins + ",\"xp\":" + xp + ",\"rewardedMissionIds\":" + rewarded + "\"settledDeliveryIds\":" + deliveries + "\"spendReceipts\":" + receipts + "}";
        }

        private static bool Finite(float value) => !float.IsNaN(value) && !float.IsInfinity(value);

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message);
        }

        private static void ClearScenario()
        {
            for (int i = 0; i < StringKeys.Length; i++) PlayerPrefs.DeleteKey(StringKeys[i]);
            for (int i = 0; i < IntKeys.Length; i++) PlayerPrefs.DeleteKey(IntKeys[i]);
            PlayerPrefs.Save();
        }

        private sealed class PrefSnapshot
        {
            private readonly Dictionary<string, StringState> strings = new Dictionary<string, StringState>(StringComparer.Ordinal);
            private readonly Dictionary<string, IntState> ints = new Dictionary<string, IntState>(StringComparer.Ordinal);

            public static PrefSnapshot Capture()
            {
                var snapshot = new PrefSnapshot();
                for (int i = 0; i < StringKeys.Length; i++) snapshot.strings[StringKeys[i]] = StringState.Capture(StringKeys[i]);
                for (int i = 0; i < IntKeys.Length; i++) snapshot.ints[IntKeys[i]] = IntState.Capture(IntKeys[i]);
                return snapshot;
            }

            public void Restore()
            {
                foreach (KeyValuePair<string, StringState> pair in strings) pair.Value.Restore(pair.Key);
                foreach (KeyValuePair<string, IntState> pair in ints) pair.Value.Restore(pair.Key);
                PlayerPrefs.Save();
            }
        }

        private readonly struct StringState
        {
            private readonly bool exists;
            private readonly string value;
            private StringState(bool exists, string value) { this.exists = exists; this.value = value; }
            public static StringState Capture(string key) => new StringState(PlayerPrefs.HasKey(key), PlayerPrefs.GetString(key, string.Empty));
            public void Restore(string key) { if (exists) PlayerPrefs.SetString(key, value); else PlayerPrefs.DeleteKey(key); }
        }

        private readonly struct IntState
        {
            private readonly bool exists;
            private readonly int value;
            private IntState(bool exists, int value) { this.exists = exists; this.value = value; }
            public static IntState Capture(string key) => new IntState(PlayerPrefs.HasKey(key), PlayerPrefs.GetInt(key, 0));
            public void Restore(string key) { if (exists) PlayerPrefs.SetInt(key, value); else PlayerPrefs.DeleteKey(key); }
        }
    }
}
#endif
