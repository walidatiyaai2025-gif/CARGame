#if UNITY_EDITOR
using CargoV2.Data;
using CargoV2.Logic;
using CargoV2.UI;
using UnityEditor;
using UnityEngine;

namespace CargoV2.QA.Editor
{
    public static class SCR_CargoV2LogisticsReadiness
    {
        private const string TruckResourcePath = "CargoV2/Truck/MOD_Truck_Premium";

        [MenuItem("CARGO V2/QA/Report Logistics Closure Readiness")]
        public static void Report()
        {
            int pass = 0;
            int hold = 0;

            bool catalogValid = CargoV2LogisticsCatalog.Validate(out string catalogError);
            Record(catalogValid, catalogValid ? "Logistics catalog validates." : $"Logistics catalog invalid: {catalogError}", ref pass, ref hold);
            Record(Resources.Load<GameObject>(TruckResourcePath) != null,
                $"Premium truck Resources asset resolves: {TruckResourcePath}", ref pass, ref hold);
            Record(typeof(SCR_CompanyProgressStore) != null, "Company/fleet persistence contract compiles.", ref pass, ref hold);
            Record(typeof(SCR_ActiveDeliveryStore) != null, "Active-delivery recovery contract compiles.", ref pass, ref hold);
            Record(typeof(SCR_LogisticsBusinessRuntime) != null, "Logistics HQ runtime contract compiles.", ref pass, ref hold);
            Record(typeof(SCR_MissionRuntimeDirector) != null, "Driving mission runtime contract compiles.", ref pass, ref hold);

            SO_GameBalance balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            try
            {
                balance.ResetToApprovedDefaults();
                Record(balance.missions != null && balance.missions.Count == 20,
                    "Authoritative game balance exposes exactly 20 launch missions.", ref pass, ref hold);

                if (balance.missions != null)
                {
                    for (int i = 0; i < balance.missions.Count; i++)
                    {
                        SO_GameBalance.MissionBalance mission = balance.missions[i];
                        CargoV2ContractSpec contract = CargoV2LogisticsCatalog.BuildContract(mission);
                        bool valid = contract != null &&
                                     contract.missionId == mission.missionId &&
                                     !string.IsNullOrWhiteSpace(contract.origin) &&
                                     !string.IsNullOrWhiteSpace(contract.destination) &&
                                     !string.IsNullOrWhiteSpace(contract.cargoLabel) &&
                                     contract.cargoWeightTons > 0f &&
                                     contract.distanceKm > 0 &&
                                     contract.timeSeconds > 0 &&
                                     CargoV2LogisticsCatalog.GetTruck(contract.recommendedTruckId) != null;
                        Record(valid, $"Mission {mission.missionId:00} maps to a valid trucking contract.", ref pass, ref hold);
                    }
                }

                ValidateProgressionFeasibility(balance, ref pass, ref hold);
            }
            finally
            {
                Object.DestroyImmediate(balance);
            }

            string verdict = hold == 0 ? "STRUCTURAL READY" : "HOLD";
            Debug.Log($"[CARGO V2][QA] LOGISTICS CLOSURE READINESS — {verdict}; PASS={pass}, HOLD={hold}. This proves source/import contracts only and is NOT Unity Play Mode, visual, physics-feel, FPS, device, or release-build acceptance.");
        }

        private static void ValidateProgressionFeasibility(SO_GameBalance balance, ref int pass, ref int hold)
        {
            long cumulativeCoins = 0;
            long cumulativeXp = 0;
            bool titanReachable = false;
            bool mammothReachable = false;
            bool falconReachable = false;

            for (int i = 0; i < balance.missions.Count; i++)
            {
                SO_GameBalance.MissionBalance mission = balance.missions[i];
                cumulativeCoins += Mathf.Max(0, mission.coin1Star);
                cumulativeXp += Mathf.Max(0, mission.xp);

                foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
                {
                    if (string.Equals(truck.id, CargoV2LogisticsCatalog.StarterTruckId, System.StringComparison.Ordinal)) continue;
                    bool reachable = cumulativeCoins >= truck.purchasePrice && cumulativeXp >= truck.unlockXp;
                    if (truck.id == "titan_x") titanReachable |= reachable;
                    if (truck.id == "mammoth_6x4") mammothReachable |= reachable;
                    if (truck.id == "falcon_e") falconReachable |= reachable;
                }
            }

            Record(titanReachable, "TITAN X becomes reachable through mission rewards without external purchases.", ref pass, ref hold);
            Record(mammothReachable, "MAMMOTH 6x4 becomes reachable through mission rewards without external purchases.", ref pass, ref hold);
            Record(falconReachable, "FALCON E becomes reachable through mission rewards without external purchases.", ref pass, ref hold);

            bool everyContractHasCapableTruck = true;
            for (int i = 0; i < balance.missions.Count; i++)
            {
                CargoV2ContractSpec contract = CargoV2LogisticsCatalog.BuildContract(balance.missions[i]);
                bool capable = false;
                foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
                {
                    if (truck.cargoCapacityTons >= contract.cargoWeightTons)
                    {
                        capable = true;
                        break;
                    }
                }
                everyContractHasCapableTruck &= capable;
            }
            Record(everyContractHasCapableTruck, "Every launch contract has at least one capable fleet truck.", ref pass, ref hold);
        }

        private static void Record(bool ok, string message, ref int pass, ref int hold)
        {
            if (ok)
            {
                pass++;
                Debug.Log($"[CARGO V2][QA][PASS] {message}");
            }
            else
            {
                hold++;
                Debug.LogWarning($"[CARGO V2][QA][HOLD] {message}");
            }
        }
    }
}
#endif
