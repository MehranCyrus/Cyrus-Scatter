"""Deterministic public content build from explicitly maintained repository sources."""
from pathlib import Path
import argparse
import hashlib
import html
import json
import re
import unicodedata

SITE = Path(__file__).resolve().parents[1]
REPO = SITE.parent
MANIFEST = SITE / "content" / "source-manifest.json"


def slug(text):
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", "-", text).strip("-") or "section"


def decode(data):
    return re.sub(r'[\udc80-\udcff]', lambda m: bytes([ord(m[0])-0xdc00]).decode('cp1252'), data.decode('utf-8-sig', errors='surrogateescape'))


def plain(text):
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return re.sub(r"[*`_]", "", text)


def build():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    docs = manifest["documents"]
    chapters = json.loads((SITE / 'content/guide-chapters.json').read_text(encoding='utf-8'))
    sources = []
    output = {}

    def local_link(target, owner):
        target = html.unescape(target)
        if target.startswith(("https://", "http://", "mailto:", "#/")) and '.md' not in target.lower():
            return target
        raise ValueError(f'Public chapters must link to website pages, not repository files: {target}')

    def render(raw, owner, docid):
        headings, records, chunks = [], [], []
        used = {}
        section = "Overview"
        anchor = ""

        def inline(value):
            links = []
            def link(m):
                token = f"LINKTOKEN{len(links)}END"
                dest = local_link(m[2], owner)
                ext = ' target="_blank" rel="noopener noreferrer"' if dest.startswith('http') else ''
                links.append(f'<a href="{html.escape(dest, quote=True)}"{ext}>{html.escape(m[1])}</a>')
                return token
            value = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link, value)
            value = html.escape(value)
            value = re.sub(r"`([^`]+)`", r"<code>\1</code>", value)
            value = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", value)
            for i, text in enumerate(links):
                value = value.replace(f"LINKTOKEN{i}END", text)
            return value

        def record(text):
            if text.strip():
                records.append({"doc": docid, "anchor": anchor, "title": section, "text": plain(text)})

        lines = raw.splitlines()
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if not line:
                i += 1; continue
            if line.startswith("```"):
                code = []; i += 1
                while i < len(lines) and not lines[i].strip().startswith("```"):
                    code.append(lines[i]); i += 1
                chunks.append("<pre><code>" + html.escape("\n".join(code)) + "</code></pre>")
                record(" ".join(code)); i += 1; continue
            match = re.match(r"^(#{1,6})\s+(.+)", line)
            if match:
                level = len(match[1]); section = plain(match[2]); base = slug(section)
                used[base] = used.get(base, 0) + 1
                anchor = base + ("-" + str(used[base]) if used[base] > 1 else "")
                if level > 1:
                    headings.append({"title": section, "anchor": anchor, "level": level})
                    chunks.append(f'<h{min(level, 4)} id="{anchor}">{inline(match[2])}<a class="heading-permalink" href="#/guide/{docid}/{anchor}" aria-label="Link to {html.escape(section)}">#</a></h{min(level, 4)}>')
                i += 1; continue
            if line.startswith("|"):
                rows = []
                while i < len(lines) and lines[i].strip().startswith("|"):
                    cells = [c.strip().replace("\\|", "|") for c in re.split(r"(?<!\\)\|", lines[i].strip().strip("|"))]
                    if not all(re.fullmatch(r":?-+:?", c.replace(" ", "")) for c in cells): rows.append(cells)
                    i += 1
                head = rows.pop(0)
                chunks.append('<div class="table-scroll" tabindex="0" role="region" aria-label="' + html.escape(section) + ' table"><table><thead><tr>' + ''.join('<th scope="col">' + inline(c) + '</th>' for c in head) + '</tr></thead><tbody>' + ''.join('<tr>' + ''.join('<td>' + inline(c) + '</td>' for c in row) + '</tr>' for row in rows) + '</tbody></table></div>')
                for row in rows: record(" — ".join(row))
                continue
            if re.match(r"^(?:[-*] |\d+\. )", line):
                ordered = bool(re.match(r"^\d+\.", line)); tag = "ol" if ordered else "ul"; items = []
                while i < len(lines) and re.match(r"^(?:[-*] |\d+\. )", lines[i].strip()):
                    item = re.sub(r"^(?:[-*] |\d+\. )", "", lines[i].strip()); i += 1
                    while i < len(lines) and lines[i].startswith("  ") and not re.match(r"^\s*(?:[-*] |\d+\. )", lines[i]):
                        item += " " + lines[i].strip(); i += 1
                    items.append('<li>' + inline(item) + '</li>'); record(item)
                chunks.append('<' + tag + '>' + ''.join(items) + '</' + tag + '>'); continue
            para = [line]; i += 1
            while i < len(lines) and lines[i].strip() and not re.match(r"^(?:#|\||```|[-*] |\d+\. )", lines[i].strip()):
                para.append(lines[i].strip()); i += 1
            paragraph = " ".join(para)
            chunks.append("<p>" + inline(paragraph) + "</p>"); record(paragraph)
        return {"html": "\n".join(chunks), "headings": headings, "search": records}

    for doc in docs:
        chapter = chapters[doc['id']]
        raw = '\n\n'.join('## '+s['title']+'\n\n'+'\n\n'.join(s['paragraphs']) for s in chapter['sections'])
        sources.append({**{k:doc[k] for k in ('id','title','description')}, **render(raw, None, doc['id']), 'words':len(raw.split())})
    catalog_path = REPO / manifest["catalog"]
    catalog_data = catalog_path.read_bytes(); catalog = json.loads(catalog_data)
    editorial_data = (SITE / "content" / "control-explanations.json").read_bytes()
    editorial = json.loads(editorial_data)
    for control in catalog["controls"]:
        key = '.'.join(control[k] for k in ('group', 'section', 'name'))
        control["id"] = "control-" + slug(key)
        control["sourceKey"] = key
        explanation = editorial[key]
        control["label"] = explanation["label"]
        control["description"] = explanation["help"]
        control["displayOwner"] = explanation.get("owner_context", control["owner_context"])
    history = json.loads((SITE/'content/changelog.json').read_text(encoding='utf-8'))
    public_history = [{k:v for k,v in entry.items() if k != 'evidence'} for entry in history['entries']]
    analyzer_doc = next(doc for doc in docs if doc['id'] == 'surface-analyzer')
    analyzer_version = re.search(r'^# Cyrus Surface Analyzer ([0-9.]+)\s*$', decode((REPO / analyzer_doc['path']).read_bytes()), re.MULTILINE).group(1)
    result = {"schema": "cyrus.public-guide/3.0", "developmentVersion": catalog["development_version"], "artistWorkflowVersion": manifest["artistWorkflowVersion"], "analyzerVersion": analyzer_version, "mcpVersion": catalog["mcp_version"], "reviewed": manifest["reviewed"], "documents": sources, 'changelog':public_history, "features": catalog["features"], "controls": catalog["controls"]}
    output[SITE / "src" / "content" / "reference.json"] = (json.dumps(result, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--check", action="store_true"); args = parser.parse_args()
    outputs = build(); stale = []
    for path, data in outputs.items():
        if args.check:
            if not path.is_file() or path.read_bytes() != data: stale.append(str(path.relative_to(SITE)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data)
    if stale: raise SystemExit("Stale generated content: " + ", ".join(stale))
    print(f"{'Checked' if args.check else 'Generated'} {len(outputs)} deterministic current-source outputs.")
