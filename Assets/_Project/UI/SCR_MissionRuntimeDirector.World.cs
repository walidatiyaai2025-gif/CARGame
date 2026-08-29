using System;
using UnityEngine;

namespace CargoV2.UI
{
    public sealed partial class SCR_MissionRuntimeDirector
    {
        private void BuildWorld()
        {
            Shader shader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            navy = CreateMaterial(shader, new Color(0.018f, 0.045f, 0.105f));
            gold = CreateMaterial(shader, new Color(0.96f, 0.60f, 0.06f));
            cyan = CreateMaterial(shader, new Color(0.05f, 0.70f, 0.92f));
            road = CreateMaterial(shader, new Color(0.075f, 0.085f, 0.105f));

            BuildRoad();
            BuildTruck();
            BuildCargoAndDepot();
            BuildTriggers();
            BuildCameraAndLighting();
        }

        private void BuildRoad()
        {
            GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ground.name = "MissionGround";
            ground.transform.position = MissionOrigin + new Vector3(0f, -0.65f, RouteLength * 0.5f);
            ground.transform.localScale = new Vector3(42f, 1f, RouteLength + 38f);
            SetMaterial(ground, navy);
            spawnedObjects.Add(ground);

            GameObject roadGo = GameObject.CreatePrimitive(PrimitiveType.Cube);
            roadGo.name = "CargoRouteRoad";
            roadGo.transform.position = MissionOrigin + new Vector3(0f, -0.08f, RouteLength * 0.5f);
            roadGo.transform.localScale = new Vector3(13f, 0.18f, RouteLength + 12f);
            SetMaterial(roadGo, road);
            spawnedObjects.Add(roadGo);

            for (int z = 8; z < RouteLength; z += 12)
            {
                GameObject line = GameObject.CreatePrimitive(PrimitiveType.Cube);
                line.name = "RouteCenterMark";
                line.transform.position = MissionOrigin + new Vector3(0f, 0.04f, z);
                line.transform.localScale = new Vector3(0.18f, 0.03f, 5f);
                SetMaterial(line, gold);
                DisableCollider(line);
                spawnedObjects.Add(line);
            }

            for (int side = -1; side <= 1; side += 2)
            {
                GameObject rail = GameObject.CreatePrimitive(PrimitiveType.Cube);
                rail.name = side < 0 ? "LeftRouteBarrier" : "RightRouteBarrier";
                rail.transform.position = MissionOrigin + new Vector3(side * 7.2f, 0.65f, RouteLength * 0.5f);
                rail.transform.localScale = new Vector3(0.35f, 1.25f, RouteLength + 10f);
                SetMaterial(rail, gold);
                spawnedObjects.Add(rail);
            }

            CreateObstacle(-3.8f, 82f, 1.5f, 4.5f);
            CreateObstacle(3.6f, 126f, 1.6f, 5f);
            CreateObstacle(-3.2f, 164f, 1.4f, 4f);
        }

        private void CreateObstacle(float x, float z, float width, float length)
        {
            GameObject obstacle = GameObject.CreatePrimitive(PrimitiveType.Cube);
            obstacle.name = "RouteObstacle";
            obstacle.transform.position = MissionOrigin + new Vector3(x, 0.75f, z);
            obstacle.transform.localScale = new Vector3(width, 1.5f, length);
            SetMaterial(obstacle, gold);
            spawnedObjects.Add(obstacle);
        }

        private void BuildTruck()
        {
            GameObject root = new GameObject("PlayerCargoTruck");
            root.transform.position = CheckpointPositions[0];

            BoxCollider collider = root.AddComponent<BoxCollider>();
            collider.center = new Vector3(0f, 1.0f, 0f);
            collider.size = new Vector3(2.8f, 2.4f, 6.8f);

            truckBody = root.AddComponent<Rigidbody>();
            truckBody.mass = 4200f;
            truckBody.drag = 0.18f;
            truckBody.angularDrag = 4f;
            truckBody.centerOfMass = new Vector3(0f, -0.45f, 0.4f);
            truckBody.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;

            TruckCollisionReporter reporter = root.AddComponent<TruckCollisionReporter>();
            reporter.Owner = this;
            spawnedObjects.Add(root);

            GameObject source = Resources.Load<GameObject>(TruckResourcePath);
            if (source != null)
            {
                GameObject visual = Instantiate(source, root.transform);
                visual.name = "PremiumTruckVisual";
                visual.transform.localPosition = new Vector3(0f, 0f, 3.55f);
                visual.transform.localRotation = Quaternion.Euler(0f, 180f, 0f);
                visual.transform.localScale = Vector3.one;
                RemoveChildColliders(visual);
                usingRealTruckAsset = true;
            }
            else
            {
                BuildFallbackTruckVisual(root.transform);
            }
        }

