using System;

namespace CargoV2.Logic
{
    public enum WorldMapNodeState
    {
        Locked = 0,
        Available = 1,
        Completed = 2,
    }

    public static class WorldMapProgression
    {
        public static int ClampHighestCompleted(int highestCompletedMissionId, int missionCount)
        {
            if (missionCount <= 0) return 0;
            return Math.Max(0, Math.Min(highestCompletedMissionId, missionCount));
        }

        public static int GetHighestUnlockedMissionId(int highestCompletedMissionId, int missionCount)
        {
            if (missionCount <= 0) return 0;
            int completed = ClampHighestCompleted(highestCompletedMissionId, missionCount);
            return Math.Min(missionCount, completed + 1);
        }

        public static bool IsValidMissionId(int missionId, int missionCount)
        {
            return missionCount > 0 && missionId >= 1 && missionId <= missionCount;
        }

        public static WorldMapNodeState GetNodeState(int missionId, int highestCompletedMissionId, int missionCount)
        {
            if (!IsValidMissionId(missionId, missionCount)) return WorldMapNodeState.Locked;

            int completed = ClampHighestCompleted(highestCompletedMissionId, missionCount);
            if (missionId <= completed) return WorldMapNodeState.Completed;
            if (missionId == completed + 1) return WorldMapNodeState.Available;
            return WorldMapNodeState.Locked;
        }

        public static bool CanSelect(int missionId, int highestCompletedMissionId, int missionCount)
        {
            return GetNodeState(missionId, highestCompletedMissionId, missionCount) != WorldMapNodeState.Locked;
        }

        public static bool CanAdvanceProgress(int missionId, int highestCompletedMissionId, int missionCount)
        {
            if (!IsValidMissionId(missionId, missionCount)) return false;
            int completed = ClampHighestCompleted(highestCompletedMissionId, missionCount);
            return missionId == completed + 1;
        }
    }
}
