"""Rebuild the portable guide from its exact Markdown source snapshots.

Python 3 standard library only. This deliberately small renderer supports the
headings, paragraphs, lists, inline emphasis, links and tables in this reference.
It fails on an unknown local link rather than silently publishing a broken one.
"""
from pathlib import Path
import argparse
import hashlib
import html
import json
import re
import shutil
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT.parent / "docs" / "Artist_Reference_0.73_2026-10-07"
BASELINE = "d55dfa88cbeda7af366e4510ac3119a749368958"
META = [
    ("README.md", "guide", "Guide contents", "Start here", "The essentials, explained."),
    ("01_SETUP_AND_LAYERS.md", "setup", "Setup & layers", "The workflow", "Choose your ground. Give every planting a home."),
    ("02_MODELS_AND_CONTAINERS.md", "models", "Models & containers", "The workflow", "Organize your sources and keep their settings."),
    ("03_SOURCE_ASSIGNMENT.md", "assignment", "Source assignment", "The workflow", "Give different models a deliberate pattern."),
    ("04_POPULATION.md", "population", "Population", "The workflow", "Set the request. Understand what can fit."),
    ("05_COVERAGE_AND_PAINTING.md", "painting", "Coverage & painting", "The workflow", "Shape where your planting belongs."),
    ("06_AREAS_AND_FALLOFF.md", "areas", "Areas & falloff", "The workflow", "Define clear boundaries and softer edges."),
    ("07_TRANSFORMS.md", "transforms", "Transforms", "The workflow", "Balance natural variation and precise control."),
    ("08_SPACING_AND_CLEANUP.md", "spacing", "Spacing & cleanup", "The workflow", "Give plants room at the right scope."),
    ("09_VIEWPORT_AND_RENDER.md", "viewport", "Viewport & render", "The workflow", "See the planting at the detail you need."),
    ("10_STATISTICS_AND_RECORDING.md", "diagnostics", "Statistics & recording", "Beyond the basics", "Read the result. Capture a useful report."),
    ("11_OTHER_EDITING_VIEWS.md", "editing", "Other editing views", "Beyond the basics", "One recipe, multiple ways to edit."),
    ("12_SURFACE_ANALYZER.md", "analyzer", "Surface Analyzer", "Beyond the basics", "Read a surface before you place the plants."),
    ("13_AUTOMATION_AND_LIMITS.md", "limits", "Automation & limits", "Beyond the basics", "Know what is supported, and what is still ahead."),
    ("14_REVIEW_AND_WALKTHROUGH.md", "walkthrough", "Artist walkthrough", "Reference", "A practical checklist for your next test scene."),
    ("15_CONTROL_INDEX.md", "index", "Complete control index", "Reference", "Find the precise control in its own context."),
]
FILES = {m[0]: m[1] for m in META}


def slug(value):
    value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", "-", value).strip("-") or "section"


def plain(value):
    value = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", value)
    return re.sub(r"[*`_]", "", value).strip()


def inline(value):
    value = html.escape(value)
    def link(match):
        label, target = match.groups()
        if target in FILES:
            target = "#/doc/" + FILES[target]
        elif not target.startswith(("https://", "http://", "#")):
            raise ValueError("Unresolved reference link: " + target)
        return '<a href="' + target + '">' + label + '</a>'
    value = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, value)
    value = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"`([^`]+)`", r"<code>\1</code>", value)
    return value


def scope_for(doc, section):
    s = section.lower()
    if doc == "setup":
        if "layer controls" in s or "layer management" in s: return "Layer"
        if "paint" in s: return "Paint set"
        if "layer" in s: return "Layer"
        return "Setup"
    if doc == "models":
        if "rectangle itself" in s: return "Container"
        if "source pool" in s: return "Paint set"
        return "Source"
    if doc in ("assignment", "population", "areas", "transforms"): return "Layer"
    if doc == "painting": return "Paint set"
    if doc == "spacing":
        if "individual" in s: return "Instance"
        if "relax" in s or "cleanup" in s: return "Layer"
        return "Selected scope"
    if doc == "viewport": return "Setup"
    if doc == "diagnostics": return "Session" if "record" in s else "Setup"
    if doc == "editing": return "Instance" if "cs edit" in s else "Selected context"
    if doc == "analyzer": return "Analyzer"
    if doc == "limits": return "Connection" if "automation panel" in s else "Reference"
    return "Reference"


