"""Frozen settings-preset discovery. Native parser owns validity; no application API."""
from copy import deepcopy
import hashlib
from .contracts import canonical,decode,digest,fields,identifier,number,require
from .installed_sources import sha
from .library import text

MAX_ENTRIES=512
PAGE_SIZE=24
CATEGORIES=("population","transforms","spacing","density_curve","scale_curve")
COUNTS=dict(population=15,transforms=34,spacing=4,density_curve=0,scale_curve=0)
ENTRY_FIELDS=("entry_key","name","category","preset_sha256","document_sha256","source_bytes","field_count","sample_count","graph_count","domain")


def progress(value):
    fields(value,("state","scanned","entry_count","invalid","limited","has_error","pages","entries"))
    require(value["state"] in ("scanning","complete","cancelled"),"Invalid native preset state")
    for key in ("scanned","entry_count","invalid"):number(value[key],0,MAX_ENTRIES,True)
    require(value["entry_count"]+value["invalid"]<=value["scanned"],"Invalid preset catalog counts")
    number(value["pages"],1,4,True)
    require(type(value["limited"]) is bool and type(value["has_error"]) is bool,"Invalid preset catalog flags")
    require(type(value["entries"]) is list and len(value["entries"])<=128,"Preset native page exceeds its bound")
    return {key:value[key] for key in ("scanned","entry_count","invalid","limited")}


def snapshot(value):
    counts=progress({**value,"entries":[]})
    require(value["state"]=="complete" and not value["has_error"],"Preset scan did not complete cleanly","CATALOG_UNAVAILABLE")
    require(type(value["entries"]) is list and len(value["entries"])==counts["entry_count"]<=MAX_ENTRIES,"Incomplete preset snapshot")
    entries=deepcopy(value["entries"]);seen=set()
    for row in entries:
        fields(row,ENTRY_FIELDS)
        for key in ("entry_key","preset_sha256","document_sha256"):sha(row[key])
        require(row["entry_key"] not in seen,"Duplicate preset entry");seen.add(row["entry_key"])
        # Native UTF-8 names allow 80 characters. Sanitize control characters for
        # display while keeping hashes and the frozen document identity intact.
        require(type(row["name"]) is str and 1<=len(row["name"])<=80,"Invalid preset name")
        clean="".join(" " if ord(c)<32 or 127<=ord(c)<=159 else c for c in row["name"])
        row["name_sanitized"]=clean!=row["name"];row["name"]=clean
        require(row["category"] in CATEGORIES,"Unsupported native preset category")
        number(row["source_bytes"],1,65536,True)
        number(row["field_count"],0,34,True)
        require(row["field_count"]==COUNTS[row["category"]],"Preset field schema differs","UNSUPPORTED_CAPABILITY")
        number(row["sample_count"],0,257,True);number(row["graph_count"],0,257,True)
        if row["field_count"]:
            require(row["sample_count"]==row["graph_count"]==0 and row["domain"]=="settings","Invalid scalar preset metadata")
        else:
            require(row["sample_count"]>=2 and (row["graph_count"]==0 or row["graph_count"]>=2) and row["domain"] in ("unit","multiplier"),"Invalid curve preset metadata")
            require(row["category"]!="density_curve" or row["domain"]=="unit","Invalid density curve domain")
    entries.sort(key=lambda row:row["entry_key"])
    fingerprint=digest(dict(entries=entries,**counts))
    for row in entries:row["preset_ref"]="preset_"+digest([fingerprint,row["entry_key"]])
    result=dict(status="ready",snapshot_sha256=fingerprint,entries=entries,**counts)
    require(len(canonical(result).encode())<=1024*1024,"Preset snapshot exceeds its metadata budget","BUDGET_EXCEEDED")
    return result


def summary(grant):
    if grant is None:return dict(shared=False,local_action="Share My settings presets or one settings preset folder in Task details")
    result={key:grant[key] for key in ("library_id","kind","status","scanned","entry_count","invalid","limited")}
    result.update(shared=True,use_supported=False,freshness="Frozen native typed settings only; refresh locally after file changes. No application approval or destination compatibility.")
    if grant["status"]=="ready":result["snapshot_sha256"]=grant["snapshot_sha256"]
    if grant["status"]=="failed":result["error"]=deepcopy(grant["error"])
    return result


