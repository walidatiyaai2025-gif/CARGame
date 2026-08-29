using System;
using System.Collections.Generic;
using CargoV2.Data;
using CargoV2.Logic;
using UnityEngine;

namespace CargoV2.UI
{
    [DisallowMultipleComponent]
    public sealed partial class SCR_MissionRuntimeDirector : MonoBehaviour
    {
        private const string PendingMissionKey = "cargo_v2_pending_mission_id";
        private const string CompletionHandoffKey = "cargo_v2_completed_mission_handoff";
        private const string CompletionStarsKey = "cargo_v2_completed_mission_stars";
        private const string TruckResourcePath = "CargoV2/Truck/MOD_Truck_Premium";
        private const string MissionResourcePath = "CargoV2/Mission/MOD_Mission_CargoDepot";
        private const float RouteLength = 190f;
        private const float HudX = 18f;
        private const float HudY = 18f;
        private const float HudWidth = 500f;
        private const float HudHeight = 300f;
        private static readonly Vector3 MissionOrigin = new Vector3(1000f, 0f, 1000f);
        private static readonly Vector3[] CheckpointPositions =
        {
            MissionOrigin + new Vector3(0f, 0.7f, 2f),
            MissionOrigin + new Vector3(0f, 0.7f, 60f),
            MissionOrigin + new Vector3(0f, 0.7f, 110f),
            MissionOrigin + new Vector3(0f, 0.7f, 155f),
        };

        private static SCR_MissionRuntimeDirector activeInstance;
        private readonly List<GameObject> spawnedObjects = new List<GameObject>();
        private readonly List<Material> runtimeMaterials = new List<Material>();

        private SO_GameBalance balance;
        private SO_GameBalance.MissionBalance mission;
        private CargoV2ContractSpec contract;
        private CargoV2TruckRuntimeStats truckStats;
        private Rigidbody truckBody;
        private Camera missionCamera;
        private GameObject pickupCargoVisual;
        private GameObject loadedCargoVisual;
        private Material navy;
        private Material gold;
        private Material cyan;
        private Material road;
        private bool initialized;
        private bool terminal;
        private bool succeeded;
        private bool paused;
        private bool cargoLoaded;
        private bool usingRealTruckAsset;
        private bool usingRealMissionAsset;
        private bool abandonRequested;
        private bool applicationQuitting;
        private float remainingSeconds;
        private float damage;
        private float nextAutosave;
        private int checkpointIndex;
        private int completionStars;
        private string statusReason = string.Empty;
        private float throttleInput;
        private float steeringInput;
        private bool hardBrake;

        public static bool IsRunning => activeInstance != null;

        public static bool LaunchInPlace(int missionId)
        {
            if (missionId < 1 || missionId > 20 || IsRunning) return false;

            if (SCR_ActiveDeliveryStore.TryLoadAny(out SCR_ActiveDeliveryStore.Snapshot active) &&
                active.MissionId != missionId)
            {
                Debug.LogWarning(
                    $"[CARGO V2][MISSION] Delivery {active.MissionId:00} is already active; resume or abandon it before starting {missionId:00}.");
                return false;
            }

            GameObject host = new GameObject("CARGO_V2_DrivingMissionRuntime");
            SCR_MissionRuntimeDirector director = host.AddComponent<SCR_MissionRuntimeDirector>();
            if (director.Initialize(missionId)) return true;
            Destroy(host);
            return false;
        }

        private bool Initialize(int missionId)
        {
            if (initialized || activeInstance != null) return false;

            balance = ScriptableObject.CreateInstance<SO_GameBalance>();
            balance.name = "SO_GameBalance_MissionRuntime";
            balance.ResetToApprovedDefaults();
            mission = balance.GetMission(missionId);
            contract = CargoV2LogisticsCatalog.BuildContract(mission);
            if (mission == null || contract == null) return false;
            if (!CargoV2LogisticsCatalog.Validate(out string catalogError))
            {
                Debug.LogError($"[CARGO V2][MISSION] Logistics catalog invalid: {catalogError}");
                return false;
            }

            bool hasResume = SCR_ActiveDeliveryStore.TryLoad(missionId, out SCR_ActiveDeliveryStore.Snapshot resume);
            truckStats = ResolveTruckStats(hasResume ? resume.TruckId : SCR_CompanyProgressStore.GetSelectedTruckId());
            if (string.IsNullOrEmpty(truckStats.Id)) return false;

            initialized = true;
            activeInstance = this;
            Time.timeScale = 1f;
            PlayerPrefs.SetInt(PendingMissionKey, missionId);
            PlayerPrefs.DeleteKey(CompletionHandoffKey);
            PlayerPrefs.DeleteKey(CompletionStarsKey);
            PlayerPrefs.Save();

            remainingSeconds = Mathf.Max(25f, mission.timeSeconds);
            BuildWorld();
            if (truckBody == null || missionCamera == null) return false;

            if (hasResume) RestoreActiveDelivery(resume);
            else
            {
                ResetTruckToCheckpoint(0, false);
                SaveActiveDelivery();
            }

            nextAutosave = Time.unscaledTime + 2f;
            return true;
        }