def parse_doc(meta, raw):
    filename, doc, label, category, description = meta
    lines = raw.splitlines()
    out, headings, search, rows, paragraphs = [], [], [], [], []
    ids, section, details_level, i = {}, label, 0, 0
    def ident(name):
        key = slug(name)
        ids[key] = ids.get(key, 0) + 1
        return key + ("-" + str(ids[key]) if ids[key] > 1 else "")
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        heading = re.match(r"^(#{1,3})\s+(.+)", line)
        if heading:
            level, title = len(heading[1]), plain(heading[2])
            if details_level and level <= details_level:
                out.append("</div></details>")
                details_level = 0
            if level == 1:
                i += 1
                continue
            section = title
            anchor = ident(title)
            advanced = title.startswith("Advanced")
            headings.append(dict(title=title, anchor=anchor, level=level, advanced=advanced))
            if advanced:
                details_level = level
                out.append(f'<details class="advanced" id="{anchor}"><summary><span class="advanced-tag">Advanced</span>{inline(title.split(":",1)[-1].strip())}<span class="disclosure" aria-hidden="true">+</span></summary><div class="advanced-body">')
            else:
                out.append(f'<h{level} id="{anchor}">{inline(title)}<a class="heading-link" href="#/doc/{doc}/{anchor}" aria-label="Link to {html.escape(title)}">#</a></h{level}>')
            i += 1
            continue
        if line.startswith("|"):
            table = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [cell.strip() for cell in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-+:?", c.replace(" ", "")) for c in cells): table.append(cells)
                i += 1
            headers = table[0]
            out.append('<div class="table-scroll" tabindex="0" role="region" aria-label="' + html.escape(section) + ' reference table"><table><thead><tr>' + ''.join('<th scope="col">'+inline(c)+'</th>' for c in headers) + '</tr></thead><tbody>')
            for cells in table[1:]:
                name, meaning = plain(cells[0]), " ".join(plain(c) for c in cells[1:])
                anchor = ident("control-" + name)
                row = dict(doc=doc, anchor=anchor, label=name, description=meaning, section=section, scope=scope_for(doc,section), advanced=bool(details_level), cells=cells)
                rows.append(row)
                if doc != "index": search.append({k:v for k,v in row.items() if k != "cells"})
                out.append(f'<tr id="{anchor}">' + ''.join(('<th scope="row">' if n == 0 else '<td>')+inline(c)+('</th>' if n == 0 else '</td>') for n,c in enumerate(cells))+'</tr>')
            out.append('</tbody></table></div>')
            continue
        if re.match(r"^(?:- |\d+\. )",line):
            ordered = bool(re.match(r"^\d+\.", line))
            tag = "ol" if ordered else "ul"
            out.append('<'+tag+'>')
            group = []
            while i < len(lines) and re.match(r"^(?:- |\d+\. )",lines[i].strip()):
                item = re.sub(r"^(?:- |\d+\. )","",lines[i].strip())
                out.append('<li>'+inline(item)+'</li>')
                group.append(plain(item))
                i += 1
            out.append('</'+tag+'>')
            search.append(dict(doc=doc, anchor=headings[-1]["anchor"] if headings else "", label=section, description=" ".join(group), section=section, scope=scope_for(doc,section),advanced=bool(details_level)))
            continue
        p = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r"^(?:#|\||- |\d+\. )",lines[i].strip()):
            p.append(lines[i].strip())
            i += 1
        value = " ".join(p)
        if value == "[Guide contents](README.md)": continue
        anchor = ident("note-"+section)
        out.append('<p id="'+anchor+'">'+inline(value)+'</p>')
        paragraphs.append(plain(value))
        search.append(dict(doc=doc, anchor=anchor,label=section,description=plain(value),section=section,scope=scope_for(doc,section),advanced=bool(details_level)))
    if details_level: out.append('</div></details>')
    return dict(id=doc,file=filename,label=label,category=category,description=description,html="\n".join(out),headings=headings,rows=rows,search=search,words=len(raw.split()),title=plain(lines[0].lstrip("# ")),sha256=hashlib.sha256(raw.encode()).hexdigest())