        private void BuildFallbackTruckVisual(Transform parent)
        {
            GameObject cab = GameObject.CreatePrimitive(PrimitiveType.Cube);
            cab.name = "TruckCab_Fallback";
            cab.transform.SetParent(parent, false);
            cab.transform.localPosition = new Vector3(0f, 1.2f, 1.6f);
            cab.transform.localScale = new Vector3(2.5f, 2.4f, 2.2f);
            SetMaterial(cab, gold);
            DisableCollider(cab);

            GameObject trailer = GameObject.CreatePrimitive(PrimitiveType.Cube);
            trailer.name = "TruckTrailer_Fallback";
            trailer.transform.SetParent(parent, false);
            trailer.transform.localPosition = new Vector3(0f, 1.55f, -1.6f);
            trailer.transform.localScale = new Vector3(2.8f, 2.8f, 4.5f);
            SetMaterial(trailer, navy);
            DisableCollider(trailer);
        }

        private void BuildCargoAndDepot()
        {
            GameObject source = Resources.Load<GameObject>(MissionResourcePath);
            Transform cargoSource = source != null ? FindChildRecursive(source.transform, "CargoCrate") : null;
            Transform bandSource = source != null ? FindChildRecursive(source.transform, "CargoCrateBand") : null;
            Transform depotSource = source != null ? FindChildRecursive(source.transform, "DepotPallet") : null;
            usingRealMissionAsset = cargoSource != null && depotSource != null;

            GameObject pickupHost = new GameObject("PickupCargoVisual");
            pickupHost.transform.position = MissionOrigin + new Vector3(0f, 0.15f, 20f);
            spawnedObjects.Add(pickupHost);
            if (cargoSource != null)
            {
                ClonePart(cargoSource, pickupHost.transform, "PickupCargoMesh");
                if (bandSource != null) ClonePart(bandSource, pickupHost.transform, "PickupCargoBand");
            }
            else
            {
                GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
                box.transform.SetParent(pickupHost.transform, false);
                box.transform.localPosition = new Vector3(0f, 0.8f, 0f);
                box.transform.localScale = new Vector3(2f, 1.6f, 2f);
                SetMaterial(box, gold);
                DisableCollider(box);
            }
            pickupCargoVisual = pickupHost;

            GameObject depotHost = new GameObject("DeliveryDepotVisual");
            depotHost.transform.position = MissionOrigin + new Vector3(0f, 0.15f, RouteLength - 8f);
            spawnedObjects.Add(depotHost);
            if (depotSource != null)
            {
                ClonePart(depotSource, depotHost.transform, "DeliveryDepotMesh");
            }
            else
            {
                GameObject depot = GameObject.CreatePrimitive(PrimitiveType.Cube);
                depot.transform.SetParent(depotHost.transform, false);
                depot.transform.localPosition = new Vector3(0f, 1.4f, 4f);
                depot.transform.localScale = new Vector3(8f, 2.8f, 2f);
                SetMaterial(depot, navy);
                DisableCollider(depot);
            }

            BuildZoneDisc("PICKUP", MissionOrigin + new Vector3(0f, 0.05f, 20f), cyan);
            BuildZoneDisc("DELIVERY", MissionOrigin + new Vector3(0f, 0.05f, RouteLength - 8f), gold);
        }

