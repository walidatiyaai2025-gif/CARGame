using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    public sealed partial class SCR_MissionRuntimeDirector
    {
        private void ReadInput()
        {
            throttleInput = 0f;
            steeringInput = 0f;
            hardBrake = Input.GetKey(KeyCode.Space);

            if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow)) throttleInput += 1f;
            if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow)) throttleInput -= 1f;
            if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow)) steeringInput -= 1f;
            if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow)) steeringInput += 1f;

            for (int i = 0; i < Input.touchCount; i++)
            {
                Touch touch = Input.GetTouch(i);
                if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled) continue;
                Vector2 guiPoint = new Vector2(touch.position.x, Screen.height - touch.position.y);
                if (GetLeftRect().Contains(guiPoint)) steeringInput -= 1f;
                if (GetRightRect().Contains(guiPoint)) steeringInput += 1f;
                if (GetThrottleRect().Contains(guiPoint)) throttleInput += 1f;
                if (GetBrakeRect().Contains(guiPoint)) throttleInput -= 1f;
            }

            throttleInput = Mathf.Clamp(throttleInput, -1f, 1f);
            steeringInput = Mathf.Clamp(steeringInput, -1f, 1f);
        }

        private void HandleMissionTrigger(TriggerKind kind, int checkpoint)
        {
            if (terminal || !initialized) return;

            if (kind == TriggerKind.Pickup)
            {
                if (!cargoLoaded)
                {
                    cargoLoaded = true;
                    checkpointIndex = 0;
                    AttachCargoToTruck();
                    if (pickupCargoVisual != null) pickupCargoVisual.SetActive(false);
                    SaveActiveDelivery();
                }
                return;
            }

            if (kind == TriggerKind.Checkpoint)
            {
                // A route checkpoint is authoritative only after the cargo has been
                // collected and only when reached in sequence. This prevents a player
                // from banking a downstream recovery point before pickup or skipping
                // route obligations by approaching checkpoints out of order.
                if (!cargoLoaded) return;
                int expectedCheckpoint = checkpointIndex + 1;
                if (checkpoint != expectedCheckpoint) return;
                if (checkpoint < 1 || checkpoint >= CheckpointPositions.Length) return;

                checkpointIndex = checkpoint;
                SaveActiveDelivery();
                return;
            }

            if (kind == TriggerKind.Delivery)
            {
                // Delivery requires both cargo and the final route checkpoint. Entering
                // the destination early is intentionally a no-op rather than a success.
                if (!cargoLoaded || checkpointIndex < CheckpointPositions.Length - 1) return;
                CompleteMission();
            }
        }

        private void CompleteMission()
        {
            if (terminal) return;
            terminal = true;
            succeeded = true;
            throttleInput = 0f;
            steeringInput = 0f;
            hardBrake = true;

            float timeRatio = remainingSeconds / Mathf.Max(1f, mission.timeSeconds);
            completionStars = damage <= 10f && timeRatio >= 0.22f ? 3 : damage <= 35f ? 2 : 1;

            PlayerPrefs.SetInt(CompletionHandoffKey, mission.missionId);
            PlayerPrefs.SetInt(CompletionStarsKey, completionStars);
            PlayerPrefs.Save();
            SCR_ActiveDeliveryStore.Clear();
        }

        private void FailMission(string reason)
        {
            terminal = true;
            succeeded = false;
            completionStars = 0;
            statusReason = reason;
            SCR_ActiveDeliveryStore.Clear();
        }

        internal void ReportCollision(float relativeSpeed)
        {
            if (terminal || relativeSpeed <= 3f) return;

            float rawDamage = (relativeSpeed - 3f) * 3.2f;
            damage = Mathf.Clamp(
                damage + rawDamage / Mathf.Max(0.45f, truckStats.Durability),
                0f,
                100f);

            if (damage >= 100f) FailMission("TRUCK DISABLED");
            else SaveActiveDelivery();
        }

        private void RecoverTruck()
        {
            if (truckBody == null || terminal) return;

            damage = Mathf.Min(99f, damage + 8f);
            remainingSeconds = Mathf.Max(1f, remainingSeconds - 5f);
            ResetTruckToCheckpoint(checkpointIndex, true);
            SaveActiveDelivery();
        }

        private void ResetTruckToCheckpoint(int index, bool keepCargo)
        {
            if (truckBody == null) return;

            int safeIndex = Mathf.Clamp(index, 0, CheckpointPositions.Length - 1);
            truckBody.position = CheckpointPositions[safeIndex];
            truckBody.rotation = Quaternion.identity;
            truckBody.velocity = Vector3.zero;
            truckBody.angularVelocity = Vector3.zero;

            if (!keepCargo && safeIndex == 0)
            {
                cargoLoaded = false;
                checkpointIndex = 0;
                if (pickupCargoVisual != null) pickupCargoVisual.SetActive(true);
                if (loadedCargoVisual != null)
                {
                    Destroy(loadedCargoVisual);
                    loadedCargoVisual = null;
                }
            }
        }

        private void RestoreActiveDelivery(SCR_ActiveDeliveryStore.Snapshot active)
        {
            checkpointIndex = Mathf.Clamp(active.CheckpointIndex, 0, CheckpointPositions.Length - 1);
            remainingSeconds = Mathf.Clamp(active.RemainingSeconds, 1f, Mathf.Max(25f, mission.timeSeconds));
            damage = Mathf.Clamp(active.Damage, 0f, 99f);
            cargoLoaded = active.CargoLoaded;

            // Corrupt/legacy state must never restore a downstream checkpoint without
            // cargo. Collapse it to the route start rather than granting free progress.
            if (!cargoLoaded && checkpointIndex != 0) checkpointIndex = 0;

            truckBody.position = active.Position;
            truckBody.rotation = Quaternion.Euler(0f, active.Yaw, 0f);
            truckBody.velocity = Vector3.zero;
            truckBody.angularVelocity = Vector3.zero;

            if (cargoLoaded)
            {
                if (pickupCargoVisual != null) pickupCargoVisual.SetActive(false);
                AttachCargoToTruck();
            }
        }

        private void RetryMission()
        {
            terminal = false;
            succeeded = false;
            paused = false;
            completionStars = 0;
            statusReason = string.Empty;
            damage = 0f;
            checkpointIndex = 0;
            remainingSeconds = Mathf.Max(25f, mission.timeSeconds);

            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.Save();

            ResetTruckToCheckpoint(0, false);
            SaveActiveDelivery();
            Time.timeScale = 1f;
        }

        private void AbandonMission()
        {
            abandonRequested = true;
            SCR_ActiveDeliveryStore.Clear();
            PlayerPrefs.DeleteKey(PendingMissionKey);
            PlayerPrefs.Save();
            Time.timeScale = 1f;
            Destroy(gameObject);
        }

        private void TogglePause()
        {
            if (terminal) return;
            paused = !paused;
            Time.timeScale = paused ? 0f : 1f;
            if (paused) SaveActiveDelivery();
        }

        private void SaveActiveDelivery()
        {
            if (!initialized || truckBody == null || terminal) return;

            SCR_ActiveDeliveryStore.TrySave(
                mission.missionId,
                truckStats.Id,
                truckBody.position,
                truckBody.rotation.eulerAngles.y,
                Mathf.Max(0f, remainingSeconds),
                Mathf.Clamp(damage, 0f, 100f),
                cargoLoaded,
                checkpointIndex);
        }

        private float GetForwardSpeed()
        {
            return truckBody == null ? 0f : Vector3.Dot(truckBody.velocity, truckBody.transform.forward);
        }
    }
}
