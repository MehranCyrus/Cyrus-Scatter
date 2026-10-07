"""Initialize real Automation in the owned private Max, after script evaluation."""
from pathlib import Path
import builtins,json,sys,traceback
from pymxs import runtime as rt
from PySide6.QtCore import QTimer

ROOT=Path(__file__).resolve().parents[2]
folder=Path(str(rt.MCPFixtureDir)).resolve()
assert folder.parent==ROOT/'build/mcp-qualification'
sys.path.insert(0,str(ROOT/'CyrusMCP'))
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
import Max_Runtime_Panel_Fixture as fixture


def save_reopen():
    """Compare exact generation identities/transforms and scene authority reset."""
    value=fixture.STATE['panel']
    value.start_diagnostics()
    value.diagnostic_permission(True)
    names={cid:str(obj.name) for cid,obj in value.host.controllers.items()}
    def snapshot(node):
        return dict(layers=[dict(id=str(layer.layerID),
            fingerprint=str(rt.cyrusEditFingerprint(layer.placements(layer.validSources()),'mcp')),
            count=len(layer.placements(layer.validSources())),
            source_ids=[str(v) for v in layer.procSourceIDs],
            rows=[dict(id=str(row[2]),source=int(row[1]),tm=str(row[0]))
                  for row in layer.placements(layer.validSources())]) for layer in node.layerObjects])
    before={cid:snapshot(obj) for cid,obj in value.host.controllers.items()}
    path=folder/'QualifiedLayout.max'
    rt.saveMaxFile(str(path),quiet=True)
    rt.loadMaxFile(str(path),quiet=True)
    cold_bindings={cid:[leaf.overlapOwner is None for leaf in rt.getNodeByName(name).layerObjects]
                   for cid,name in names.items()}
    # Embedded records are not stand-alone controllers. Restore the cold
    # transient publication through the saved root before reading its leaves.
    # This is the same exact-output entry point; do not force a second update.
    for name in names.values():rt.getNodeByName(name).procReadSnapshot()
    after={cid:snapshot(rt.getNodeByName(name)) for cid,name in names.items()}
    result=dict(match=before==after,scope_cleared=value.service.scope is None,
        diagnostic_stopped=not rt.cyrusDiagnosticActive(),
        diagnostic_unshared=value.service.diagnostic_session is None and not value.trace_share.isChecked(),
        cold_bindings=cold_bindings,before=before,after=after)
    (folder/'panel-save-reopen.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    assert result['match'] and result['scope_cleared'],result
    assert result['diagnostic_stopped'] and result['diagnostic_unshared'],result
    return result


def initialize():
    try:
        builtins.CSRuntimePanel={name:getattr(fixture,name) for name in
            ('sample','share','busy','setup_design','approve','save_reopen','close')}
        builtins.CSRuntimePanel['save_reopen']=save_reopen
        fixture.setup(folder,str(rt.CyrusLoadedScriptFingerprint))
    except Exception:
        (folder/'panel-initialization-error.txt').write_text(traceback.format_exc(),encoding='utf-8')


QTimer.singleShot(100,initialize)
