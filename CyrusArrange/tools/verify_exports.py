"""Independently validate native JSON exports from a qualified furniture test run."""
import argparse
import json
import math
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run", type=Path)
    args = parser.parse_args()
    run = args.run.resolve()
    names = ["tv-console", "open-shelf", "hole", "transformed", "reopened"]
    counts = {}
    for name in names:
        data = json.loads((run / (name + ".json")).read_text(encoding="utf-8"), parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
        assert data["schema"] == 1 and data["coordinate_space"] == "world_mm"
        spacing = data["settings"]["cell_size_mm"]
        minimum = data["settings"]["minimum_clearance_mm"]
        cells_total = 0
        divider_cells = 0
        for region in data["regions"]:
            cells = region["cells"]
            assert math.isclose(region["sampled_area_mm2"], len(cells) * spacing * spacing)
            assert math.isclose(region["usable_area_mm2"], sum(c["usable"] for c in cells) * spacing * spacing)
            finite = [c["clearance_mm"] for c in cells if c["clearance_mm"] is not None]
            assert region["open_above"] == (len(finite) == 0)
            assert region["minimum_clearance_mm"] == (min(finite) if finite else None)
            for cell in cells:
                assert all(math.isfinite(v) for v in cell["center_mm"])
                assert cell["usable"] == (cell["clearance_mm"] is None or (cell["clearance_mm"] > 1e-7 and cell["clearance_mm"] + 1e-6 >= minimum))
                for axis in range(3):
                    assert region["bounds"]["min"][axis] - 1e-6 <= cell["center_mm"][axis] <= region["bounds"]["max"][axis] + 1e-6
                if name == "hole":
                    x, y, _ = cell["center_mm"]
                    assert not (-3200 < x < -2800 and -150 < y < 150), "Support incorrectly fills the known hole"
                x, y, z = cell["center_mm"]
                under_divider = (name in ("tv-console", "reopened") and abs(z - 275) < 0.1 and abs(x) < 15)
                under_divider |= (name == "open-shelf" and abs(z - 30) < 0.1 and abs(x - 3000) < 15)
                if under_divider:
                    assert cell["clearance_mm"] == 0 and not cell["usable"], "Coplanar divider footprint incorrectly reported free"
                    divider_cells += 1
            cells_total += len(cells)
        assert cells_total == data["sampled_cells"]
        counts[name] = {"regions": len(data["regions"]), "cells": cells_total}
        if name in ("tv-console", "open-shelf", "reopened"):
            assert divider_cells > 0, "Expected sampled cells below the fixture divider"
            counts[name]["blocked_divider_cells"] = divider_cells
        if name == "tv-console":
            assert any('"' in s["name"] and "\u0416" in s["name"] for s in data["sources"]), "Quoted Unicode source name failed to roundtrip"
        if name in ("tv-console", "reopened"):
            dims = [b - a for a, b in zip(data["bounds"]["min"], data["bounds"]["max"])]
            assert all(math.isclose(a, b, abs_tol=0.1) for a, b in zip(dims, [1800, 450, 600]))
        if name == "transformed":
            assert math.isclose(data["bounds"]["min"][2], 0, abs_tol=0.1)
            assert math.isclose(data["bounds"]["max"][2], 720, abs_tol=0.1)
            assert any(math.isclose(r["bounds"]["min"][2], 720, abs_tol=0.1) for r in data["regions"])
    result = {"status": "passed", "files": counts, "checks": "Strict JSON; metadata; counts/areas; clearance/usability; bounds; known empty hole; blocked coplanar dividers; quoted Unicode names; physical dimensions; transformed top surface"}
    (run / "json-validation.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
