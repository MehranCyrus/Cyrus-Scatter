"""Check integrity and measured acceptance invariants of the archived first loop."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "docs/Heavy_Scene_Viewport_2026-10-02/evidence"


def read(name):
    return json.loads((EVIDENCE / name).read_text(encoding="utf-8-sig"))


def main():
    files = read("manifest.json")["files"]
    for item in files:
        path = EVIDENCE / item["path"]
        assert path.is_relative_to(EVIDENCE)
        data = path.read_bytes()
        assert len(data) == item["bytes"] and hashlib.sha256(data).hexdigest() == item["sha256"], path
    summary = read("summary.json")
    assert len(summary["cases"]) == 10
    steps = 0
    for case in summary["cases"]:
        for row in case["validation"]:
            steps += row["frames"]
            if row["arm"] == "retained":
                assert row["upload_increment"] == row["prepare_increment"] == row["node_update_increment"] == 0
                assert row["draw_increment"] >= row["frames"]
    assert steps == 11880, steps
    presentation = read("presentmon-summary.json")
    assert all(arm["presents"] == 1437 for arm in presentation["arms"].values())
    lifecycle = read("lifecycle.json")
    assert len(lifecycle) == 12
    assert len({row["private_bytes"] for row in lifecycle}) == 1
    assert all(row["stats"][0] == 250000 and row["stats"][9] == 3 and row["stats"][8] == 0 for row in lifecycle)
    gesture = read("gesture.json")
    for index in (0, 2, 3, 4, 5, 10):
        assert gesture["before"][index] == gesture["after"][index]
    assert gesture["after"][7] > gesture["before"][7]
    cleanup = read("cleanup.json")
    assert cleanup["status"] == "SUCCESS" and cleanup["after_reset"][9] == 0
    assert cleanup["objects_after_cleanup"] == 0 and cleanup["redraw_callback_unregistered"]
    assert read("shutdown-requested.json")["transport_disposed"]
    assert read("shutdown-observed.json")["process_exited"]
    assert all(row["matches_pre_launch"] for row in read("preservation.json"))
    print(f"Verified {len(files)} archived file hashes, {steps:,} camera steps, 4,311 aligned presents, 12 ownership cycles, mouse navigation, reset, shutdown and input preservation.")


if __name__ == "__main__":
    main()
