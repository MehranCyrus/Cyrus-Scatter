"""Definitions only; run explicitly on the UI thread of the disposable host.

The .ms fixture creates CS_Offline_Controller. No Max launch, installation,
renderer or artist scene operations occur in this module.
"""
from pathlib import Path
import json


def run(expected_script_payload_sha256, output_directory):
    from pymxs import runtime as rt
    from cyrus_mcp.max_host import MaxHost
    from cyrus_mcp.service import Service, Journal
    from cyrus_mcp.diagnostics import collect_report, save_report
    from cyrus_mcp.contracts import Fault
    node=rt.getNodeByName("CS_Offline_Controller")
    assert node is not None and rt.objects.count<10, "Requires the disposable handoff fixture"
    assert str(rt.CyrusLoadedScriptFingerprint)==expected_script_payload_sha256
    directory=Path(output_directory).resolve()
    assert "build" in directory.parts and "offline-implementation-20261005" in directory.parts
    directory.mkdir(parents=True,exist_ok=True)
    host=MaxHost();service=Service(host,Journal(directory/"operations.json"))
    service.observe(node)
    controller=next(iter(service.observed))
    root=node.baseObject
    before=(int(root.procEpoch),[int(leaf.procPreparedBuilds) for leaf in root.layerObjects])
    published=service.publication(service.epoch,controller)["manifest"]
    rows=[];offset=0
    while offset<published["count"]:
        result=service.publication_page(service.epoch,controller,published["publication_id"],offset,25)["page"]
        rows.extend(result["rows"]);offset=result["next_offset"]
    assert len(rows)==published["count"]
    assert before==(int(root.procEpoch),[int(leaf.procPreparedBuilds) for leaf in root.layerObjects])
    try:
        service.diagnostic_events(service.epoch,"offline_handoff_fixture")
        raise AssertionError("An unshared trace was exposed")
    except Fault as error:assert error.code=="APPROVAL_REQUIRED"
    service.diagnostic_session="offline_handoff_fixture"  # Local fixture authority only.
    service.diagnostic_events(service.epoch,service.diagnostic_session)
    report=collect_report(host.diagnostic_page,service.diagnostic_session,host.version())
    save_report(directory/"diagnostic-report.json",report)
    (directory/"adapter-result.json").write_text(json.dumps(dict(passed=True,manifest=published,rows=rows,
        scope="Direct main-thread adapter checks; not full panel/stdio or Corona qualification"),indent=2),encoding="utf-8")
    return True
