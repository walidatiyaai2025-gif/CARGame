using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed class SCR_LogisticsBusinessRuntime : MonoBehaviour
    {
        private const float ReferencePanelWidth = 430f;
        private const float ReferencePanelHeight = 620f;
        private static SCR_LogisticsBusinessRuntime instance;

        private bool expanded;
        private Vector2 fleetScroll;
        private string status = string.Empty;
        private float statusUntil;
        private float currentScale = 1f;
        private GUIStyle labelStyle;
        private GUIStyle buttonStyle;
        private GUIStyle headerStyle;
        private GUIStyle boxStyle;

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

        public static bool IsPointOverUi(Vector2 guiPoint)
        {
            if (instance == null || !instance.IsWorldMapAvailable()) return false;
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
            float scale = CargoV2UiLayout.Scale(safe, settings.LargeText);
            Rect area = instance.expanded
                ? instance.GetExpandedRect(safe, scale)
                : instance.GetCollapsedRect(safe, scale);
            return area.Contains(guiPoint);
        }

        private bool IsWorldMapAvailable()
        {
            return !SCR_MissionRuntimeDirector.IsRunning &&
                   FindObjectOfType<SCR_WorldMapRouteController>() != null;
        }

        private void OnGUI()
        {
            if (!IsWorldMapAvailable() || SCR_PlayerExperienceRuntime.HasModalOpen) return;

            Rect safe = CargoV2UiLayout.SafeGuiRect;
            CargoV2PlayerSettings.Snapshot settings = CargoV2PlayerSettings.Load();
            currentScale = CargoV2UiLayout.Scale(safe, settings.LargeText);
            BuildStyles(currentScale);

            if (!expanded)
            {
                Rect collapsed = GetCollapsedRect(safe, currentScale);
                GUILayout.BeginArea(collapsed);
                if (GUILayout.Button(L("hq.title"), buttonStyle, GUILayout.Height(ButtonHeight)))
                {
                    expanded = true;
                    SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
                }
                DrawResumeButton();
                GUILayout.EndArea();
                return;
            }

            Rect panel = GetExpandedRect(safe, currentScale);
            GUILayout.BeginArea(panel, boxStyle);
            GUILayout.BeginHorizontal();
            GUILayout.Label(L("hq.title"), headerStyle, GUILayout.ExpandWidth(true), GUILayout.Height(ButtonHeight));
            if (GUILayout.Button("×", buttonStyle, GUILayout.Width(ButtonHeight), GUILayout.Height(ButtonHeight)))
            {
                expanded = false;
                SCR_PlayerFeedback.Play(SCR_PlayerFeedback.Cue.Ui);
            }
            GUILayout.EndHorizontal();

            if (SCR_MissionRewardStore.TryReadSnapshot(out SCR_MissionRewardStore.Snapshot economy))
            {
                int rank = CargoV2LogisticsCatalog.GetCompanyRank(economy.Xp);
                GUILayout.Label(F("hq.companyRank", Num(rank), Num(economy.Coins), Num(economy.Xp)), labelStyle);
            }
            else
            {
                GUILayout.Label(L("hq.economyUnavailable"), labelStyle);
            }

            DrawActiveContract();
            DrawResumeButton();

            GUILayout.Space(8f * currentScale);
            GUILayout.Label(L("hq.fleet"), headerStyle);
            float scrollHeight = Mathf.Clamp(panel.height * 0.40f, 180f, 310f * currentScale);
            fleetScroll = GUILayout.BeginScrollView(fleetScroll, GUILayout.Height(scrollHeight));
            foreach (CargoV2TruckSpec truck in CargoV2LogisticsCatalog.AllTrucks)
            {
                DrawTruckCard(truck);
            }
            GUILayout.EndScrollView();

            DrawUpgradeControls();

            if (!string.IsNullOrEmpty(status) && Time.unscaledTime <= statusUntil)
            {
                GUILayout.Space(6f * currentScale);
                GUILayout.Label(status, labelStyle);
            }

            GUILayout.EndArea();
        }

        private Rect GetCollapsedRect(Rect safe, float scale)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float width = Mathf.Min(safe.width - margin * 2f, Mathf.Max(188f, 214f * scale));
            float height = Mathf.Max(58f, 116f * scale);
            return CargoV2UiLayout.ClampToSafe(
                new Rect(safe.xMax - margin - width, safe.y + margin, width, height), safe);
        }

        private Rect GetExpandedRect(Rect safe, float scale)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float width = Mathf.Min(safe.width - margin * 2f, Mathf.Max(350f, ReferencePanelWidth * scale));
            float height = Mathf.Min(safe.height - margin * 2f, Mathf.Max(470f, ReferencePanelHeight * scale));
            return CargoV2UiLayout.ClampToSafe(
                new Rect(safe.xMax - margin - width, safe.y + margin, width, height), safe);
        }

        private float ButtonHeight => Mathf.Max(44f, 50f * currentScale);

        private void DrawActiveContract()
        {
            SCR_WorldMapRouteController controller = FindObjectOfType<SCR_WorldMapRouteController>();
            if (controller == null || controller.SelectedMission == null) return;

            CargoV2ContractSpec contract = CargoV2LogisticsCatalog.BuildContract(controller.SelectedMission);
            if (contract == null) return;

            string selectedTruckId = SCR_CompanyProgressStore.GetSelectedTruckId();
            CargoV2TruckSpec selectedTruck = CargoV2LogisticsCatalog.GetTruck(selectedTruckId);

            GUILayout.Space(7f * currentScale);
            GUILayout.Label(F("hq.contract", Two(contract.missionId)), headerStyle);
            GUILayout.Label($"{Term(contract.origin)}  →  {Term(contract.destination)}", labelStyle);
            GUILayout.Label($"{Term(contract.cargoLabel)} • {Dec(contract.cargoWeightTons, "0.0")} t • {Num(contract.distanceKm)} km", labelStyle);
            GUILayout.Label($"{L("reward")}: {Num(contract.payoutCoins)} + {Num(contract.bonusCoins)} {L("hq.bonus")} • {Num(contract.xp)} XP", labelStyle);

            bool canCarry = selectedTruck != null && selectedTruck.cargoCapacityTons >= contract.cargoWeightTons;
            GUILayout.Label(canCarry && selectedTruck != null
                ? F("hq.capacityOk", selectedTruck.displayName)
                : L("hq.underCapacity"), labelStyle);
        }

        private void DrawResumeButton()
        {
            if (!SCR_ActiveDeliveryStore.TryLoadAny(out SCR_ActiveDeliveryStore.Snapshot active)) return;

            if (GUILayout.Button(F("hq.resumeDelivery", Two(active.MissionId)), buttonStyle, GUILayout.Height(ButtonHeight)))
            {
                if (SCR_MissionRuntimeDirector.LaunchInPlace(active.MissionId))
                {
                    expanded = false;
                    SetStatus(L("hq.resumed"), false);
                }
                else
                {
                    SetStatus(L("hq.resumeFailed"), true);
                }
            }
        }

        private void DrawTruckCard(CargoV2TruckSpec truck)
        {
            bool owned = SCR_CompanyProgressStore.IsOwned(truck.id);
            string selectedId = SCR_CompanyProgressStore.GetSelectedTruckId();
            bool selected = string.Equals(selectedId, truck.id, System.StringComparison.Ordinal);

            GUILayout.BeginVertical(boxStyle);
            GUILayout.Label($"{truck.displayName} {(selected ? "• " + L("hq.selected") : string.Empty)}", headerStyle);
            GUILayout.Label(
                $"{L("hq.speed")} {Dec(truck.topSpeedMetersPerSecond * 3.6f, "0")} km/h • {L("hq.capacity")} {Dec(truck.cargoCapacityTons, "0.#")} t • {L("hq.durability")} {Dec(truck.durability, "0.00")}",
                labelStyle);

            if (owned)
            {
                if (SCR_CompanyProgressStore.TryGetTruckState(truck.id, out SCR_CompanyProgressStore.TruckState state))
                {
                    GUILayout.Label(
                        $"{L("hq.engine")} {Num(state.EngineLevel)}/3 • {L("hq.handling")} {Num(state.HandlingLevel)}/3 • {L("hq.durability")} {Num(state.DurabilityLevel)}/3",
                        labelStyle);
                }

                if (!selected && GUILayout.Button(L("hq.select"), buttonStyle, GUILayout.Height(ButtonHeight)))
                {
                    if (SCR_CompanyProgressStore.TrySelectTruck(truck.id, out string reason))
                    {
                        SetStatus($"{truck.displayName} {L("hq.selected")}", false);
                    }
                    else SetStatus(reason, true);
                }
            }
            else
            {
                GUILayout.Label(F("hq.unlockBuy", Num(truck.unlockXp), Num(truck.purchasePrice)), labelStyle);
                if (GUILayout.Button(L("hq.buy"), buttonStyle, GUILayout.Height(ButtonHeight)))
                {
                    if (SCR_CompanyProgressStore.TryBuyTruck(truck.id, out string reason))
                    {
                        SetStatus($"{truck.displayName} {L("hq.purchased")}", false);
                    }
                    else SetStatus(reason, true);
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

            GUILayout.Space(6f * currentScale);
            GUILayout.Label(F("hq.upgrades", selected.displayName), headerStyle);
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Engine, state.EngineLevel, "hq.engine");
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Handling, state.HandlingLevel, "hq.handling");
            DrawUpgradeButton(selected, CargoV2TruckUpgrade.Durability, state.DurabilityLevel, "hq.durability");
        }

        private void DrawUpgradeButton(CargoV2TruckSpec truck, CargoV2TruckUpgrade upgrade, int level, string labelKey)
        {
            string label = L(labelKey);
            if (level >= 3)
            {
                GUILayout.Label($"{label}: {L("hq.max")}", labelStyle);
                return;
            }

            long cost = CargoV2LogisticsCatalog.GetUpgradeCost(truck, upgrade, level);
            if (GUILayout.Button($"{label} {Num(level)} → {Num(level + 1)} • {Num(cost)} {L("hq.coins")}",
                    buttonStyle, GUILayout.Height(ButtonHeight)))
            {
                if (SCR_CompanyProgressStore.TryUpgradeSelected(upgrade, out string reason))
                {
                    SetStatus($"{label} {L("hq.upgraded")}", false);
                }
                else SetStatus(reason, true);
            }
        }

        private void SetStatus(string message, bool error)
        {
            status = string.IsNullOrWhiteSpace(message) ? string.Empty : message;
            statusUntil = Time.unscaledTime + 4f;
            SCR_PlayerFeedback.Play(error ? SCR_PlayerFeedback.Cue.Error : SCR_PlayerFeedback.Cue.Ui);
        }

        private void BuildStyles(float scale)
        {
            bool rtl = SCR_LocalizationManager.Instance != null && SCR_LocalizationManager.Instance.IsRtl;
            labelStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(18f * scale), 15, 30),
                alignment = rtl ? TextAnchor.MiddleRight : TextAnchor.MiddleLeft,
                wordWrap = true,
            };
            buttonStyle = new GUIStyle(GUI.skin.button)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(17f * scale), 15, 28),
                fontStyle = FontStyle.Bold,
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
            };
            headerStyle = new GUIStyle(labelStyle)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(20f * scale), 17, 32),
                fontStyle = FontStyle.Bold,
            };
            boxStyle = new GUIStyle(GUI.skin.box)
            {
                padding = new RectOffset(
                    Mathf.RoundToInt(9f * scale), Mathf.RoundToInt(9f * scale),
                    Mathf.RoundToInt(8f * scale), Mathf.RoundToInt(8f * scale)),
            };
        }

        private static string L(string key)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            string value = manager != null ? manager.Get(key) : key;
            if (!string.Equals(value, key, System.StringComparison.Ordinal)) return value;
            return CargoV2LocalizationTerms.LogisticsLabel(key);
        }

        private static string F(string key, params object[] args)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.Format(key, args) : string.Format(L(key), args);
        }

        private static string Num(long value)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.FormatInteger(value) : value.ToString("N0");
        }

        private static string Dec(float value, string format)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.FormatDecimal(value, format) : value.ToString(format);
        }

        private static string Two(int value)
        {
            string raw = Mathf.Clamp(value, 0, 99).ToString("00");
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.LocalizeDigits(raw) : raw;
        }

        private static string Term(string value)
        {
            return CargoV2LocalizationTerms.Term(value);
        }
    }
}
