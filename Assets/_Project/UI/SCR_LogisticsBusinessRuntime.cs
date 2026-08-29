using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_LogisticsBusinessRuntime : MonoBehaviour
    {
        private const float PanelWidth = 430f;
        private const float PanelHeight = 620f;
        private static SCR_LogisticsBusinessRuntime instance;

        private bool expanded;
        private Vector2 fleetScroll;
        private string status = string.Empty;
        private float statusUntil;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Install()
        {
            if (instance != null) return;
            GameObject host = new GameObject("CARGO_V2_LogisticsBusinessRuntime");
            instance = host.AddComponent<SCR_LogisticsBusinessRuntime>();
            DontDestroyOnLoad(host);
        }

        private void Awake()
        {
            if (instance != null && instance != this)
            {
                Destroy(gameObject);
                return;
            }

            instance = this;
            DontDestroyOnLoad(gameObject);

            if (!CargoV2LogisticsCatalog.Validate(out string catalogError))
            {
                status = $"Fleet catalog error: {catalogError}";
                statusUntil = float.PositiveInfinity;
            }
        }

        private void OnDestroy()
        {
            if (instance == this) instance = null;
        }

        private bool IsWorldMapAvailable()
        {
            return !SCR_MissionRuntimeDirector.IsRunning &&
                   FindObjectOfType<SCR_WorldMapRouteController>() != null;
        }

        private void OnGUI()
        {
            if (!IsWorldMapAvailable()) return;

            float x = Mathf.Max(10f, Screen.width - PanelWidth - 18f);
            if (!expanded)
            {
                GUILayout.BeginArea(new Rect(x + PanelWidth - 176f, 18f, 176f, 110f));
                if (GUILayout.Button("LOGISTICS HQ", GUILayout.Height(42f)))
                {
                    expanded = true;
                }

                DrawResumeButton();
                GUILayout.EndArea();
                return;
            }

            GUILayout.BeginArea(new Rect(x, 18f, PanelWidth, Mathf.Min(PanelHeight, Screen.height - 36f)), GUI.skin.box);
            GUILayout.BeginHorizontal();
            GUILayout.Label("CARGO V2 — LOGISTICS HQ");
            if (GUILayout.Button("×", GUILayout.Width(40f)))
            {
                expanded = false;
            }
            GUILayout.EndHorizontal();

            if (SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy))
            {
                int rank = CargoV2LogisticsCatalog.GetCompanyRank(economy.Xp);
                GUILayout.Label($"Company Rank {rank}   •   {economy.Coins:N0} coins   •   {economy.Xp:N0} XP");
            }
            else
            {
                GUILayout.Label("Economy: safe hold — save unavailable");
            }

            DrawActiveContract();
            DrawResumeButton();

            GUILayout.Space(8f);
            GUILayout.Label("FLEET");
            fleetScroll = GUILayout.BeginScrollView(fleetScroll, GUILayout.Height(300f));
            foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
            {
                DrawTruckCard(truck);
            }
            GUILayout.EndScrollView();

            DrawUpgradeControls();

            if (!string.IsNullOrEmpty(status) && Time.unscaledTime <= statusUntil)
            {
                GUILayout.Space(6f);
                GUILayout.Label(status);
            }

            GUILayout.EndArea();
        }

        private void DrawActiveContract()
        {
            SCR_WorldMapRouteController controller = FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null || controller.SelectedMission == null) return;

            CargoV2ContractSpec contract = CargoV2LogisticsCatalog.BuildContract(controller.SelectedMission);
            if (contract == null) return;

            string selectedTruckId = SCR_CompanyProgressStore.GetSelectedTruckId();
            CargoV2TruckSpec selectedTruck = CargoV2LogisticsCatalog.GetTruck(selectedTruckId);

            GUILayout.Space(8f);
            GUILayout.Label($"CONTRACT {contract.missionId:00}");
            GUILayout.Label($"{contract.origin}  →  {contract.destination}");
            GUILayout.Label($"{contract.cargoLabel} • {contract.cargoWeightTons:0.0} t • {contract.distanceKm} km");
            GUILayout.Label($"Reward {contract.payoutCoins:N0} + up to {contract.bonusCoins:N0} bonus • {contract.xp} XP");

            bool canCarry = selectedTruck != null &&
                            selectedTruck.cargoCapacityTons >= contract.cargoWeightTons;
            GUILayout.Label(canCarry
                ? $"Selected: {selectedTruck.displayName} — capacity OK"
                : "Selected truck is under-capacity — deployment stays available with reduced speed and acceleration.");
        }

        private void DrawResumeButton()
        {
            if (!SCR_ActiveDeliveryStore.TryLoadAny(out SCR_ActiveDeliveryStore.Snapshot active)) return;

            if (GUILayout.Button($"RESUME DELIVERY {active.MissionId:00}", GUILayout.Height(36f)))
            {
                if (SCR_MissionRuntimeDirector.LaunchInPlace(active.MissionId))
                {
                    expanded = false;
                    SetStatus("Delivery resumed.");
                }
                else
                {
                    SetStatus("Delivery could not resume safely.");
                }
            }
        }

        private void DrawTruckCard(CargoV2TruckSpec truck)
        {
            bool owned = SCR_CompanyProgressStore.IsOwned(truck.id);
            string selectedId = SCR_CompanyProgressStore.GetSelectedTruckId();
            bool selected = string.Equals(selectedId, truck.id, System.StringComparison.Ordinal);

            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label($"{truck.displayName} {(selected ? "• SELECTED" : string.Empty)}");
            GUILayout.Label(
                $"Speed {truck.topSpeedMetersPerSecond * 3.6f:0} km/h • Capacity {truck.cargoCapacityTons:0.#} t • Durability {truck.durability:0.00}");

            if (owned)
            {
                if (SCR_CompanyProgressStore.TryGetTruckState(truck.id, out SCR_CompanyProgressStore.TruckState state))
                {
                    GUILayout.Label(
                        $"Engine {state.EngineLevel}/3 • Handling {state.HandlingLevel}/3 • Durability {state.DurabilityLevel}/3");
                }

                if (!selected && GUILayout.Button("SELECT"))
                {
                    if (SCR_CompanyProgressStore.TrySelectTruck(truck.id, out string reason))
                    {
                        SetStatus($"{truck.displayName} selected.");
                    }
                    else
                    {
                        SetStatus(reason);
                    }
                }
            }
            else
            {
                GUILayout.Label($"Unlock {truck.unlockXp:N0} XP • Buy {truck.purchasePrice:N0} coins");
                if (GUILayout.Button("BUY"))
                {
                    if (SCR_CompanyProgressStore.TryBuyTruck(truck.id, out string reason))
                    {
                        SetStatus($"{truck.displayName} added to fleet.");
                    }
                    else
                    {
                        SetStatus(reason);
                    }
                }
            }
            GUILayout.EndVertical();
        }

        private void DrawUpgradeControls()
        {
            string selectedId = SCR_CompanyProgressStore.GetSelectedTruckId();
            CargoV2TruckSpec selected = CargoV2LogisticsCatalog.GetTruck(selectedId);
            if (selected == null ||
                !SCR_CompanyProgressStore.TryGetTruckState(selectedId, out SCR_CompanyProgressStore.TruckState state))
            {
                return;
            }

            GUILayout.Space(6f);
            GUILayout.Label($"UPGRADES — {selected.displayName}");
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Engine, state.EngineLevel, "ENGINE");
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Handling, state.HandlingLevel, "HANDLING");
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Durability, state.DurabilityLevel, "DURABILITY");
        }

        private void DrawUpgradeButton(
            CargoV2TruckSpec truck,
            CargoV2TruckUpgrade upgrade,
            int level,
            string label)
        {
            if (level >= 3)
            {
                GUILayout.Label($"{label}: MAX");
                return;
            }

            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(truck, upgrade, level);
            if (GUILayout.Button($"{label} {level} → {level + 1}   •   {cost:N0} coins"))
            {
                if (SCR_CompanyProgressStore.TryUpgradeSelected(upgrade, out string reason))
                {
                    SetStatus($"{label} upgraded.");
                }
                else
                {
                    SetStatus(reason);
                }
            }
        }

        private void SetStatus(string message)
        {
            status = string.IsNullOrWhiteSpace(message) ? string.Empty : message;
            statusUntil = Time.unscaledTime + 4f;
        }
    }
}