        private void BuildTriggers()
        {
            CreateTrigger("PickupTrigger", MissionOrigin + new Vector3(0f, 1f, 20f), new Vector3(9f, 3f, 9f), TriggerKind.Pickup, 0);
            CreateTrigger("Checkpoint01", MissionOrigin + new Vector3(0f, 1f, 60f), new Vector3(11f, 3f, 4f), TriggerKind.Checkpoint, 1);
            CreateTrigger("Checkpoint02", MissionOrigin + new Vector3(0f, 1f, 110f), new Vector3(11f, 3f, 4f), TriggerKind.Checkpoint, 2);
            CreateTrigger("Checkpoint03", MissionOrigin + new Vector3(0f, 1f, 155f), new Vector3(11f, 3f, 4f), TriggerKind.Checkpoint, 3);
            CreateTrigger("DeliveryTrigger", MissionOrigin + new Vector3(0f, 1f, RouteLength - 8f), new Vector3(9f, 3f, 9f), TriggerKind.Delivery, 3);
        }

        private void CreateTrigger(string name, Vector3 position, Vector3 size, TriggerKind kind, int checkpoint)
        {
            GameObject host = new GameObject(name);
            host.transform.position = position;
            BoxCollider collider = host.AddComponent<BoxCollider>();
            collider.isTrigger = true;
            collider.size = size;
            MissionTrigger trigger = host.AddComponent<MissionTrigger>();
            trigger.Owner = this;
            trigger.Kind = kind;
            trigger.Checkpoint = checkpoint;
            spawnedObjects.Add(host);
        }

        private void BuildZoneDisc(string name, Vector3 position, Material material)
        {
            GameObject disc = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            disc.name = name + "_ZONE";
            disc.transform.position = position;
            disc.transform.localScale = new Vector3(4.2f, 0.04f, 4.2f);
            SetMaterial(disc, material);
            DisableCollider(disc);
            spawnedObjects.Add(disc);
        }

        private void BuildCameraAndLighting()
        {
            GameObject cameraGo = new GameObject("MissionDrivingCamera");
            missionCamera = cameraGo.AddComponent<Camera>();
            missionCamera.depth = 100f;
            missionCamera.fieldOfView = 62f;
            missionCamera.nearClipPlane = 0.15f;
            missionCamera.farClipPlane = 600f;
            missionCamera.transform.position = MissionOrigin + new Vector3(0f, 6f, -12f);
            spawnedObjects.Add(cameraGo);

            GameObject keyGo = new GameObject("MissionKeyLight");
            Light key = keyGo.AddComponent<Light>();
            key.type = LightType.Directional;
            key.intensity = 1.15f;
            key.color = new Color(1f, 0.92f, 0.78f);
            key.transform.rotation = Quaternion.Euler(48f, -32f, 0f);
            spawnedObjects.Add(keyGo);

            GameObject fillGo = new GameObject("MissionFillLight");
            Light fill = fillGo.AddComponent<Light>();
            fill.type = LightType.Directional;
            fill.intensity = 0.38f;
            fill.color = new Color(0.22f, 0.45f, 0.9f);
            fill.transform.rotation = Quaternion.Euler(28f, 142f, 0f);
            spawnedObjects.Add(fillGo);
        }

        private void AttachCargoToTruck()
        {
            if (truckBody == null || loadedCargoVisual != null) return;

            GameObject source = Resources.Load<GameObject>(MissionResourcePath);
            Transform cargoSource = source != null ? FindChildRecursive(source.transform, "CargoCrate") : null;
            Transform bandSource = source != null ? FindChildRecursive(source.transform, "CargoCrateBand") : null;

            GameObject host = new GameObject("LoadedCargo");
            host.transform.SetParent(truckBody.transform, false);
            host.transform.localPosition = new Vector3(0f, 1.4f, -1.3f);
            host.transform.localRotation = Quaternion.identity;
            if (cargoSource != null)
            {
                ClonePart(cargoSource, host.transform, "LoadedCargoMesh");
                if (bandSource != null) ClonePart(bandSource, host.transform, "LoadedCargoBand");
            }
            else
            {
                GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
                box.name = "LoadedCargo_Fallback";
                box.transform.SetParent(host.transform, false);
                box.transform.localScale = new Vector3(1.4f, 1.2f, 1.6f);
                SetMaterial(box, gold);
                DisableCollider(box);
            }
            loadedCargoVisual = host;
        }
    }
}
