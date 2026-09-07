using System;
using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    public sealed partial class SCR_MissionRuntimeDirector
    {
        private GUIStyle hudLabelStyle;
        private GUIStyle hudHeaderStyle;
        private GUIStyle hudButtonStyle;
        private GUIStyle hudBoxStyle;

        private void OnGUI()
        {
            if (!initialized || mission == null || contract == null || SCR_PlayerExperienceRuntime.HasModalOpen) return;

            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            BuildHudStyles(scale);
            Rect hudRect = GetHudRect(safe, scale);

            GUILayout.BeginArea(hudRect, hudBoxStyle);
            GUILayout.Label(F("hud.contract", Two(mission.missionId)), hudHeaderStyle);
            GUILayout.Label($"{contract.origin}  →  {contract.destination}", hudLabelStyle);
            GUILayout.Label($"{contract.cargoLabel} • {Dec(contract.cargoWeightTons, "0.0")} t • {Num(contract.distanceKm)} km", hudLabelStyle);
            GUILayout.Label(
                $"{truckStats.DisplayName} • {Dec(Mathf.Abs(GetForwardSpeed()) * 3.6f, "0")} km/h • {L("hud.damage")} {Dec(damage, "0")}% • {L("hud.time")} {Num(Mathf.CeilToInt(remainingSeconds))}s",
                hudLabelStyle);
            GUILayout.Label(cargoLoaded
                ? F("hud.cargoLoaded", Num(checkpointIndex))
                : L("hud.pickup"), hudLabelStyle);

            if (contract.cargoWeightTons > truckStats.CargoCapacityTons)
            {
                GUILayout.Label(F("hud.overCapacity",
                    Dec(contract.cargoWeightTons, "0.0"),
                    Dec(truckStats.CargoCapacityTons, "0.0")), hudLabelStyle);
            }

            if (terminal)
            {
                DrawResultPanel(scale);
            }
            else if (paused)
            {
                DrawPausePanel(scale);
            }
            GUILayout.EndArea();

            if (!terminal && !paused)
            {
                GUI.Box(GetLeftRect(), "◀", hudButtonStyle);
                GUI.Box(GetRightRect(), "▶", hudButtonStyle);
                GUI.Box(GetBrakeRect(), L("hud.brakeReverse"), hudButtonStyle);
                GUI.Box(GetThrottleRect(), L("hud.throttle"), hudButtonStyle);
                if (GUI.Button(GetRecoverRect(), L("hud.recover"), hudButtonStyle)) RecoverTruck();
                if (GUI.Button(GetPauseRect(), L("hud.pause"), hudButtonStyle)) TogglePause();
            }
        }

        private void DrawResultPanel(float scale)
        {
            GUILayout.Space(6f * scale);
            if (succeeded)
            {
                long reward = SCR_MissionRewardStore.GetCoinReward(mission, completionStars);
                string stars = new string('★', Mathf.Clamp(completionStars, 1, 3));
                GUILayout.Label($"{L("hud.complete")} • {stars}", hudHeaderStyle);
                GUILayout.Label(F("hud.reward", Num(reward), Num(mission.xp)), hudLabelStyle);
            }
            else
            {
                string reason = ResolveStatusReason();
                GUILayout.Label(string.IsNullOrEmpty(reason) ? L("hud.failed") : reason, hudHeaderStyle);
                if (GUILayout.Button(L("hud.retry"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale))))
                {
                    RetryMission();
                }
            }

            if (GUILayout.Button(L("hud.worldMap"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale))))
            {
                ReturnToWorldMapFromResult();
            }
        }

        private void DrawPausePanel(float scale)
        {
            GUILayout.Space(5f * scale);
            GUILayout.Label(L("hud.paused"), hudHeaderStyle);
            if (GUILayout.Button(L("hud.resume"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale)))) TogglePause();
            if (GUILayout.Button(L("settings.title"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale))))
            {
                SCR_PlayerExperienceRuntime.OpenSettings();
            }
            if (GUILayout.Button(L("help.title"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale))))
            {
                SCR_PlayerExperienceRuntime.OpenHelp();
            }
            if (GUILayout.Button(L("hud.abandon"), hudButtonStyle, GUILayout.Height(HudButtonHeight(scale)))) AbandonMission();
        }

        private Rect GetHudRect(Rect safe, float scale)
        {
            float margin = CargoV2UiLayout.Margin(scale);
            float width = Mathf.Min(safe.width * 0.58f, Mathf.Max(390f, 590f * scale));
            float height;
            if (terminal || paused)
            {
                height = Mathf.Min(safe.height - margin * 2f, Mathf.Max(390f, 510f * scale));
            }
            else
            {
                height = Mathf.Min(safe.height * 0.46f, Mathf.Max(230f, 310f * scale));
            }
            return CargoV2UiLayout.TopLeftPanel(safe, width, height, scale);
        }

        private float HudButtonHeight(float scale)
        {
            return Mathf.Max(44f, 52f * scale);
        }

        private Rect GetLeftRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.BottomLeftTouch(safe, 0, scale);
        }

        private Rect GetRightRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.BottomLeftTouch(safe, 1, scale);
        }

        private Rect GetBrakeRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.BottomRightTouch(safe, 1, scale);
        }

        private Rect GetThrottleRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.BottomRightTouch(safe, 0, scale);
        }

        private Rect GetRecoverRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.TopRightTouch(safe, 1, scale);
        }

        private Rect GetPauseRect()
        {
            Rect safe = CargoV2UiLayout.SafeGuiRect;
            float scale = CargoV2UiLayout.Scale(safe, playerSettings.LargeText);
            return CargoV2UiLayout.TopRightTouch(safe, 0, scale);
        }

        private void BuildHudStyles(float scale)
        {
            bool rtl = SCR_LocalizationManager.Instance != null && SCR_LocalizationManager.Instance.IsRtl;
            hudLabelStyle = new GUIStyle(GUI.skin.label)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(18f * scale), 15, 31),
                alignment = rtl ? TextAnchor.MiddleRight : TextAnchor.MiddleLeft,
                wordWrap = true,
            };
            hudHeaderStyle = new GUIStyle(hudLabelStyle)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(21f * scale), 17, 34),
                fontStyle = FontStyle.Bold,
            };
            hudButtonStyle = new GUIStyle(GUI.skin.button)
            {
                fontSize = Mathf.Clamp(Mathf.RoundToInt(17f * scale), 15, 28),
                fontStyle = FontStyle.Bold,
                alignment = TextAnchor.MiddleCenter,
                wordWrap = true,
            };
            hudBoxStyle = new GUIStyle(GUI.skin.box)
            {
                padding = new RectOffset(
                    Mathf.RoundToInt(12f * scale), Mathf.RoundToInt(12f * scale),
                    Mathf.RoundToInt(10f * scale), Mathf.RoundToInt(10f * scale)),
            };
        }

        private string ResolveStatusReason()
        {
            if (string.IsNullOrWhiteSpace(statusReason)) return string.Empty;
            return statusReason.StartsWith("hud.", StringComparison.Ordinal) ? L(statusReason) : statusReason;
        }

        private static string L(string key)
        {
            SCR_LocalizationManager manager = SCR_LocalizationManager.Instance;
            return manager != null ? manager.Get(key) : key;
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

        private Material CreateMaterial(Shader shader, Color color)
        {
            if (shader == null) return null;
            Material material = new Material(shader) { color = color };
            runtimeMaterials.Add(material);
            return material;
        }

        private static void SetMaterial(GameObject go, Material material)
        {
            Renderer renderer = go != null ? go.GetComponent<Renderer>() : null;
            if (renderer != null && material != null) renderer.sharedMaterial = material;
        }

        private static void DisableCollider(GameObject go)
        {
            Collider collider = go != null ? go.GetComponent<Collider>() : null;
            if (collider != null) collider.enabled = false;
        }

        private static void RemoveChildColliders(GameObject root)
        {
            if (root == null) return;
            Collider[] colliders = root.GetComponentsInChildren<Collider>(true);
            for (int i = 0; i < colliders.Length; i++)
            {
                if (colliders[i] != null) colliders[i].enabled = false;
            }
        }

        private static GameObject ClonePart(Transform source, Transform parent, string name)
        {
            if (source == null) return null;
            GameObject clone = Instantiate(source.gameObject, parent);
            clone.name = name;
            clone.transform.localPosition = Vector3.zero;
            clone.transform.localRotation = Quaternion.identity;
            clone.transform.localScale = Vector3.one;
            RemoveChildColliders(clone);
            return clone;
        }

        private static Transform FindChildRecursive(Transform root, string childName)
        {
            if (root == null) return null;
            if (string.Equals(root.name, childName, StringComparison.Ordinal)) return root;
            for (int i = 0; i < root.childCount; i++)
            {
                Transform match = FindChildRecursive(root.GetChild(i), childName);
                if (match != null) return match;
            }
            return null;
        }

        private void OnApplicationPause(bool pauseStatus)
        {
            if (!pauseStatus || !initialized || terminal) return;
            if (!paused)
            {
                paused = true;
                Time.timeScale = 0f;
            }
            SaveActiveDelivery();
            SCR_PlayerFeedback.StopEngine();
        }

        private void OnApplicationQuit()
        {
            applicationQuitting = true;
            SaveActiveDelivery();
            SCR_PlayerFeedback.StopEngine();
        }

        private void OnDestroy()
        {
            CargoV2PlayerSettings.Changed -= HandlePlayerSettingsChanged;
            SCR_PlayerFeedback.StopEngine();
            if (activeInstance == this) activeInstance = null;

            if (!terminal && !abandonRequested && !applicationQuitting && initialized) SaveActiveDelivery();
            if (succeeded || abandonRequested) SCR_ActiveDeliveryStore.Clear();
            if (!applicationQuitting && (succeeded || abandonRequested))
            {
                PlayerPrefs.DeleteKey(PendingMissionKey);
                if (abandonRequested) PlayerPrefs.DeleteKey(ActiveDeliveryRunKey);
                PlayerPrefs.Save();
            }

            Time.timeScale = 1f;
            for (int i = 0; i < spawnedObjects.Count; i++)
            {
                if (spawnedObjects[i] != null) Destroy(spawnedObjects[i]);
            }
            spawnedObjects.Clear();

            for (int i = 0; i < runtimeMaterials.Count; i++)
            {
                if (runtimeMaterials[i] != null) Destroy(runtimeMaterials[i]);
            }
            runtimeMaterials.Clear();

            if (balance != null)
            {
                Destroy(balance);
                balance = null;
            }
        }

        private enum TriggerKind
        {
            Pickup = 0,
            Checkpoint = 1,
            Delivery = 2,
        }

        private sealed class MissionTrigger : MonoBehaviour
        {
            public SCR_MissionRuntimeDirector Owner;
            public TriggerKind Kind;
            public int Checkpoint;

            private void OnTriggerEnter(Collider other)
            {
                if (Owner == null || other == null || Owner.truckBody == null) return;
                if (other.attachedRigidbody != Owner.truckBody) return;
                Owner.HandleMissionTrigger(Kind, Checkpoint);
            }
        }

        private sealed class TruckCollisionReporter : MonoBehaviour
        {
            public SCR_MissionRuntimeDirector Owner;

            private void OnCollisionEnter(Collision collision)
            {
                if (Owner == null || collision == null) return;
                Owner.ReportCollision(collision.relativeVelocity.magnitude);
            }
        }
    }
}
