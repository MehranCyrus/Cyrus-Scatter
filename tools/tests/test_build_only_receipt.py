"""Build-only artifacts must not masquerade as tested native producers."""
from pathlib import Path
import json
import sys
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_inputs
import build_max


@pytest.mark.parametrize("tests_run,build_testing,stages,accepted", [
    (None, True, ["configure", "build"], False),
    (False, True, ["configure", "build"], False),
    (False, False, ["configure", "build"], True),
    (False, False, ["configure"], False),
    (True, True, ["configure", "build", "tests"], True),
])
def test_native_admission_requires_explicit_build_only(tmp_path, monkeypatch,
                                                      tests_run, build_testing, stages, accepted):
    manifest = {"files": {}}
    receipt = {"schema": "cyrus.native-build/2", "status": "complete", "project": "scatter",
               "max_year": 2026, "clean_compilation": True, "tests_run": tests_run,
               "source_selection": {"build_testing": build_testing}, "sources": {},
               "compiler_dependencies": {"selected.h": "hash"}, "input_manifest": manifest,
               "input_manifest_sha256": build_inputs.identity(manifest),
               "stages": [{"stage": s, "exit_code": 0} for s in stages]}
    path = tmp_path / "receipt.json"
    path.write_text(json.dumps(receipt))
    monkeypatch.setattr(build_inputs, "verify_frozen", lambda *args: None)
    monkeypatch.setattr(build_inputs, "source_manifest", lambda *args: {"files": {}})
    if accepted:
        result = build_max.verify_native_receipt(path, "AminScatter", 2026, {})
        assert result["tests_run"] is tests_run
    else:
        with pytest.raises(ValueError, match="complete matching"):
            build_max.verify_native_receipt(path, "AminScatter", 2026, {})
