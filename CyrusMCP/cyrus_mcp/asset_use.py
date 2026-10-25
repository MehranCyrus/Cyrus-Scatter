"""Closed prepared-source grant/proposal contracts; no paths or native references."""
from copy import deepcopy
from pathlib import Path
from .contracts import canonical,decode,digest,fields,identifier,number,require
from .library import text

MAX_NODES=3
MAX_GRAPH_BYTES=256*1024
MAX_RECIPE_BYTES=128*1024
MAX_FILE_BYTES=64*1024*1024
MAX_MESH_BYTES=128*1024*1024
MAX_PIXELS=64000000

def bounded_json(path,maximum):
    with path.open("rb") as stream:value=stream.read(maximum+1)
    return decode(value,maximum)

def preflight(directory):
    """Budget local metadata before the native worker verifies full contracts/hashes."""
    root=Path(directory).resolve(strict=True)
    require(root.is_dir(),"Choose an existing prepared source package")
    manifest=bounded_json(root/"cyrus.package.json",8192)
    require(type(manifest) is dict and manifest.get("hostYear")==2027,"Prepared source use requires a Max 2027 package","UNSUPPORTED_CAPABILITY")
    graph=bounded_json(root/"assets.json",MAX_GRAPH_BYTES)
    recipe=bounded_json(root/"entry.csrecipe.json",MAX_RECIPE_BYTES)
    require(type(graph) is dict and type(recipe) is dict,"Invalid prepared source metadata")
    for key,maximum in (("nodes",3),("files",128),("maps",128),("materials",64),("meshes",3)):
        require(type(graph.get(key)) is list and len(graph[key])<=maximum,"Prepared source graph exceeds "+key+" admission","BUDGET_EXCEEDED")
    require(1<=len(graph["nodes"])<=3 and not graph.get("splines"),"Source packages need 1–3 meshes and no splines","UNSUPPORTED_CAPABILITY")
    total=mesh_bytes=pixels=0
    for file in graph["files"]:
        require(type(file) is dict,"Invalid source file metadata")
        number(file.get("bytes"),1,MAX_FILE_BYTES,True);total+=file["bytes"]
        require(file.get("kind") in ("mesh","bitmap"),"Unsupported prepared source file")
        if file["kind"]=="mesh":mesh_bytes+=file["bytes"]
    for row in graph["maps"]:
        require(type(row) is dict,"Invalid source map metadata")
        if row.get("kind") in ("bitmap","corona-bitmap-v1"):
            size=row.get("size")
            require(type(size) is list and len(size)==2,"Invalid image dimensions")
            for axis in size:number(axis,1,32768,True)
            pixels+=size[0]*size[1]
    require(total<=MAX_FILE_BYTES and mesh_bytes<=32*1024**2 and pixels<=MAX_PIXELS,
            "Prepared source file/image admission exceeded","BUDGET_EXCEEDED")
    return root,digest(manifest),dict(file_bytes=total,mesh_encoded_bytes=mesh_bytes,image_pixels=pixels,graph_version=graph.get("version"),
            source_nodes=len(graph["nodes"]),materials=len(graph["materials"]),maps=len(graph["maps"]))

def source_info(value):
    fields(value,("schema","vertices","triangles","minimum_m","maximum_m","radius_xy_m","radius_xyz_m",
                  "mesh_storage_bytes","mapping_channels","stored_normals"))
    require(value["schema"]=="cyrus.prepared-source/1.0","Prepared source API differs","UNSUPPORTED_CAPABILITY")
    number(value["vertices"],1,1000000,True);number(value["triangles"],1,2000000,True)
    number(value["mesh_storage_bytes"],1,MAX_MESH_BYTES,True);number(value["mapping_channels"],0,100,True)
    require(type(value["stored_normals"]) is bool,"Invalid stored-normal metadata")
    from .source_metadata import bounds
    local=bounds(value["minimum_m"],value["maximum_m"])
    number(value["radius_xy_m"],0,2e6);number(value["radius_xyz_m"],value["radius_xy_m"],2e6)
    return {**deepcopy(value),"local_aabb_m":local,"height_m":local["size"][2]}