# These distinguish controls with the same visible label by their inventory context.
PREFERRED_SECTIONS = {
    "Whole setup":"Top controls", "Manual, Live and Update":"Top controls",
    "Receiving surfaces":"Receiving surfaces", "Layers":"Layers & paint sets",
    "Paint sets":"Selected paint set", "Local recording":"Local diagnostic",
    "Selected source":"Models and their settings", "Source pools":"Source pool",
    "Selected source container":"Selecting and moving", "Population and sampling":"Common controls",
    "Target and retry":"Target and bounded", "Coverage and saved strokes":"Paint the allowed",
    "Background planting":"Background planting", "Individual instance radii":"Individual CS Edit",
    "Candidate Relax":"Candidate Relax", "Cleanup":"Cleanup",
}
ALIASES = {
    "Viewport update":"Manual", "Global source containers — now opened through Advanced":"Global source containers list",
    "Global source containers":"Global source containers list", "Point / Empty sources and color groups — now under Advanced":"Add Point",
    "Analyzer and falloff details — now under Advanced":"Refresh areas / preview",
    "Brush feedback and history — now under Advanced":"Softness",
    "Source pool":"Manual sources", "Rectangles":"Rectangles list", "Per m2":"Plants per m2",
    "Population":"Population: Count", "Method":"Method: Random", "Layer population":"Candidate budget",
    "This set: background":"Off", "Coverage":"Coverage: Whole shared surface", "Next stroke":"Next stroke: Paint / Erase",
    "Strength %":"Strength", "Softness %":"Softness", "Paint feedback":"Paint feedback: Coverage samples",
    "Selected CS Edit instances":"Selection / override information", "Spacing scope":"This paint set",
    "Source assignment":"Random", "Analyzer data":"Border", "Assign by":"Assign by: Color groups",
    "Width":"Width", "Length":"Width / Length", "Source/group choices (Ctrl/Shift)":"Source/group choices",
    "Sources list (Ctrl/Shift)":"Sources list", "Closed lines / shapes":"Closed lines / shapes list",
    "Selected area mode":"Selected area mode: Include", "Line ends":"Line ends: Flat / Round",
    "Edge falloff target":"Edge falloff target: Analyzer Boundary", "Display mode":"Display mode: Point Cloud",
    "Preview color":"Preview color: Solid Color", "Corner radius":"Corner radius / Blend radius",
}


def score_row(entry, row):
    raw = entry["label"]
    name = ALIASES.get(raw, raw)
    if entry["section"] == "Candidate Relax" and raw == "Strength %": name = "Strength %"
    if entry["section"] == "Selected source container" and raw == "Width": name = "Width / Length"
    if raw.startswith("Boundary Relax: "): name = raw.split(": ")[1]
    if re.search(r" (min|max)$",name): name = re.sub(r" (min|max)$"," min / max",name)
    if raw in ("Scale min","Scale max"): name = "Scale min / Scale max"
    if name in ("Move up","Move down"): name = "Move up / Move down"
    if name.startswith("Local "): name = "Local X / Local Y / Local Z (deg)"
    if name in ("Add Outside","Add Inside"): name = "Add Outside / Add Inside"
    if name in ("Trim start","Trim end"): name = "Trim start / Trim end"
    target, candidate = slug(name), slug(row["label"])
    score = 100 if target == candidate else 45 if target in candidate or candidate in target else 0
    if not score: return 0
    preferred = PREFERRED_SECTIONS.get(entry["section"], "")
    if preferred and preferred.lower() in row["section"].lower(): score += 25
    if entry["section"] == "Paint sets" and "Paint-set management" in row["section"]: score += 25
    if entry["section"] == "Layers" and "Layer management" in row["section"]: score += 25
    if raw.startswith("Boundary Relax: ") and row["label"] in ("Strength","Iterations","Max movement"):
        if "Boundary Relax" in row["description"]: score += 50
    return score