def ready(grant):
    require(grant["status"]=="ready","Preset metadata is still scanning" if grant["status"]=="scanning" else "Preset metadata unavailable; refresh locally",
            "CATALOG_SCANNING" if grant["status"]=="scanning" else "CATALOG_UNAVAILABLE")


def search(grant,query="",category="",offset=0,limit=PAGE_SIZE):
    ready(grant);text(query,80,empty=True);text(category,32,empty=True)
    require(not category or category in CATEGORIES,"Unknown settings preset category")
    number(offset,0,MAX_ENTRIES,True);number(limit,1,PAGE_SIZE,True)
    matches=[row for row in grant["entries"] if (not category or row["category"]==category)
             and (not query or query.casefold() in (row["name"]+" "+row["category"]).casefold())]
    rows=[{key:deepcopy(value) for key,value in row.items() if key!="entry_key"} for row in matches[offset:offset+limit]]
    result={**summary(grant),"entries":rows,"query":query,"category":category,"offset":offset,"total_matches":len(matches),
            "next_offset":offset+len(rows) if offset+len(rows)<len(matches) else None,"categories":list(CATEGORIES)}
    require(len(canonical(result).encode())<=32768,"Preset search exceeds its response budget","BUDGET_EXCEEDED")
    return result


def entry(grant,preset_ref):
    ready(grant);identifier(preset_ref)
    row=next((row for row in grant["entries"] if row["preset_ref"]==preset_ref),None)
    require(row is not None,"Preset is outside this shared snapshot","UNKNOWN_REFERENCE")
    return row


def inspect(grant,row,native):
    fields(native,("document_json","fields","preset_sha256","document_sha256"))
    require(native["preset_sha256"]==row["preset_sha256"] and native["document_sha256"]==row["document_sha256"],"Native preset snapshot changed","STALE_CONTEXT")
    encoded=native["document_json"]
    require(type(encoded) is str and hashlib.sha256(encoded.encode()).hexdigest()==row["document_sha256"],"Native preset document hash differs","STALE_CONTEXT")
    document=decode(encoded.encode(),65536)
    fields(document,("format","version","category","name","values"))
    require(document["format"]=="cyrus.settings-preset" and type(document["version"]) is int and document["version"]==3
            and document["category"]==row["category"],"Native preset document contract differs","UNSUPPORTED_CAPABILITY")
    schema=native["fields"]
    require(type(schema) is list and len(schema)==row["field_count"],"Native preset field count differs")
    names=set()
    for field in schema:
        fields(field,("name","kind","minimum","maximum","distance_metres"))
        identifier(field["name"]);require(field["name"] not in names,"Duplicate native preset field");names.add(field["name"])
        require(field["kind"] in ("boolean","integer","number") and type(field["distance_metres"]) is bool,"Native preset field type differs")
        number(field["minimum"],-1e30,1e30);number(field["maximum"],field["minimum"],1e30)
    if schema:
        fields(document["values"],names)
        for field in schema:
            value=document["values"][field["name"]]
            if field["kind"]=="boolean":require(type(value) is bool,"Invalid native preset Boolean")
            else:number(value,field["minimum"],field["maximum"],field["kind"]=="integer")
    else:
        fields(document["values"],("domain","samples","graph"))
        require(type(document["values"]["samples"]) is list and type(document["values"]["graph"]) is list,"Invalid native curve arrays")
        require(document["values"]["domain"]==row["domain"] and len(document["values"]["samples"])==row["sample_count"]
                and len(document["values"]["graph"])==row["graph_count"],"Native curve dimensions differ")
        for sample in document["values"]["samples"]:number(sample,0,100 if row["domain"]=="multiplier" else 1)
        for point in document["values"]["graph"]:
            require(type(point) is list and len(point)==8,"Invalid native curve graph point")
            for value in point:number(value,-1e8,1e8)
    result={**summary(grant),"entry":{key:deepcopy(value) for key,value in row.items() if key!="entry_key"},
            "document":document,"fields":deepcopy(schema),"evidence":{"native_validation":"Closed native preset parser and normalized v3 document",
            "units":"distance_metres fields are metres; remaining native properties retain their declared native domains",
            "freshness":"Frozen scan-time document; selected inspection does not reread files or evaluate the scene",
            "destination_compatibility":"unchecked","ready_for_application":False},
            "next_action":"Inspect the exact target and review a supported application separately. Discovery grants no setting changes; full recipe loading has different effects."}
    require(len(canonical(result).encode())<=96*1024,"Preset inspection exceeds its response budget","BUDGET_EXCEEDED")
    return result
