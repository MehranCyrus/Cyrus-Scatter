"""Bounded catalog-to-portable-derivative links. No .max reads or scene effects."""
from copy import deepcopy
import hashlib
from pathlib import Path
import stat
from .contracts import decode,digest,fields,identifier,require

INDEX_NAME="prepared-sources.json"
MAX_INDEX_BYTES=512*1024

def unlinked(path):
    path=Path(path).absolute()
    for current in (path,*path.parents):
        info=current.lstat()
        require(not stat.S_ISLNK(info.st_mode) and not (getattr(info,"st_file_attributes",0)&0x400),
                "Prepared content cannot use linked paths","UNSUPPORTED_CAPABILITY")
    return path

def contained(root,relative):
    require(type(relative) is str and 1<=len(relative)<=160 and ":" not in relative and "\\" not in relative,"Invalid prepared content path")
    parts=relative.split("/")
    require(all(part not in ("",".","..") and part.rstrip(" .")==part and all(ord(c)>=32 and c not in '<>"|?*' for c in part) for part in parts),"Invalid prepared content path")
    root=unlinked(root);path=unlinked(root.joinpath(*parts))
    require(path.resolve().is_relative_to(root.resolve()),"Prepared content escapes its root")
    return path

def sha(value):
    require(type(value) is str and len(value)==64 and all(c in "0123456789abcdef" for c in value),"Invalid prepared content hash")
    return value

def load(root,catalog_sha256,models):
    """Local sharing reads index and tiny manifests, never mesh/images or .max files."""
    root=unlinked(root);index=root/INDEX_NAME
    if not index.exists():return None,{}
    unlinked(index)
    with index.open("rb") as stream:raw=stream.read(MAX_INDEX_BYTES+1)
    value=decode(raw,MAX_INDEX_BYTES)
    fields(value,("format","version","host_year","catalog_sha256","entries"))
    require(type(value["version"]) is int and type(value["host_year"]) is int,"Invalid prepared index version")
    require((value["format"],value["version"],value["host_year"])==("cyrus.prepared-model-index",1,2027),"Unsupported prepared model index","UNSUPPORTED_CAPABILITY")
    require(sha(value["catalog_sha256"])==catalog_sha256,"Prepared model index belongs to another catalog","STALE_CONTEXT")
    require(type(value["entries"]) is list and len(value["entries"])<=104,"Prepared model index exceeds its bound","BUDGET_EXCEEDED")
    entries={};known={row["entry_id"]:row for row in models}
    for row in value["entries"]:
        fields(row,("entry_id","scene_sha256","status"),("package","manifest_sha256","package_revision","source_node_id","reason"))
        identity=row["entry_id"];identifier(identity)
        require(identity in known and identity not in entries,"Unknown/duplicate prepared model ID")
        require(sha(row["scene_sha256"])==known[identity]["scene_sha256"],"Prepared model source scene changed","STALE_CONTEXT")
        require(row["status"] in ("prepared","deferred","rejected","not_requested"),"Invalid prepared model status")
        entry=deepcopy(row)
        if row["status"]=="prepared":
            require(all(key in row for key in ("package","manifest_sha256","package_revision","source_node_id")),"Incomplete prepared model link")
            identifier(row["source_node_id"]);sha(row["manifest_sha256"]);sha(row["package_revision"])
            folder=contained(root,row["package"]);require(folder.is_dir(),"Prepared package is unavailable","STALE_CONTEXT")
            manifest=unlinked(folder/"cyrus.package.json")
            with manifest.open("rb") as stream:data=stream.read(8193)
            require(len(data)<=8192 and hashlib.sha256(data).hexdigest()==row["manifest_sha256"],"Prepared package manifest changed","STALE_CONTEXT")
            require(digest(decode(data,8192))==row["package_revision"],"Prepared package revision changed","STALE_CONTEXT")
            entry["_directory"]=str(folder)
        else:
            reason=row.get("reason",row["status"])
            require(type(reason) is str and len(reason)<=160 and all(ord(c)>=32 for c in reason),"Invalid preparation omission reason")
            entry["reason"]=reason
        entries[identity]=entry
    return hashlib.sha256(raw).hexdigest(),entries

def descriptor(entry,index_sha256):
    if entry is None:return dict(status="not_prepared",ready_for_import=False)
    result={key:entry[key] for key in ("status","reason","package_revision","source_node_id") if key in entry}
    return {**result,"index_sha256":index_sha256,"ready_for_import":False,
            "evidence":"Bound index and small manifest only; prepare through the native worker before exact import approval"}

def permission_summary(value):
    if value is None:return dict(enabled=False,local_action="Enable installed-source proposals locally for the shared catalog")
    return {"enabled":True,**deepcopy(value),"authority":"Bounded preparation of linked installed sources only. Scene import still requires exact local approval."}
