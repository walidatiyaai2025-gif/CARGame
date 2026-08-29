using System;
using System.Collections.Generic;

namespace CargoV2.Data
{
    public enum CargoV2CargoClass
    {
        General = 0,
        Food = 1,
        Electronics = 2,
        Machinery = 3,
        Medical = 4,
        Container = 5,
    }

    public enum CargoV2TruckUpgrade
    {
        Engine = 0,
        Handling = 1,
        Durability = 2,
    }

    [Serializable]
    public sealed class CargoV2TruckSpec
    {
        public string id;
        public string displayName;
        public long purchasePrice;
        public long unlockXp;
        public float topSpeedMetersPerSecond;
        public float accelerationMetersPerSecondSquared;
        public float steeringDegreesPerSecond;
        public float cargoCapacityTons;
        public float durability;
        public long baseUpgradeCost;
    }

    [Serializable]
    public sealed class CargoV2ContractSpec
    {
        public int missionId;
        public string origin;
        public string destination;
        public string cargoLabel;
        public CargoV2CargoClass cargoClass;
        public float cargoWeightTons;
        public int distanceKm;
        public int timeSeconds;
        public int payoutCoins;
        public int bonusCoins;
        public int xp;
        public string recommendedTruckId;
    }

    public readonly struct CargoV2TruckRuntimeStats
    {
        public CargoV2TruckRuntimeStats(
            string id,
            string displayName,
            float topSpeed,
            float acceleration,
            float steering,
            float capacity,
            float durability)
        {
            Id = id;
            DisplayName = displayName;
            TopSpeedMetersPerSecond = topSpeed;
            AccelerationMetersPerSecondSquared = acceleration;
            SteeringDegreesPerSecond = steering;
            CargoCapacityTons = capacity;
            Durability = durability;
        }

        public string Id { get; }
        public string DisplayName { get; }
        public float TopSpeedMetersPerSecond { get; }
        public float AccelerationMetersPerSecondSquared { get; }
        public float SteeringDegreesPerSecond { get; }
        public float CargoCapacityTons { get; }
        public float Durability { get; }
    }

    public static class CargoV2LogisticsCatalog
    {
        public const string StarterTruckId = "atlas_s";

        private static readonly CargoV2TruckSpec[] Trucks =
        {
            Truck("atlas_s", "ATLAS S", 0, 0, 12.5f, 5.8f, 72f, 8f, 1.00f, 350),
            Truck("titan_x", "TITAN X", 1200, 100, 14.0f, 6.6f, 68f, 14f, 1.12f, 600),
            Truck("mammoth_6x4", "MAMMOTH 6x4", 3000, 350, 13.2f, 5.4f, 60f, 22f, 1.38f, 900),
            Truck("falcon_e", "FALCON E", 6500, 650, 16.0f, 7.5f, 78f, 12f, 1.08f, 1250),
        };

        private static readonly IReadOnlyList<CargoV2TruckSpec> ReadOnlyTrucks =
            Array.AsReadOnly(Trucks);

        private static readonly string[] CairoDestinations =
        {
            "Giza Distribution Yard",
            "Nasr City Freight Hub",
            "New Cairo Logistics Park",
            "Cairo Airport Cargo",
            "Helwan Industrial Depot",
            "6th October Warehouse",
            "Obour Food Terminal",
            "Ain Sokhna Connector",
            "Alexandria Inland Link",
            "Cairo International Depot",
        };

        private static readonly string[] DubaiDestinations =
        {
            "Jebel Ali Container Yard",
            "Dubai South Logistics District",
            "Al Quoz Freight Terminal",
            "DXB Cargo Village",
            "Ras Al Khor Depot",
            "Dubai Industrial City",
            "Port Rashid Connector",
            "Dubai Investment Park",
            "JAFZA Heavy Cargo Gate",
            "Gulf International Depot",
        };

        private static readonly string[] CargoLabels =
        {
            "General Freight",
            "Fresh Produce",
            "Electronics",
            "Industrial Machinery",
            "Medical Supplies",
            "Blue Container",
        };

        private static readonly CargoV2CargoClass[] CargoClasses =
        {
            CargoV2CargoClass.General,
            CargoV2CargoClass.Food,
            CargoV2CargoClass.Electronics,
            CargoV2CargoClass.Machinery,
            CargoV2CargoClass.Medical,
            CargoV2CargoClass.Container,
        };

        public static IReadOnlyList<CargoV2TruckSpec> AllTrucks => ReadOnlyTrucks;

        public static CargoV2TruckSpec GetTruck(string truckId)
        {
            if (string.IsNullOrEmpty(truckId)) return null;
            for (int i = 0; i < Trucks.Length; i++)
            {
                if (string.Equals(Trucks[i].id, truckId, StringComparison.Ordinal))
                {
                    return Trucks[i];
                }
            }
            return null;
        }

