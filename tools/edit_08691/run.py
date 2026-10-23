"""Focused current-payload Max 2027 checks. Never launches older hosts."""
from pathlib import Path
import argparse
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools/edit_0869"))
from compatibility_host import launch_owned, run_case, bind_suite, close_owned

CASES = {
    "density": ["map_empty", "map_preview", "preview_reuse", "preview_revision", "map_clear", "map_undo", "manual_preserved"],
    "drop_prepare": ["drop_ready"],
    "drop_verify": ["drop_assigned", "drop_preview_manual"],
    "layout_prepare": ["layout_ready"],
    "layout_verify": ["main_width", "layers_width", "layout_manual"],
    "geometry_probe": ["geometry_recorded"],
    "width_prototype": ["native_resize_event"],
    "layout_reselect": ["layout_reselect"],
    "setup": ["setup_ready"],
    "setup_medium": ["medium_ready"],
    "bench": [f"{state}_{count}_{layers}" for count, layers in [(100, 1), (10000, 1), (10000, 3)] for state in ["pending", "settled"]],
    "physical_begin": ["physical_armed"],
    "physical_end": ["physical_moved"],
    "physical_verify": ["pointer_authored", "pointer_feedback_live", "pointer_gizmo_live", "pointer_release_matches", "pointer_gizmo_release", "pointer_one_publication"],
    "lifecycle": ["lifecycle_move", "lifecycle_undo", "lifecycle_redo", "lifecycle_cancel", "lifecycle_scene"],
    "old_scene": ["old_edits", "old_radii"],
    "analyzer": ["analyzer_bridge"],
    "feedback_manual": ["feedback_manual"],
}
DRAG_CASES = {"setup", "setup_medium", "bench", "physical_begin", "physical_end", "physical_verify", "lifecycle", "feedback_manual"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["launch", "bind", "close", *CASES])
    parser.add_argument("--folder", type=Path, required=True)
    parser.add_argument("--payload", type=Path)
    parser.add_argument("--old-scene", type=Path, default=ROOT / "build/edit-0869-20261023/hosts/max2027-01/recovered-source.max")
    args = parser.parse_args()
    bindings = {"ui91": HERE / "ui_checks.ms", "ui91-driver": HERE / "run.py", "drag91": HERE / "drag_checks.ms",
                "preservation91": HERE / "preservation.ms"}
    if args.old_scene.is_file():
        bindings["prior-scene"] = args.old_scene
    if args.action == "launch":
        if args.payload is None:
            parser.error("launch needs --payload")
        result = launch_owned(args.folder, 2027, args.payload, bindings=bindings,
                              visible=True, require_edit_version=True)
    elif args.action == "bind":
        result = bind_suite(args.folder, bindings)
    elif args.action == "close":
        close_owned(args.folder)
        result = {"status": "closed"}
    else:
        drag = args.action in DRAG_CASES
        preservation = args.action in ("old_scene", "analyzer")
        setup = 'global UI91OldScene=@"' + args.old_scene.resolve().as_posix() + '"\n' if args.action == "old_scene" else ""
        result = run_case(args.folder, HERE / ("preservation.ms" if preservation else "drag_checks.ms" if drag else "ui_checks.ms"), args.action,
                          CASES[args.action], entrypoint="PRRun" if preservation else "DRun" if drag else "UIRun", timeout=180, setup=setup)
    summary = ({k: result[k] for k in ("status", "request_id", "scenario_id", "assertions") if k in result}
               if "assertions" in result else
               {k: result[k] for k in ("status", "pid", "run_id", "artifact_id", "version", "max_year") if k in result})
    print(json.dumps(summary, indent=2, default=str))
