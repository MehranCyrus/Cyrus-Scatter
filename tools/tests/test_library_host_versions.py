"""Host matching is part of packaging, independent of machine runtime qualification."""
import hashlib,importlib.util,json
from pathlib import Path
import pytest
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('library_host_build',ROOT/'tools/build_max.py');builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
@pytest.mark.parametrize('year',[2024,2026,2027])
def test_library_inventory_cannot_cross_host_boundary(tmp_path,year):
 data=b'owned target-format fixture';(tmp_path/'example.max').write_bytes(data)
 (tmp_path/'inventory.json').write_text(json.dumps({'version':'0.86.1','max_year':year,'files':{'example.max':hashlib.sha256(data).hexdigest()}}))
 assert builder.library_payload(tmp_path,'0.86.1',year)['Library/example.max']==data
 for other in (2024,2026,2027,2025):
  if other!=year:
   with pytest.raises(ValueError,match='version/host'):builder.library_payload(tmp_path,'0.86.1',other)
