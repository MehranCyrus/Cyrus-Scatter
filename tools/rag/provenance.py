"""Compact public provenance; complete build inventories stay in local receipts."""
import hashlib
import json


def compact_identities(metadata):
    identities = metadata["identities"]
    git = identities["git_state"]
    return {
        **{key: identities[key] for key in (
            "root", "corpus_path", "corpus_sha256", "runtime_sha256",
            "audit_manifest_sha256", "audit_run_sha256", "audit_schema", "tool_version",
            "extraction_version", "normalization_version", "settings", "ranking")},
        "git_state": {key: git[key] for key in ("branch", "head", "index_sha256")},
        "build_receipt": {"relative_to": "explicit_selected_index_directory",
                          "path": "logical.json", "sha256": metadata["generation_id"],
                          "identities_sha256": hashlib.sha256((json.dumps(identities, ensure_ascii=False,
                              sort_keys=True, separators=(",", ":")) + "\n").encode()).hexdigest()},
    }
