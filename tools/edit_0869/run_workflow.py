"""Focused 0.86.9 Edit cases; launch/bind/close are explicit separate operations."""
from pathlib import Path
import argparse
import json
from compatibility_host import run_case

HERE = Path(__file__).resolve().parent
CASES = {
    "feedback": ["E1_model_and_final_matrix", "E1_layer_palette", "E1_manual_display_only", "E1_sdk_move", "E1_move_undo_redo", "E1_cancel", "E1_visual_capture"],
    "stack": ["E1_stack_final", "E1_stack_world_move", "E1_stack_history"],
    "bands": ["E1_band_palette", "E1_band_recolor"],
    "removal": ["E2_remove_manual", "E2_dormant_no_transfer", "E2_radius_history", "E2_remove_undo", "E2_remove_redo", "E2_absent_saved", "E2_last_source", "E2_empty_undo", "E2_live_remove"],
    "saved": ["E3_dormant_reopen", "E3_same_name_isolation", "E3_source_readd", "E3_recovered_roundtrip", "E3_copy_clone_ids"],
    "guards": ["E4_seed_guard", "E4_receiver_guard", "E4_successor_rollback", "E4_retry", "E4_palette_rollback", "E4_author_after_failure"],
    "produce": ["E3_old_fixture_created", "E3_old_incompatible_created"],
    "migrate": ["E3_old_exact_migration", "E3_old_upgraded_roundtrip", "E3_old_incompatible_preserved", "E3_old_recovery"],
    "old_reader": ["E3_old_reader_refusal"],
    "tree": ["E1_tree_placement_pivot", "E1_tree_full_mesh", "E1_tree_move", "E1_tree_visual"],
    "point_identity": ["E2_point_compaction", "E2_point_undo", "E2_point_new_role"],
    "disabled_radius": ["E3_disabled_radius_reopen", "E3_disabled_radius_recover", "E3_disabled_radius_undo"],
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--folder", type=Path, required=True)
    parser.add_argument("--case", choices=CASES, required=True)
    parser.add_argument("--legacy", type=Path)
    parser.add_argument("--tree", type=Path)
    args = parser.parse_args()
    legacy = args.case in ("produce", "migrate", "old_reader")
    setup = ('global EWLegacyPath=@"' + args.legacy.resolve().as_posix() + '"\n') if args.legacy else ""
    if args.tree:
        setup += 'global EWTreeInput=@"' + args.tree.resolve().as_posix() + '"\n'
    fixture = "legacy_fixture.ms" if legacy else "tree_alignment.ms" if args.case == "tree" else "edit_workflow.ms"
    result = run_case(args.folder, HERE / fixture,
                      args.case, CASES[args.case], timeout=240, setup=setup,
                      entrypoint="EWLegacyRun" if legacy else "EWTreeRun" if args.case == "tree" else "EWRun")
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
