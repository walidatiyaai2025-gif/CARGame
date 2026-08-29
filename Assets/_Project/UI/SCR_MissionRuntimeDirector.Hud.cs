using System;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    public sealed partial class SCR_MissionRuntimeDirector
    {
        private void OnGUI()
        {
            if (!initialized || mission == null || contract == null) return;

            GUILayout.BeginArea(new Rect(HudX, HudY, HudWidth, HudHeight), GUI.skin.box);
            GUILayout.Label($"CARGO V2 — CONTRACT {mission.missionId:00}");
            GUILayout.Label($"{contract.origin}  →  {contract.destination}");
            GUILayout.Label($"{contract.cargoLabel} • {contract.cargoWeightTons:0.0} t • {contract.distanceKm} km");
            GUILayout.Label($"{truckStats.DisplayName} • {Mathf.Abs(GetForwardSpeed()) * 3.6f:0} km/h • Damage {damage:0}% • Time {Mathf.CeilToInt(remainingSeconds)}s");
            GUILayout.Label(cargoLoaded ? "Cargo: LOADED — proceed to gold delivery zone." : "Cargo: DRIVE INTO THE CYAN PICKUP ZONE.");
            GUILayout.Label(usingRealTruckAsset && usingRealMissionAsset ? "3D assets: premium truck + cargo/depot pack" : "3D assets: safe generated fallback active");

            if (contract.cargoWeightTons > truckStats.CargoCapacityTons)
            {
                GUILayout.Label($"OVER CAPACITY: {contract.cargoWeightTons:0.0} t / {truckStats.CargoCapacityTons:0.0} t — reduced performance.");
            }

            if (terminal)
            {
                GUILayout.Space(6f);
                if (succeeded)
                {
                    long reward = SCR_MissionRewardStore.GetCoinReward(mission, completionStars);
                    GUILayout.Label($"DELIVERY COMPLETE — {new string('★', completionStars)}");
                    GUILayout.Label($"Settlement queued: {reward:N0} coins + {mission.xp} XP");
                }
                else
                {
                    GUILayout.Label(string.IsNullOrEmpty(statusReason) ? "DELIVERY FAILED" : statusReason);
                    if (GUILayout.Button("RETRY")) RetryMission();
                }

                if (GUILayout.Button("BACK TO WORLD MAP"))
                {
                    if (succeeded)
                    {
                        PlayerPrefs.DeleteKey(PendingMissionKey);
                        PlayerPrefs.Save();
                        Time.timeScale = 1f;
                        Destroy(gameObject);
                    }
                    else
                    {
                        AbandonMission();
                    }
                }
            }
            else if (paused)
            {
                GUILayout.Label("PAUSED");
                if (GUILayout.Button("RESUME")) TogglePause();
                if (GUILayout.Button("ABANDON CONTRACT")) AbandonMission();
            }
            else
            {
                GUILayout.Label("Keyboard: W/S throttle • A/D steer • SPACE brake • R recover • P pause");
            }
            GUILayout.EndArea();

            if (!terminal && !paused)
            {
                GUI.Box(GetLeftRect(), "◀");
                GUI.Box(GetRightRect(), "▶");
                GUI.Box(GetBrakeRect(), "BRAKE / REV");
                GUI.Box(GetThrottleRect(), "THROTTLE");
                if (GUI.Button(GetRecoverRect(), "RECOVER")) RecoverTruck();
                if (GUI.Button(GetPauseRect(), "PAUSE")) TogglePause();
            }
        }

        private static Rect GetLeftRect() => new Rect(18f, Screen.height - 118f, 96f, 96f);
        private static Rect GetRightRect() => new Rect(122f, Screen.height - 118f, 96f, 96f);
        private static Rect GetBrakeRect() => new Rect(Screen.width - 222f, Screen.height - 118f, 96f, 96f);
        private static Rect GetThrottleRect() => new Rect(Screen.width - 118f, Screen.height - 118f, 96f, 96f);
        private static Rect GetRecoverRect() => new Rect(Screen.width - 224f, 18f, 100f, 42f);
        private static Rect GetPauseRect() => new Rect(Screen.width - 116f, 18f, 98f, 42f);

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
            if (pauseStatus) SaveActiveDelivery();
        }

        private void OnApplicationQuit()
        {
            applicationQuitting = true;
            SaveActiveDelivery();
        }

        private void OnDestroy()
        {
            if (activeInstance == this) activeInstance = null;

            if (!terminal && !abandonRequested && !applicationQuitting && initialized) SaveActiveDelivery();
            if (succeeded || abandonRequested) SCR_ActiveDeliveryStore.Clear();
            if (!applicationQuitting && (succeeded || abandonRequested))
            {
                PlayerPrefs.DeleteKey(PendingMissionKey);
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
