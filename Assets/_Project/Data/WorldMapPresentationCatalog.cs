using System;
using System.Collections.Generic;

namespace CargoV2.Data
{
    public enum WorldMapRouteRegion
    {
        Cairo = 0,
        Dubai = 1,
    }

    public readonly struct WorldMapNodePresentation
    {
        public WorldMapNodePresentation(
            int missionId,
            WorldMapRouteRegion region,
            int routeIndex,
            float normalizedX,
            float normalizedY,
            float emphasisScale)
        {
            MissionId = missionId;
            Region = region;
            RouteIndex = routeIndex;
            NormalizedX = normalizedX;
            NormalizedY = normalizedY;
            EmphasisScale = emphasisScale;
        }

        public int MissionId { get; }
        public WorldMapRouteRegion Region { get; }
        public int RouteIndex { get; }
        public float NormalizedX { get; }
        public float NormalizedY { get; }
        public float EmphasisScale { get; }
    }

    public static class WorldMapPresentationCatalog
    {
        private static readonly WorldMapNodePresentation[] Nodes =
        {
            Node(1, WorldMapRouteRegion.Cairo, 1, -0.86f, -0.34f, 1.16f),
            Node(2, WorldMapRouteRegion.Cairo, 2, -0.72f, -0.16f, 1.00f),
            Node(3, WorldMapRouteRegion.Cairo, 3, -0.57f,  0.02f, 1.00f),
            Node(4, WorldMapRouteRegion.Cairo, 4, -0.40f,  0.17f, 1.00f),
            Node(5, WorldMapRouteRegion.Cairo, 5, -0.20f,  0.11f, 1.00f),
            Node(6, WorldMapRouteRegion.Cairo, 6, -0.01f,  0.27f, 1.00f),
            Node(7, WorldMapRouteRegion.Cairo, 7,  0.18f,  0.42f, 1.00f),
            Node(8, WorldMapRouteRegion.Cairo, 8,  0.35f,  0.30f, 1.00f),
            Node(9, WorldMapRouteRegion.Cairo, 9,  0.51f,  0.45f, 1.00f),
            Node(10, WorldMapRouteRegion.Cairo, 10, 0.65f,  0.59f, 1.14f),

            Node(11, WorldMapRouteRegion.Dubai, 1,  0.78f,  0.37f, 1.16f),
            Node(12, WorldMapRouteRegion.Dubai, 2,  0.86f,  0.17f, 1.00f),
            Node(13, WorldMapRouteRegion.Dubai, 3,  0.72f, -0.03f, 1.00f),
            Node(14, WorldMapRouteRegion.Dubai, 4,  0.56f, -0.19f, 1.00f),
            Node(15, WorldMapRouteRegion.Dubai, 5,  0.36f, -0.33f, 1.00f),
            Node(16, WorldMapRouteRegion.Dubai, 6,  0.13f, -0.45f, 1.00f),
            Node(17, WorldMapRouteRegion.Dubai, 7, -0.10f, -0.57f, 1.00f),
            Node(18, WorldMapRouteRegion.Dubai, 8, -0.34f, -0.48f, 1.00f),
            Node(19, WorldMapRouteRegion.Dubai, 9, -0.58f, -0.61f, 1.00f),
            Node(20, WorldMapRouteRegion.Dubai, 10, -0.79f, -0.51f, 1.14f),
        };

        private static readonly IReadOnlyList<WorldMapNodePresentation> ReadOnlyNodes =
            Array.AsReadOnly(Nodes);

        static WorldMapPresentationCatalog()
        {
            if (!Validate(out string error))
            {
                throw new InvalidOperationException($"Invalid CARGO V2 WorldMap presentation catalog: {error}");
            }
        }

        public static IReadOnlyList<WorldMapNodePresentation> All => ReadOnlyNodes;

        public static bool TryGet(int missionId, out WorldMapNodePresentation node)
        {
            if (missionId >= 1 && missionId <= Nodes.Length)
            {
                WorldMapNodePresentation candidate = Nodes[missionId - 1];
                if (candidate.MissionId == missionId)
                {
                    node = candidate;
                    return true;
                }
            }

            for (int i = 0; i < Nodes.Length; i++)
            {
                if (Nodes[i].MissionId == missionId)
                {
                    node = Nodes[i];
                    return true;
                }
            }

            node = default;
            return false;
        }

        public static bool Validate(out string error)
        {
            if (Nodes.Length != 20)
            {
                error = $"expected 20 nodes, found {Nodes.Length}";
                return false;
            }

            var seen = new HashSet<int>();
            var regionCounts = new Dictionary<WorldMapRouteRegion, int>();

            for (int i = 0; i < Nodes.Length; i++)
            {
                WorldMapNodePresentation node = Nodes[i];

                if (node.MissionId < 1 || node.MissionId > 20 || !seen.Add(node.MissionId))
                {
                    error = $"invalid or duplicate mission id {node.MissionId}";
                    return false;
                }

                if (!IsFinite(node.NormalizedX) || !IsFinite(node.NormalizedY) ||
                    node.NormalizedX < -1f || node.NormalizedX > 1f ||
                    node.NormalizedY < -1f || node.NormalizedY > 1f)
                {
                    error = $"mission {node.MissionId} has invalid normalized coordinates";
                    return false;
                }

                if (!IsFinite(node.EmphasisScale) || node.EmphasisScale < 0.75f || node.EmphasisScale > 1.5f)
                {
                    error = $"mission {node.MissionId} has invalid emphasis scale";
                    return false;
                }

                if (node.RouteIndex < 1 || node.RouteIndex > 10)
                {
                    error = $"mission {node.MissionId} has invalid route index";
                    return false;
                }

                regionCounts.TryGetValue(node.Region, out int count);
                regionCounts[node.Region] = count + 1;
            }

            for (int missionId = 1; missionId <= 20; missionId++)
            {
                if (!seen.Contains(missionId))
                {
                    error = $"missing mission id {missionId}";
                    return false;
                }
            }

            if (!regionCounts.TryGetValue(WorldMapRouteRegion.Cairo, out int cairoCount) || cairoCount != 10 ||
                !regionCounts.TryGetValue(WorldMapRouteRegion.Dubai, out int dubaiCount) || dubaiCount != 10)
            {
                error = "expected exactly 10 Cairo nodes and 10 Dubai nodes";
                return false;
            }

            error = string.Empty;
            return true;
        }

        private static WorldMapNodePresentation Node(
            int missionId,
            WorldMapRouteRegion region,
            int routeIndex,
            float x,
            float y,
            float scale)
        {
            return new WorldMapNodePresentation(missionId, region, routeIndex, x, y, scale);
        }

        private static bool IsFinite(float value)
        {
            return !float.IsNaN(value) && !float.IsInfinity(value);
        }
    }
}