        private CargoV2TruckRuntimeStats ResolveTruckStats(string truckId)
        {
            CargoV2TruckSpec spec = CargoV2LogisticsCatalog.GetTruck(truckId);
            if (spec != null &&
                SCR_CompanyProgressStore.TryGetTruckState(truckId, out SCR_CompanyProgressStore.TruckState state))
            {
                return CargoV2LogisticsCatalog.GetRuntimeStats(
                    spec, state.EngineLevel, state.HandlingLevel, state.DurabilityLevel);
            }
            return SCR_CompanyProgressStore.GetSelectedRuntimeStats();
        }

        private void Update()
        {
            if (!initialized) return;

            if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.P)) TogglePause();
            if (!terminal && !paused && Input.GetKeyDown(KeyCode.R)) RecoverTruck();

            if (terminal || paused)
            {
                throttleInput = 0f;
                steeringInput = 0f;
                hardBrake = false;
                return;
            }

            ReadInput();
            remainingSeconds -= Time.deltaTime;
            if (remainingSeconds <= 0f)
            {
                remainingSeconds = 0f;
                FailMission("CONTRACT TIME EXPIRED");
                return;
            }

            if (truckBody != null &&
                (truckBody.position.y < MissionOrigin.y - 5f ||
                 Vector3.Distance(truckBody.position, MissionOrigin) > 320f))
            {
                RecoverTruck();
            }

            if (Time.unscaledTime >= nextAutosave)
            {
                nextAutosave = Time.unscaledTime + 2f;
                SaveActiveDelivery();
            }
        }

        private void FixedUpdate()
        {
            if (!initialized || terminal || paused || truckBody == null) return;

            Vector3 forward = truckBody.transform.forward;
            Vector3 right = truckBody.transform.right;
            float forwardSpeed = Vector3.Dot(truckBody.velocity, forward);
            float overload = contract.cargoWeightTons > truckStats.CargoCapacityTons ? 0.72f : 1f;
            float maxForward = truckStats.TopSpeedMetersPerSecond * overload;
            float maxReverse = Mathf.Min(5f, maxForward * 0.42f);
            float acceleration = truckStats.AccelerationMetersPerSecondSquared * overload;

            if (hardBrake || (throttleInput < -0.05f && forwardSpeed > 0.75f))
            {
                Vector3 planar = new Vector3(truckBody.velocity.x, 0f, truckBody.velocity.z);
                truckBody.AddForce(-planar * 4.8f, ForceMode.Acceleration);
            }
            else if (Mathf.Abs(throttleInput) > 0.02f)
            {
                truckBody.AddForce(forward * (throttleInput * acceleration), ForceMode.Acceleration);
            }

            float direction = Mathf.Abs(forwardSpeed) < 0.25f ? 1f : Mathf.Sign(forwardSpeed);
            float authority = Mathf.Clamp01(Mathf.Abs(forwardSpeed) / 3f + 0.25f);
            float yaw = steeringInput * truckStats.SteeringDegreesPerSecond *
                        authority * direction * Time.fixedDeltaTime;
            truckBody.MoveRotation(truckBody.rotation * Quaternion.Euler(0f, yaw, 0f));

            float lateralSpeed = Vector3.Dot(truckBody.velocity, right);
            truckBody.AddForce(-right * lateralSpeed * 3.1f, ForceMode.Acceleration);

            Vector3 velocity = truckBody.velocity;
            Vector3 horizontal = new Vector3(velocity.x, 0f, velocity.z);
            float signedSpeed = Vector3.Dot(horizontal, truckBody.transform.forward);
            float allowed = signedSpeed < 0f ? maxReverse : maxForward;
            if (horizontal.magnitude > allowed)
            {
                horizontal = horizontal.normalized * allowed;
                truckBody.velocity = new Vector3(horizontal.x, velocity.y, horizontal.z);
            }
        }

        private void LateUpdate()
        {
            if (missionCamera == null || truckBody == null) return;
            Vector3 target = truckBody.position + Vector3.up * 1.6f;
            Vector3 desired = target - truckBody.transform.forward * 10.5f + Vector3.up * 5.2f;
            float positionT = 1f - Mathf.Exp(-6f * Time.unscaledDeltaTime);
            float rotationT = 1f - Mathf.Exp(-8f * Time.unscaledDeltaTime);
            missionCamera.transform.position = Vector3.Lerp(missionCamera.transform.position, desired, positionT);
            Quaternion look = Quaternion.LookRotation(target - missionCamera.transform.position, Vector3.up);
            missionCamera.transform.rotation = Quaternion.Slerp(missionCamera.transform.rotation, look, rotationT);
        }
    }
}