        public static CargoV2ContractSpec BuildContract(SO_GameBalance.MissionBalance mission)
        {
            if (mission == null || mission.missionId < 1 || mission.missionId > 20)
            {
                return null;
            }

            int routeIndex = (mission.missionId - 1) % 10;
            bool cairo = mission.missionId <= 10;
            int cargoIndex = (mission.missionId - 1) % CargoLabels.Length;
            float weight = 3.5f + (routeIndex * 1.15f) + (cairo ? 0f : 1.4f);
            int distance = 24 + routeIndex * 19 + (cairo ? 0 : 34);
            string recommendedTruck = weight > 16f
                ? "mammoth_6x4"
                : weight > 10f
                    ? "titan_x"
                    : StarterTruckId;

            return new CargoV2ContractSpec
            {
                missionId = mission.missionId,
                origin = cairo ? "Cairo Logistics Hub" : "Dubai Logistics Hub",
                destination = cairo ? CairoDestinations[routeIndex] : DubaiDestinations[routeIndex],
                cargoLabel = CargoLabels[cargoIndex],
                cargoClass = CargoClasses[cargoIndex],
                cargoWeightTons = weight,
                distanceKm = distance,
                timeSeconds = mission.timeSeconds,
                payoutCoins = mission.coin1Star,
                bonusCoins = Math.Max(0, mission.coin3Star - mission.coin1Star),
                xp = mission.xp,
                recommendedTruckId = recommendedTruck,
            };
        }

        public static int GetCompanyRank(long xp)
        {
            if (xp >= 650) return 4;
            if (xp >= 350) return 3;
            if (xp >= 100) return 2;
            return 1;
        }

        public static long GetUpgradeCost(CargoV2TruckSpec truck, CargoV2TruckUpgrade upgrade, int currentLevel)
        {
            if (truck == null || currentLevel < 0 || currentLevel >= 3) return -1;
            float typeMultiplier = upgrade == CargoV2TruckUpgrade.Engine
                ? 1.15f
                : upgrade == CargoV2TruckUpgrade.Durability
                    ? 1.05f
                    : 1.00f;
            double scaled = truck.baseUpgradeCost * typeMultiplier * (1.0 + currentLevel * 0.85);
            return Math.Max(1L, (long)Math.Round(scaled, MidpointRounding.AwayFromZero));
        }

        public static CargoV2TruckRuntimeStats GetRuntimeStats(
            CargoV2TruckSpec truck,
            int engineLevel,
            int handlingLevel,
            int durabilityLevel)
        {
            if (truck == null)
            {
                truck = GetTruck(StarterTruckId);
            }

            engineLevel = ClampUpgrade(engineLevel);
            handlingLevel = ClampUpgrade(handlingLevel);
            durabilityLevel = ClampUpgrade(durabilityLevel);
            return new CargoV2TruckRuntimeStats(
                truck.id,
                truck.displayName,
                truck.topSpeedMetersPerSecond * (1f + engineLevel * 0.055f),
                truck.accelerationMetersPerSecondSquared * (1f + engineLevel * 0.08f),
                truck.steeringDegreesPerSecond * (1f + handlingLevel * 0.07f),
                truck.cargoCapacityTons,
                truck.durability * (1f + durabilityLevel * 0.10f));
        }

        public static bool CanTruckCarry(string truckId, CargoV2ContractSpec contract)
        {
            CargoV2TruckSpec truck = GetTruck(truckId);
            return truck != null && contract != null && truck.cargoCapacityTons >= contract.cargoWeightTons;
        }

        public static bool Validate(out string error)
        {
            var ids = new HashSet<string>(StringComparer.Ordinal);
            for (int i = 0; i < Trucks.Length; i++)
            {
                CargoV2TruckSpec truck = Trucks[i];
                if (truck == null || string.IsNullOrWhiteSpace(truck.id) || !ids.Add(truck.id))
                {
                    error = "truck ids must be unique and non-empty";
                    return false;
                }

                if (truck.purchasePrice < 0 || truck.unlockXp < 0 || truck.topSpeedMetersPerSecond <= 0f ||
                    truck.accelerationMetersPerSecondSquared <= 0f || truck.steeringDegreesPerSecond <= 0f ||
                    truck.cargoCapacityTons <= 0f || truck.durability <= 0f || truck.baseUpgradeCost <= 0)
                {
                    error = $"truck {truck.id} has invalid balance values";
                    return false;
                }
            }

            if (GetTruck(StarterTruckId) == null)
            {
                error = "starter truck is missing";
                return false;
            }

            for (int missionId = 1; missionId <= 20; missionId++)
            {
                var mission = new SO_GameBalance.MissionBalance
                {
                    missionId = missionId,
                    city = missionId <= 10 ? "Cairo" : "Dubai",
                    timeSeconds = 30,
                    coin1Star = 100,
                    coin3Star = 200,
                    xp = 20,
                };
                CargoV2ContractSpec contract = BuildContract(mission);
                if (contract == null || contract.missionId != missionId || string.IsNullOrWhiteSpace(contract.destination) ||
                    contract.cargoWeightTons <= 0f || contract.distanceKm <= 0 || contract.timeSeconds <= 0 ||
                    GetTruck(contract.recommendedTruckId) == null)
                {
                    error = $"mission {missionId} does not map to a valid logistics contract";
                    return false;
                }
            }

            error = string.Empty;
            return true;
        }

        private static CargoV2TruckSpec Truck(
            string id,
            string name,
            long price,
            long unlockXp,
            float speed,
            float acceleration,
            float steering,
            float capacity,
            float durability,
            long upgradeCost)
        {
            return new CargoV2TruckSpec
            {
                id = id,
                displayName = name,
                purchasePrice = price,
                unlockXp = unlockXp,
                topSpeedMetersPerSecond = speed,
                accelerationMetersPerSecondSquared = acceleration,
                steeringDegreesPerSecond = steering,
                cargoCapacityTons = capacity,
                durability = durability,
                baseUpgradeCost = upgradeCost,
            };
        }

        private static int ClampUpgrade(int level)
        {
            if (level < 0) return 0;
            return level > 3 ? 3 : level;
        }
    }
}