def build(source, check=False):
    docs = [parse_doc(meta,(source/meta[0]).read_text(encoding="utf-8-sig")) for meta in META]
    by_id = {doc["id"]:doc for doc in docs}
    entries=[]
    occurrences={}
    for index,row in enumerate(by_id["index"]["rows"]):
        file = re.search(r"\]\(([^)]+)\)",row["cells"][1])[1]
        target=by_id[FILES[file]]
        candidates=sorted(target["rows"],key=lambda r:score_row(row,r),reverse=True)
        chosen=candidates[0]
        occurrence_key=(row['section'],row['label'])
        occurrences[occurrence_key]=occurrences.get(occurrence_key,0)+1
        if occurrences[occurrence_key]>1:
            exact=[r for r in target['rows'] if r['label']==row['label']]
            if len(exact)>=occurrences[occurrence_key]: chosen=exact[occurrences[occurrence_key]-1]
        if score_row(row,chosen)==0:
            matches=[item for item in target['search'] if row['label'].lower() in item['description'].lower()]
            assert matches,(row["section"],row["label"])
            chosen=matches[0]
        entries.append(dict(id=f"inventory-{index+1:03}",label=row["label"],section=row["section"],doc=target["id"],anchor=chosen["anchor"],description=chosen["description"],scope=chosen["scope"],advanced=chosen["advanced"],indexAnchor=row["anchor"],source=file))
    assert len(entries)==240, len(entries)
    # The index now links directly to a precise explanation, rather than just a chapter.
    for entry in entries:
        pattern = '(<tr id="'+re.escape(entry['indexAnchor'])+'">[\s\S]*?<a href=")#[^"]+(">Read guide</a>)'
        by_id["index"]["html"]=re.sub(pattern,lambda m:m[1]+f'#/doc/{entry["doc"]}/{entry["anchor"]}'+m[2],by_id["index"]["html"],count=1)
    data=dict(version="0.73",date="7 October 2026",baseline=BASELINE,documents=docs,inventory=entries)
    rendered="// Generated by tools/import_reference.py. Edit source Markdown, then rebuild.\nwindow.CYRUS_GUIDE = "+json.dumps(data,ensure_ascii=False,separators=(",",":"))+";\n"
    coverage=dict(sourceBaseline=BASELINE,sourceDate="2026-10-07",documents=len(docs),inventoryEntries=len(entries),walkthroughSteps=len([r for r in by_id['walkthrough']['rows'] if r['label'].isdigit()]),entries=entries,sources=[dict(file=d['file'],sha256=hashlib.sha256((source/d['file']).read_bytes()).hexdigest(),route='#/doc/'+d['id'],words=d['words']) for d in docs])
    coverage_text=json.dumps(coverage,ensure_ascii=False,indent=2)+"\n"
    if check:
        assert (ROOT/"content/reference.js").read_text(encoding="utf-8")==rendered,"reference.js is stale"
        assert (ROOT/"content/coverage.json").read_text(encoding="utf-8")==coverage_text,"coverage.json is stale"
        for meta in META: assert (ROOT/'sources'/meta[0]).read_bytes()==(source/meta[0]).read_bytes(),"Source snapshot changed"
    else:
        (ROOT/"content").mkdir(parents=True,exist_ok=True)
        (ROOT/"sources").mkdir(exist_ok=True)
        for meta in META:
            if source.resolve() != (ROOT/"sources").resolve(): shutil.copyfile(source/meta[0],ROOT/"sources"/meta[0])
        (ROOT/"content/reference.js").write_text(rendered,encoding="utf-8")
        (ROOT/"content/coverage.json").write_text(coverage_text,encoding="utf-8")
    print(f"{'Verified' if check else 'Built'} {len(docs)} chapters, {len(entries)} mapped inventory entries, {coverage['walkthroughSteps']} walkthrough steps.")


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--source",type=Path,default=DEFAULT_SOURCE if DEFAULT_SOURCE.exists() else ROOT/'sources')
    parser.add_argument("--check",action="store_true")
    args=parser.parse_args()
    build(args.source,args.check)
