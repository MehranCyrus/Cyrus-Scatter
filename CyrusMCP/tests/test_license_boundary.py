"""Execute the real adapter method with a sentinel before its first host access."""
import ast
from pathlib import Path
from types import SimpleNamespace
import pytest
from cyrus_mcp.contracts import Fault,require

def method(runtime):
    source=Path(__file__).parents[1]/'cyrus_mcp/max_host.py'
    tree=ast.parse(source.read_text())
    cls=next(n for n in tree.body if isinstance(n,ast.ClassDef) and n.name=='MaxHost')
    fn=next(n for n in cls.body if isinstance(n,ast.FunctionDef) and n.name=='generate')
    scope={'rt':runtime,'require':require}
    exec(compile(ast.Module(body=[fn],type_ignores=[]),str(source),'exec'),scope)
    return scope['generate']

@pytest.mark.parametrize('runtime',[SimpleNamespace(),SimpleNamespace(cyrusLicenseAllows=lambda:False)])
def test_mcp_denies_before_fingerprint_undo_or_scene_access(runtime):
    host=SimpleNamespace(assert_main=lambda:None)
    with pytest.raises(Fault,match='active team license'):
        method(runtime)(host,{},None)

def test_licensed_mcp_continues_to_normal_busy_check():
    host=SimpleNamespace(assert_main=lambda:None,busy=lambda:True)
    with pytest.raises(Fault,match='Host is busy'):
        method(SimpleNamespace(cyrusLicenseAllows=lambda:True))(host,{},None)