def ready_snapshot(value,grant_id):
    fields(value,("package_revision","entries","resources","dependencies"))
    identifier(grant_id)
    require(type(value["package_revision"]) is str and len(value["package_revision"])==64
            and all(c in "0123456789abcdef" for c in value["package_revision"]),"Invalid prepared revision")
    require(type(value["entries"]) is list and 1<=len(value["entries"])<=MAX_NODES,"Prepared source node budget exceeded","BUDGET_EXCEEDED")
    seen=set();result=deepcopy(value)
    for row in result["entries"]:
        fields(row,("node_id","name","mesh_sha256","geometry"),("catalog_asset_ref","catalog_entry_id"))
        for key in ("catalog_asset_ref","catalog_entry_id"):
            if key in row:identifier(row[key])
        identifier(row["node_id"]);text(row["name"],160)
        require(row["node_id"] not in seen,"Duplicate prepared node identity");seen.add(row["node_id"])
        require(type(row["mesh_sha256"]) is str and len(row["mesh_sha256"])==64
                and all(c in "0123456789abcdef" for c in row["mesh_sha256"]),"Invalid prepared mesh identity")
        row["geometry"]=source_info(row["geometry"])
        row["asset_ref"]="prepared_"+digest([grant_id,result["package_revision"],row["node_id"]])
    require(sum(r["geometry"]["triangles"] for r in result["entries"])<=2000000
            and sum(r["geometry"]["vertices"] for r in result["entries"])<=1000000
            and sum(r["geometry"]["mesh_storage_bytes"] for r in result["entries"])<=MAX_MESH_BYTES,
            "Aggregate prepared mesh admission exceeded","BUDGET_EXCEEDED")
    result.update(grant_id=grant_id,status="ready",uses=0)
    require(len(canonical(result).encode())<=16384,"Prepared source metadata exceeds its byte budget","BUDGET_EXCEEDED")
    return result

def summary(grant):
    if grant is None:return dict(shared=False,local_action="Share a prepared source package locally in Task details")
    return {"shared":True,**deepcopy(grant),"authority":"Separate local grant for exact approved creation of hidden source copies only; existing objects remain read-only.",
            "freshness":"Immutable prepared revision; refresh locally for content changes. No source files, preview pixels or geometry arrays shared.",
            "limits":"Up to three source meshes; one approved import per grant; imported images use the persistent native asset cache.",
            "readiness_limits":"Finite native adapter preflight; not rendered material equivalence or arbitrary plug-in/proxy support."}

def proposal(use,grant,task,scope,revision):
    fields(use,("use_schema","scope_id","task_id","task_revision","grant_id","asset_refs","destination"))
    require(use["use_schema"]=="cyrus.asset-use/1.0","Unsupported asset-use schema","UNSUPPORTED_CAPABILITY")
    for key in ("scope_id","task_id","grant_id"):identifier(use[key])
    number(use["task_revision"],0,2**53,True)
    require(scope and scope["kind"]=="scene_inspection" and task,"Prepared source use requires a selected scene task","UNSUPPORTED_CAPABILITY")
    require(use["scope_id"]==scope["scope_id"] and use["task_id"]==task["task_id"] and use["task_revision"]==task["task_revision"],
            "Task scope or roles changed","STALE_CONTEXT")
    require(grant and grant["status"]=="ready" and grant["grant_id"]==use["grant_id"],"Prepared source grant is unavailable or changed","STALE_CONTEXT")
    require(grant["uses"]==0,"This prepared source grant was already used; share a new revision locally","BUDGET_EXCEEDED")
    refs=use["asset_refs"]
    require(type(refs) is list and 1<=len(refs)<=MAX_NODES and len(set(refs))==len(refs),"Choose 1–3 distinct prepared sources")
    for ref in refs:identifier(ref)
    entries={row["asset_ref"]:row for row in grant["entries"]}
    require(all(ref in entries for ref in refs),"Prepared source is outside this grant","UNKNOWN_REFERENCE")
    existing=sum("source" in roles for roles in task["roles"].values())
    require(existing+len(refs)<=3 and len(scope["snapshot"]["objects"])+len(refs)<=32,"Task source/object budget exceeded","BUDGET_EXCEEDED")
    require(use["destination"]=="task_sources","Only hidden, non-rendering source copies in this task are supported")
    return dict(use=deepcopy(use),package_revision=grant["package_revision"],sources=[deepcopy(entries[ref]) for ref in refs],
                scene_revision=revision,name="Import prepared source assets",effect="create_hidden_task_sources",
                effects_summary="Create only the selected hidden, non-rendering source copies; keep existing scene objects, materials, selection and placements unchanged. Bind new nodes as source roles in this task.",
                undo="One native Undo removes the new source nodes; persistent hash-addressed bitmap files are retained for scene references.",
                resources=deepcopy(grant["resources"]))
