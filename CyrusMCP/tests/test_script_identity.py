from pathlib import Path
import hashlib
import re


def test_generated_payload_fingerprint_matches_exact_script_bytes():
    root=Path(__file__).resolve().parents[2]
    content=(root/"AminScatter/scripts/AminScatterObject.ms").read_bytes()
    first,payload=content.split(b"\n",1)
    matched=re.fullmatch(rb'global CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',first)
    assert matched and matched[1].decode()==hashlib.sha256(payload).hexdigest()
