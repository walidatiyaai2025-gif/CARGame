using UnityEngine;

namespace CargoV2.Logic
{
    [DisallowMultipleComponent]
    public sealed class SCR_WorldMapMissionNode : MonoBehaviour
    {
        [SerializeField, Min(1)] private int missionId = 1;
        [SerializeField] private SCR_WorldMapRouteController routeController;

        public int MissionId => missionId;
        public bool IsSelected => routeController != null && routeController.SelectedMissionId == missionId;
        public WorldMapNodeState State => routeController != null
            ? routeController.GetNodeState(missionId)
            : WorldMapNodeState.Locked;

        public void Bind(SCR_WorldMapRouteController controller, int id)
        {
            routeController = controller;
            missionId = Mathf.Max(1, id);
        }

        public bool Select()
        {
            if (routeController == null)
            {
                Debug.LogWarning($"[CARGO V2][LOGIC_TEAM] Mission node {missionId} has no WorldMap route controller.");
                return false;
            }

            return routeController.TrySelectMission(missionId);
        }

        private void OnMouseUpAsButton()
        {
            Select();
        }
    }
}
