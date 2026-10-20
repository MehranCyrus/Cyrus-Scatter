"""Check the staged Git source backup against the qualified local inputs."""
from pathlib import Path
import hashlib
import io
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/clearance-performance-08681-20261020/final"
receipt = json.loads((WORK / "max2027/receipt.json").read_text())
names = list(receipt["sources"])
query = "".join(":" + name.replace("\\", "/") + "\n" for name in names)
data = io.BytesIO(subprocess.check_output(["git", "cat-file", "--batch"], input=query.encode(), cwd=ROOT))
normalized = []
for name in names:
    header = data.readline().decode().strip()
    assert not header.endswith("missing"), name
    oid, kind, size = header.split()
    assert kind == "blob", name
    blob = data.read(int(size))
    assert data.read(1) == b"\n"
    local = (ROOT / name).read_bytes()
    assert hashlib.sha256(local).hexdigest() == receipt["sources"][name], name
    digest = hashlib.sha256(blob).hexdigest()
    if digest != receipt["sources"][name]:
        assert blob.replace(b"\r\n", b"\n") == local.replace(b"\r\n", b"\n"), name
        normalized.append({"path": name, "indexed_sha256": digest, "local_sha256": receipt["sources"][name]})
staged = subprocess.check_output(["git", "diff", "--cached", "--name-only"], cwd=ROOT, text=True).splitlines()
assert all(not p.startswith(("website/", "CyrusArrange/", "CyrusLicensing/")) for p in staged), staged
result = {"qualified_sources": len(names), "untracked_qualified_sources": 0,
          "newline_only_differences": normalized, "staged_files": staged}
(WORK / "git-index-check.json").write_text(json.dumps(result, indent=2) + "\n")
print(f"{len(names)} qualified inputs present in Git; {len(normalized)} pre-existing newline-only differences; {len(staged)} scoped staged files.")
