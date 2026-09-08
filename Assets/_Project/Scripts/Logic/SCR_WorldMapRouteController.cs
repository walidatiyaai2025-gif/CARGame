using System;
using CargoV2.Data;
using UnityEngine;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapRouteController : MonoBehaviour
    {
        [SerializeField] private SO_GameBalance gameBalance;
        [SerializeField, Min(0)] private int highestCompletedMissionId;
        [SerializeField, Min(1)] private int selectedMissionId = 1;

        private SO_GameBalance transientBalance;

        public event Action<int> SelectionChanged;
        public event Action<int> ProgressChanged;

        public int MissionCount => ActiveBalance != null && ActiveBalance.missions != null
            ? ActiveBalance.missions.Count
            : 0;

        public int HighestCompletedMissionId =>
            WorldMapProgression.ClampHighestCompleted(highestCompletedMissionId, MissionCount);

        public int HighestUnlockedMissionId =>
            WorldMapProgression.GetHighestUnlockedMissionId(HighestCompletedMissionId, MissionCount);

        public int SelectedMissionId => selectedMissionId;

        public SO_GameBalance.MissionBalance SelectedMission => GetMission(selectedMissionId);

        private SO_GameBalance ActiveBalance => gameBalance != null ? gameBalance : transientBalance;

        private void Awake()
        {
            EnsureBalance();
            NormalizeState();
        }

        private void OnDestroy()
        {
            if (transientBalance != null)
            {
                Destroy(transientBalance);
                transientBalance = null;
            }
        }

        public void ConfigureBalance(SO_GameBalance balance)
        {
            gameBalance = balance;
            if (transientBalance != null)
            {
                Destroy(transientBalance);
                transientBalance = null;
            }

            EnsureBalance();
            NormalizeState();
        }

        public void SetProgress(int completedMissionId)
        {
            EnsureBalance();
            int next = WorldMapProgression.ClampHighestCompleted(completedMissionId, MissionCount);
            if (next == highestCompletedMissionId)
            {
                NormalizeSelection();
                return;
            }

            highestCompletedMissionId = next;
            NormalizeSelection();
            ProgressChanged?.Invoke(highestCompletedMissionId);
        }

        public bool TrySelectMission(int missionId)
        {
            EnsureBalance();
            if (!WorldMapProgression.CanSelect(missionId, HighestCompletedMissionId, MissionCount))
            {
                return false;
            }

            if (selectedMissionId == missionId)
            {
                return true;
            }

            selectedMissionId = missionId;
            SelectionChanged?.Invoke(selectedMissionId);
            return true;
        }

        public bool TryCompleteSelectedMission()
        {
            return TryCompleteMission(selectedMissionId);
        }

        public bool TryCompleteMission(int missionId)
        {
            EnsureBalance();
            int missionCount = MissionCount;
            if (!WorldMapProgression.IsValidMissionId(missionId, missionCount))
            {
                return false;
            }

            WorldMapNodeState state = WorldMapProgression.GetNodeState(
                missionId,
                HighestCompletedMissionId,
                missionCount);

            if (state == WorldMapNodeState.Completed)
            {
                return true;
            }

            if (!WorldMapProgression.CanAdvanceProgress(missionId, HighestCompletedMissionId, missionCount))
            {
                return false;
            }

            highestCompletedMissionId = missionId;
            selectedMissionId = WorldMapProgression.GetHighestUnlockedMissionId(
                highestCompletedMissionId,
                missionCount);

            ProgressChanged?.Invoke(highestCompletedMissionId);
            SelectionChanged?.Invoke(selectedMissionId);
            return true;
        }

        public WorldMapNodeState GetNodeState(int missionId)
        {
            EnsureBalance();
            return WorldMapProgression.GetNodeState(missionId, HighestCompletedMissionId, MissionCount);
        }

        public SO_GameBalance.MissionBalance GetMission(int missionId)
        {
            EnsureBalance();
            if (!WorldMapProgression.IsValidMissionId(missionId, MissionCount))
            {
                return null;
            }

            return ActiveBalance.GetMission(missionId);
        }

        private void EnsureBalance()
        {
            if (gameBalance != null && gameBalance.missions != null && gameBalance.missions.Count > 0)
            {
                return;
            }

            if (transientBalance != null)
            {
                return;
            }

            try
            {
                transientBalance = ScriptableObject.CreateInstance<SO_GameBalance>();
                transientBalance.name = "SO_GameBalance_RuntimeFallback";
                transientBalance.ResetToApprovedDefaults();
                Debug.LogWarning(
                    "[CARGO V2][LOGIC_TEAM] WorldMap has no assigned SO_GameBalance; using the approved transient defaults for this session.");
            }
            catch (Exception exception)
            {
                Debug.LogError($"[CARGO V2][LOGIC_TEAM] Failed to create WorldMap balance fallback: {exception.Message}");
            }
        }

        private void NormalizeState()
        {
            highestCompletedMissionId = WorldMapProgression.ClampHighestCompleted(
                highestCompletedMissionId,
                MissionCount);
            NormalizeSelection();
        }

        private void NormalizeSelection()
        {
            int missionCount = MissionCount;
            if (missionCount <= 0)
            {
                selectedMissionId = 0;
                return;
            }

            if (!WorldMapProgression.CanSelect(selectedMissionId, HighestCompletedMissionId, missionCount))
            {
                selectedMissionId = WorldMapProgression.GetHighestUnlockedMissionId(
                    HighestCompletedMissionId,
                    missionCount);
            }
        }
    }
}
