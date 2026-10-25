"""Seal a completed owned model-export result into bounded availability metadata."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def seal(base):
    """Publish availability only after a terminal owned export; never claims readiness."""
    sys.path.insert(0,str(ROOT/"CyrusMCP"))
    from cyrus_mcp.asset_use import preflight,bounded_json,MAX_GRAPH_BYTES,MAX_RECIPE_BYTES
    from cyrus_mcp.contracts import Fault,canonical,digest,require
    from cyrus_mcp.installed_sources import INDEX_NAME,load,unlinked
    root=unlinked(base/"Library");target=root/INDEX_NAME
    require(not target.exists(),"A sealed index already exists; preserve its original evidence")
    result=json.loads((base/"host01/content-preparation.json").read_text(encoding="utf-8"))
    require(result["status"]=="complete" and result["remaining"]==0,"Observe the existing native export until terminal")
    catalog_path=root/"model-catalog.json";catalog=json.loads(catalog_path.read_text(encoding="utf-8"))
    models=catalog["entries"];exported={row["entry_id"]:row for row in result["entries"]}
    require(len(exported)==len(result["entries"])==len(models) and {row["id"] for row in models}==set(exported),"Incomplete content export evidence")
    rows=[]
    for model in models:
        original=exported[model["id"]]
        require(original["scene_sha256"]==model["scene_sha256"],"Content source identity changed")
        row=dict(entry_id=model["id"],scene_sha256=model["scene_sha256"],status=original["status"])
        if original["status"]=="prepared":
            folder=root/"PreparedModels"/model["id"]/"package"
            try:
                directory,revision,resources=preflight(folder)
                require(directory==folder.resolve() and resources["source_nodes"]==1,"Installed derivative must contain one selected model")
                manifest=bounded_json(folder/"cyrus.package.json",8192)
                for key,name,limit in (("graph","assets.json",MAX_GRAPH_BYTES),("recipe","entry.csrecipe.json",MAX_RECIPE_BYTES)):
                    path=unlinked(folder/name)
                    with path.open("rb") as stream:data=stream.read(limit+1)
                    require(len(data)<=limit and manifest[key]["file"]==name and len(data)==manifest[key]["bytes"]
                            and hashlib.sha256(data).hexdigest()==manifest[key]["sha256"],"Exported descriptor changed")
                graph=bounded_json(folder/"assets.json",MAX_GRAPH_BYTES)
                row.update(package=folder.relative_to(root).as_posix(),manifest_sha256=sha(folder/"cyrus.package.json"),
                           package_revision=revision,source_node_id=graph["nodes"][0]["id"])
            except Fault as exc:
                row=dict(entry_id=model["id"],scene_sha256=model["scene_sha256"],status="deferred",
                         reason="requires_larger_mcp_source_preparation_budget" if exc.code=="BUDGET_EXCEEDED" else "prepared_descriptor_requires_review")
        elif original["status"]=="rejected":
            row["reason"]="portable_shader_enum_requires_adapter_qualification" if "unsupported enum value" in original.get("error","") else "native_portable_preparation_requires_review"
        else:row["reason"]=original.get("reason",original["status"])
        rows.append(row)
    value=dict(format="cyrus.prepared-model-index",version=1,host_year=2027,catalog_sha256=sha(catalog_path),entries=rows)
    temporary=root/(INDEX_NAME+".pending")
    with temporary.open("x",encoding="utf-8") as stream:
        stream.write(canonical(value)+"\n");stream.flush();os.fsync(stream.fileno())
    os.replace(temporary,target)
    index,linked=load(root,value["catalog_sha256"],[dict(entry_id=row["id"],scene_sha256=row["scene_sha256"]) for row in models])
    report=dict(index_sha256=index,catalog_sha256=value["catalog_sha256"],entries=len(linked),
                counts={key:sum(row["status"]==key for row in rows) for key in ("prepared","deferred","rejected","not_requested")},
                evidence="Native export and bounded descriptor admission only; native selected-source preparation and exact import approval remain required")
    (base/"host01/prepared-index.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report),flush=True)

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base',type=Path,required=True)
    args=parser.parse_args();base=args.base.resolve()
    if not base.is_relative_to(ROOT/'build'):raise ValueError('Owned build directory required')
    seal(base)
