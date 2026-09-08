#!/usr/bin/env python3
"""Fail-closed source guard for CARGO V2 contract/truck capacity recommendations."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "Assets/_Project/Data/CargoV2LogisticsCatalog.cs"

TRUCK_RE = re.compile(
    r'Truck\("(?P<id>[^"]+)",\s*"[^"]+",\s*'
    r'(?P<price>\d+),\s*\d+,\s*'
    r'[\d.]+f,\s*[\d.]+f,\s*[\d.]+f,\s*'
    r'(?P<capacity>[\d.]+)f,',
)


def fail(message: str) -> None:
    raise SystemExit(f"CARGO V2 contract capacity guard FAIL: {message}")


def main() -> None:
    source = CATALOG.read_text(encoding="utf-8")
    trucks: list[tuple[str, int, float]] = []
    for match in TRUCK_RE.finditer(source):
        trucks.append(
            (
                match.group("id"),
                int(match.group("price")),
                float(match.group("capacity")),
            )
        )

    if len(trucks) < 4:
        fail(f"expected at least four declared trucks, found {len(trucks)}")
    if len({truck_id for truck_id, _, _ in trucks}) != len(trucks):
        fail("truck ids are not unique")

    required_source_contracts = (
        "string recommendedTruck = SelectRecommendedTruckId(weight);",
        "private static string SelectRecommendedTruckId(float cargoWeightTons)",
        "truck.cargoCapacityTons < cargoWeightTons",
        "truck.purchasePrice < best.purchasePrice",
        "!CanTruckCarry(contract.recommendedTruckId, contract)",
    )
    for contract in required_source_contracts:
        if contract not in source:
            fail(f"missing source invariant: {contract}")

    if 'weight > 16f' in source or 'weight > 10f' in source:
        fail("hard-coded cargo-weight recommendation thresholds returned")

    mission_recommendations: dict[int, str] = {}
    for mission_id in range(1, 21):
        route_index = (mission_id - 1) % 10
        cairo = mission_id <= 10
        weight = 3.5 + route_index * 1.15 + (0.0 if cairo else 1.4)
        capable = [truck for truck in trucks if truck[2] + 1e-6 >= weight]
        if not capable:
            fail(f"mission {mission_id:02d} weight {weight:.2f}t has no capable truck")

        recommended = min(capable, key=lambda truck: (truck[1], truck[2], truck[0]))
        mission_recommendations[mission_id] = recommended[0]
        if recommended[2] + 1e-6 < weight:
            fail(
                f"mission {mission_id:02d} recommendation {recommended[0]} "
                f"capacity {recommended[2]:.2f}t is below {weight:.2f}t"
            )

    for heavy_id in (19, 20):
        if mission_recommendations[heavy_id] != "mammoth_6x4":
            fail(
                f"mission {heavy_id:02d} must resolve to mammoth_6x4, "
                f"got {mission_recommendations[heavy_id]}"
            )

    print(
        "CARGO V2 contract capacity guard PASS: "
        "20/20 generated contracts have a deterministic capable recommendation; "
        "missions 19-20 correctly require mammoth_6x4."
    )


if __name__ == "__main__":
    main()
