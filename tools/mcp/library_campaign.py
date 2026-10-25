"""Real SDK / owned Max catalog metadata grant; never merges content models."""
import asyncio
import json
from pathlib import Path
import sys
import uuid

from mcp import Client
from mcp.client.stdio import StdioServerParameters
from foundation_campaign import ROOT, qualification, verify_owned, run_case
from compatibility_host import bind_suite


async def run(base):
    q=qualification(base)
    here=Path(__file__).resolve().parent
    catalog=ROOT/"dist/CyrusScatter-0.86.7-20261020/Content/Library/model-catalog.json"
    meta=bind_suite(q.folder,{"library-driver":Path(__file__),"library-clean-fixture":here/"scene_passive.ms",
                              "library-source-catalog":catalog})
    receipt=q.folder/("library-"+uuid.uuid4().hex+".json")
    evidence={"status":"running","pid":meta["pid"],"artifact_id":meta["artifact_id"],"run_id":meta["run_id"],
              "qualification":"Owned Max 2027 / real SDK; local sharing buttons scripted, not artist consent. No asset import.","cases":[]}
    def save():receipt.write_text(json.dumps(evidence,indent=2)+"\n",encoding="utf-8")
    code="import sys;sys.path.insert(0,"+repr(str(base/"source"))+");from cyrus_mcp.server import main;main()"
    params=StdioServerParameters(command=sys.executable,args=["-c",code,"--connection-dir",str(q.folder/"connection")])
    try:
        q.local("setup");q.local("scene_fixture")
        async with Client(params) as client:
            async def call(name,expected=None,**args):
                verify_owned(q.folder)
                response=await client.call_tool(name,args)
                verify_owned(q.folder)
                value=response.structured_content
                if expected:
                    assert response.is_error and value["error"]["code"]==expected,value
                else:assert not response.is_error,value
                return value
            connection=await call("connection_get_status")
            scope_id=connection["scope_id"]
            ctx=await call("scene_get_context",scope_id=scope_id)
            task_id=ctx["task"]["task_id"]
            cards=ctx["scope"]["snapshot"]["objects"]
            q.local("scene_role",role="receiver",object_ids=[next(c["object_id"] for c in cards if c["object_type"]=="Plane")])
            q.local("scene_role",role="source",object_ids=[next(c["object_id"] for c in cards if c["object_type"]=="Cone")])
            await call("library_search",expected="APPROVAL_REQUIRED",scope_id=scope_id,library_id="not_shared")
            binding=q.local("catalog_fixture",root=str(catalog.parent))
            run_case(q.folder,here/"scene_passive.ms","clean",["clean_before_reads"],timeout=30,entrypoint="MCPScenePassiveRun")
            before=q.local("scene_state")
            shared=q.local("catalog_share")
            assert shared["grant"]["entry_count"]==96 and shared["revoke_enabled"]
            library_id=shared["grant"]["library_id"]
            rows=[];offset=0;pages=[]
            while offset is not None:
                page=await call("library_search",scope_id=scope_id,library_id=library_id,offset=offset)
                assert page["snapshot_sha256"]==shared["grant"]["snapshot_sha256"] and len(page["entries"])<=12
                rows+=page["entries"];pages.append(page);offset=page["next_offset"]
            assert len(rows)==96 and len({r["asset_ref"] for r in rows})==96
            info=await call("library_inspect_entry",scope_id=scope_id,library_id=library_id,asset_ref=rows[0]["asset_ref"])
            assert info["evidence"]["dimensions_m"] is None and not info["evidence"]["ready_for_import"] and not info["use_supported"]
            assert "F:" not in json.dumps(pages+ [info]) and "C:" not in json.dumps(pages+ [info])
            category=rows[0]["category"]
            filtered=await call("library_search",scope_id=scope_id,library_id=library_id,category=category,query=rows[0]["entry_id"])
            assert len(filtered["entries"])==1 and filtered["entries"][0]["asset_ref"]==rows[0]["asset_ref"]
            await call("library_inspect_entry",expected="UNKNOWN_REFERENCE",scope_id=scope_id,library_id=library_id,asset_ref="asset_outside")
            after=q.local("scene_state")
            assert before==after and not after["save_required"],(before,after)
            evidence["cases"].append({"case":"real_catalog_paging_inspection","status":"passed","shared":shared,"binding":binding,
                                      "page_count":len(pages),"asset_count":len(rows),"example":info,"native_before":before,"native_after":after})
            renewed=q.local("catalog_share")
            assert renewed["grant"]["snapshot_sha256"]==shared["grant"]["snapshot_sha256"] and renewed["grant"]["library_id"]!=library_id
            await call("library_search",expected="STALE_CONTEXT",scope_id=scope_id,library_id=library_id)
            revoked=q.local("catalog_revoke")
            assert not revoked["grant"]["shared"] and not revoked["revoke_enabled"]
            await call("library_search",expected="APPROVAL_REQUIRED",scope_id=scope_id,library_id=renewed["grant"]["library_id"])
            final=q.local("catalog_share")
            review=q.local("task_prepare_grant")
            q.local("task_connect_grant",review_id=review["review_id"],digest=review["digest"])
            current=await call("connection_get_status")
            assert current["scope_id"]!=scope_id and current["installed_catalog"]==final["grant"]
            await call("library_search",expected="UNKNOWN_REFERENCE",scope_id=scope_id,library_id=final["grant"]["library_id"])
            retained=await call("library_search",scope_id=current["scope_id"],library_id=final["grant"]["library_id"],limit=1)
            assert retained["entries"][0]["asset_ref"]==rows[0]["asset_ref"]
            task=q.local("scene_ui")
            assert q.local("scene_state")==after
            evidence["cases"].append({"case":"refresh_revoke_and_task_handoff","status":"passed","task_id":task_id,
                                      "renewed":renewed,"revoked":revoked,"retained":current["installed_catalog"],"native_after":q.local("scene_state")})
            missing=q.folder/("missing-models-"+uuid.uuid4().hex)
            missing.mkdir()
            (missing/"model-catalog.json").write_bytes(catalog.read_bytes())
            q.local("catalog_fixture",root=str(missing))
            try:q.local("catalog_share")
            except AssertionError as exc:
                assert "CATALOG_UNAVAILABLE" in str(exc),str(exc)
            else:raise AssertionError("Missing installed model files were admitted")
            failed=await call("connection_get_status")
            assert not failed["installed_catalog"]["shared"]
            await call("library_search",expected="APPROVAL_REQUIRED",scope_id=current["scope_id"],library_id=final["grant"]["library_id"])
            assert q.local("scene_state")==after
            q.local("catalog_fixture",root=str(catalog.parent))
            repaired=q.local("catalog_share")
            assert repaired["grant"]["snapshot_sha256"]==shared["grant"]["snapshot_sha256"]
            evidence["cases"].append({"case":"missing_content_revokes_refresh_grant_then_native_repair","status":"passed",
                                      "failed_connection":failed["installed_catalog"],"repaired":repaired,"native_unchanged":True})
            q.local("scene_disconnect")
            disconnected=await call("connection_get_status")
            assert not disconnected["installed_catalog"]["shared"]
            evidence["cases"].append({"case":"disconnect_revokes_grant","status":"passed"})
        evidence["status"]="passed";save()
    except Exception as exc:
        evidence["status"]="failed";evidence["error"]=repr(exc);save();raise
    print(receipt,flush=True)


if __name__=="__main__":
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base",type=Path,required=True)
    asyncio.run(run(parser.parse_args().base.resolve()))
