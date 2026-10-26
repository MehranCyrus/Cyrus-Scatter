"""Build the local research reading editions from the adjacent Markdown.

Python stdlib builds HTML; --pdf additionally requires ReportLab. This deliberately
supports the small Markdown subset used by this documentation set, not arbitrary
Markdown or executable source HTML. Original reports are linked, never executed.
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
CHAPTERS = sorted(ROOT.glob('[0-9][0-9]-*.md'))
APPENDICES = [ROOT / p for p in (
    'checklists/ASSET-AUDIT.md', 'checklists/VALIDATION-MATRIX.md',
    'checklists/SOLVER-DECISION-EXPERIMENTS.md',
    'checklists/RECIPE-COMPARISON.md', 'sources/README.md',
    'references/PRIMARY-SOURCES.md')]
DOCS = [ROOT / 'README.md', *CHAPTERS, *APPENDICES]
INLINE = re.compile(r'\[([^\]]+)\]\((<[^>]*>|[^)]*)\)|\*\*([^*]+)\*\*|`([^`]+)`')


def slug(text):
    return re.sub(r'\s+', '-', re.sub(r'[^\w\s-]', '', text.lower())).strip('-')


def doc_id(path):
    return 'doc-' + slug(path.relative_to(ROOT).as_posix().removesuffix('.md'))


def title(path):
    return path.read_text(encoding='utf-8').splitlines()[0].lstrip('# ')


def library_counts():
    manifest = json.loads((ROOT / 'sources/manifest.json').read_text(encoding='utf-8'))
    matrix = (ROOT / 'checklists/VALIDATION-MATRIX.md').read_text(encoding='utf-8')
    return len(manifest['sources']), len(re.findall(r'^\| V\d+ \|', matrix, re.M))


def blocks(path):
    lines = path.read_text(encoding='utf-8').splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('#'):
            mark, text = line.split(' ', 1)
            yield 'heading', (len(mark), text)
            i += 1
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', c) for c in cells):
                    rows.append(cells)
                i += 1
            if len({len(r) for r in rows}) != 1:
                raise ValueError(f'Inconsistent table width: {path}')
            yield 'table', rows
        elif re.match(r'^(- |\d+\. )', line):
            ordered = line[0].isdigit()
            items = []
            while i < len(lines) and re.match(r'^(- |\d+\. )', lines[i].strip()):
                items.append(re.sub(r'^(- |\d+\. )', '', lines[i].strip()))
                i += 1
            yield 'list', (ordered, items)
        else:
            paragraph = [line]
            i += 1
            while i < len(lines) and lines[i].strip() and not re.match(r'^(#|\||- |\d+\. )', lines[i].strip()):
                paragraph.append(lines[i].strip())
                i += 1
            yield 'paragraph', ' '.join(paragraph)


def target(href, source, pdf=False):
    href = href.strip('<>')
    parts = urlsplit(href)
    if parts.scheme in ('http', 'https', 'mailto'):
        return href
    local = (source.parent / unquote(parts.path)).resolve() if parts.path else source
    if local in DOCS:
        return '#' + doc_id(local) + ('-' + parts.fragment if parts.fragment else '')
    if pdf:
        return None
    relative = os.path.relpath(local, ROOT).replace(os.sep, '/')
    return quote(relative, safe='/._-') + ('#' + parts.fragment if parts.fragment else '')


def inline(text, source, pdf=False):
    out, start = [], 0
    for match in INLINE.finditer(text):
        out.append(html.escape(text[start:match.start()]))
        if match.group(1) is not None:
            label = html.escape(match.group(1))
            href = target(match.group(2), source, pdf)
            if href:
                tag = 'link' if pdf else 'a'
                out.append(f'<{tag} href="{html.escape(href, quote=True)}">{label}</{tag}>')
            else:
                out.append(label)
        elif match.group(3) is not None:
            out.append('<b>' + html.escape(match.group(3)) + '</b>')
        else:
            tag = 'font face="Courier"' if pdf else 'code'
            end = 'font' if pdf else 'code'
            out.append(f'<{tag}>' + html.escape(match.group(4)) + f'</{end}>')
        start = match.end()
    out.append(html.escape(text[start:]))
    return ''.join(out)


def section_html(path):
    out = [f'<article id="{doc_id(path)}" class="chapter">']
    for kind, value in blocks(path):
        if kind == 'heading':
            level, text = value
            level = min(level + 1, 6)
            anchor = doc_id(path) + '-' + slug(text)
            out.append(f'<h{level} id="{anchor}">{inline(text, path)}</h{level}>')
        elif kind == 'paragraph':
            out.append('<p>' + inline(value, path) + '</p>')
        elif kind == 'list':
            ordered, items = value
            tag = 'ol' if ordered else 'ul'
            out.append(f'<{tag}>' + ''.join('<li>' + inline(s, path) + '</li>' for s in items) + f'</{tag}>')
        else:
            rows = value
            table = '<div class="table-wrap"><table><thead><tr>'
            table += ''.join('<th scope="col">' + inline(c, path) + '</th>' for c in rows[0])
            table += '</tr></thead><tbody>'
            table += ''.join('<tr>' + ''.join('<td>' + inline(c, path) + '</td>' for c in row) + '</tr>' for row in rows[1:])
            out.append(table + '</tbody></table></div>')
    out.append(f'<p class="source-note">Editable source: <a href="{quote(path.relative_to(ROOT).as_posix())}">{html.escape(path.name)}</a></p></article>')
    return '\n'.join(out)


def build_html():
    source_count, case_count = library_counts()
    nav = ''.join(f'<a href="#{doc_id(p)}">{html.escape(title(p))}</a>' for p in DOCS)
    body = '\n'.join(section_html(p) for p in DOCS)
    css = '''
    :root{--ink:#183238;--muted:#587079;--accent:#087d75;--line:#d8e4e5;--paper:#fff;--wash:#f2f6f5}
    *{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}
    body{margin:0;color:var(--ink);background:var(--wash);font:16px/1.7 'Segoe UI',Arial,sans-serif}
    a{color:#006d68;text-underline-offset:3px}a:hover{color:#003f3c}a:focus-visible,button:focus-visible{outline:3px solid #c98d35;outline-offset:3px}
    nav{position:fixed;inset:0 auto 0 0;width:294px;padding:36px 24px;background:#123037;color:#dce9e9;overflow:auto}
    .brand{font-size:12px;letter-spacing:.18em;font-weight:700;color:#77d4c2;margin-bottom:28px}
    nav a{display:block;padding:9px 10px;margin:2px 0;color:#e6f0ef;text-decoration:none;font-size:13px;line-height:1.4;border-radius:4px}
    nav a:hover,nav a.active{background:#24444a;color:#fff}nav p{font-size:12px;color:#b0c4c7;margin:24px 10px}
    main{max-width:1300px;margin-left:294px;padding:40px 48px 80px}
    .hero{padding:46px;background:var(--ink);color:#fff;border-top:5px solid #5cc3ac;border-radius:3px}
    .eyebrow{text-transform:uppercase;letter-spacing:.17em;font-size:12px;font-weight:700;color:#87daca}
    h1{font-size:clamp(32px,4vw,58px);line-height:1.1;letter-spacing:-.035em;margin:18px 0 22px;font-weight:650;max-width:780px}
    .hero p{color:#d5e4e5;max-width:720px}.hero .links{display:flex;gap:12px;flex-wrap:wrap;margin-top:26px}
    .button{padding:9px 18px;border:1px solid #72b4ac;color:#fff;border-radius:4px;text-decoration:none;font-size:14px}
    .stats{display:flex;gap:35px;flex-wrap:wrap;padding-top:24px;margin-top:25px;border-top:1px solid #3b585e}
    .stat strong{font-size:27px;display:block;color:#a7e0d4;line-height:1.3}.stat span{font-size:12px;color:#c4d6d8}
    .flow{display:grid;grid-template-columns:repeat(5,1fr);gap:8px;margin:26px 0;font-size:13px}
    .flow div{background:#e4efeb;border:1px solid #c7ddd4;border-radius:4px;padding:14px 10px;text-align:center;font-weight:600}
    .chapter{background:var(--paper);margin:28px 0;padding:40px 42px;border:1px solid var(--line);border-radius:4px;box-shadow:0 4px 18px #153a3b04}
    h2{font-size:30px;line-height:1.2;margin:0 0 24px;letter-spacing:-.025em;color:#143f43}
    h3{font-size:21px;line-height:1.4;margin:32px 0 12px;padding-top:12px;border-top:1px solid #e4eceb}
    h4{font-size:18px}p{margin:12px 0}li{margin:7px 0}ul,ol{padding-left:25px}
    .table-wrap{overflow-x:auto;margin:21px 0;border:1px solid var(--line);border-radius:4px}
    table{width:100%;border-collapse:collapse;font-size:13px;line-height:1.55;min-width:570px}
    th{background:#e8f0ee;color:#194e4e;text-align:left;font-weight:650;padding:13px 14px;vertical-align:top}
    td{padding:12px 14px;vertical-align:top;border-top:1px solid #e0e9e7;overflow-wrap:anywhere}
    tbody tr:nth-child(even){background:#f8faf9}td:first-child{font-weight:600;min-width:95px}
    code{background:#eef3f2;padding:2px 5px;border-radius:3px;font-size:.9em}.source-note{font-size:12px;color:var(--muted);margin-top:30px;padding-top:15px;border-top:1px solid var(--line)}
    footer{font-size:12px;color:var(--muted);padding:20px 5px}
    @media(max-width:1100px){nav{width:250px;padding:28px 16px}main{margin-left:250px;padding:28px}.chapter{padding:30px}.hero{padding:32px}}
    @media(max-width:760px){nav{position:static;width:auto;max-height:280px}main{margin:0;padding:16px}.chapter,.hero{padding:25px}h2{font-size:26px}.flow{grid-template-columns:1fr}.stats{gap:22px}}
    @media print{body{background:white;font-size:10pt}nav,.links,.source-note{display:none}main{margin:0;max-width:none;padding:0}.hero{background:white;color:#14343b;border:0;padding:20px 0}.hero p,.stat span{color:#47626a}.stat strong{color:#087d75}h1{font-size:35pt}.chapter{border:0;box-shadow:none;padding:0;break-before:page}h2,h3{break-after:avoid}.table-wrap{overflow:visible}table{min-width:0;font-size:8.5pt}tr{break-inside:avoid}a{color:inherit}footer{display:none}}
    '''
    result = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CyrusScatter | Vegetation Interaction Research Library</title><style>{css}</style></head><body>
    <nav aria-label="Handbook contents"><div class="brand">CYRUS SCATTER<br>RESEARCH LIBRARY</div>{nav}<p>24 October 2026<br>Research and proposed design<br>{source_count} original files preserved</p></nav>
    <main><header class="hero"><div class="eyebrow">Engineering research / consolidated edition</div><h1>Vegetation<br>interaction</h1><p>Prepared grass that bends naturally around fixed obstacles. A decision library covering artist workflow, source preparation, contact, geometry delivery and validation.</p><div class="links"><a class="button" href="handbook.pdf">Open PDF</a><a class="button" href="README.md">Document index</a><a class="button" href="#doc-sourcesreadme">Original research register</a></div><div class="stats"><div class="stat"><strong>09</strong><span>Core documents</span></div><div class="stat"><strong>{source_count:02d}</strong><span>Original files</span></div><div class="stat"><strong>{case_count}</strong><span>Proposed validation cases</span></div><div class="stat"><strong>Research</strong><span>Implementation remains unqualified</span></div></div></header>
    <div class="flow" aria-label="Proposed fitting pipeline"><div>Prepare source</div><div>Find contacts</div><div>Fit drivers</div><div>Validate mesh</div><div>Publish result</div></div>
    {body}<footer>CyrusScatter research library. Editable Markdown is authoritative for this consolidation. Supplied originals retain their own claims and qualification limits.</footer></main>
    <script>const links=[...document.querySelectorAll('nav a')];const observer=new IntersectionObserver(entries=>{{for(const e of entries)if(e.isIntersecting){{for(const a of links)a.classList.toggle('active',a.hash==='#'+e.target.id);}}}},{{rootMargin:'0px 0px -72% 0px'}});document.querySelectorAll('article').forEach(a=>observer.observe(a));</script></body></html>'''
    (ROOT / 'handbook.html').write_text(result, encoding='utf-8', newline='\n')


def build_pdf():
    source_count, case_count = library_counts()
    from reportlab.lib import colors
    from reportlab.lib.enums import TA_LEFT
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.platypus import (BaseDocTemplate, Frame, PageTemplate, Paragraph,
        Spacer, Table, TableStyle, PageBreak, CondPageBreak, HRFlowable)
    from reportlab.platypus.tableofcontents import TableOfContents
    from reportlab.graphics.shapes import Drawing, Rect, String, Line

    font_dir = Path(os.environ.get('WINDIR', 'C:/Windows')) / 'Fonts'
    for name, filename in [('Research', 'calibri.ttf'), ('Research-Bold', 'calibrib.ttf'), ('Research-Italic', 'calibrii.ttf')]:
        if not (font_dir / filename).exists():
            raise RuntimeError('Calibri fonts unavailable; configure equivalent fonts before PDF generation')
        pdfmetrics.registerFont(TTFont(name, str(font_dir / filename)))
    pdfmetrics.registerFontFamily('Research', normal='Research', bold='Research-Bold', italic='Research-Italic', boldItalic='Research-Bold')
    ink, teal, muted = colors.HexColor('#183238'), colors.HexColor('#087d75'), colors.HexColor('#587079')
    width, height = A4
    usable = width - 108
    styles = {
        'body': ParagraphStyle('body', fontName='Research', fontSize=10.5, leading=14.4, textColor=ink, spaceAfter=8, allowWidows=0, allowOrphans=0),
        'h1': ParagraphStyle('chapter', fontName='Research-Bold', fontSize=25, leading=29, textColor=ink, spaceBefore=4, spaceAfter=20, keepWithNext=True),
        'h2': ParagraphStyle('section', fontName='Research-Bold', fontSize=15, leading=19, textColor=teal, spaceBefore=12, spaceAfter=7),
        'cell': ParagraphStyle('cell', fontName='Research', fontSize=8.9, leading=11.6, textColor=ink, splitLongWords=True),
        'headcell': ParagraphStyle('headcell', fontName='Research-Bold', fontSize=8.9, leading=11.6, textColor=colors.white),
        'small': ParagraphStyle('small', fontName='Research', fontSize=9, leading=12.5, textColor=muted, spaceAfter=8),
        'cover': ParagraphStyle('cover', fontName='Research-Bold', fontSize=49, leading=49, textColor=ink, spaceAfter=24),
        'subtitle': ParagraphStyle('subtitle', fontName='Research', fontSize=18, leading=24, textColor=muted, spaceAfter=24),
        'kicker': ParagraphStyle('kicker', fontName='Research-Bold', fontSize=10, leading=14, textColor=teal, spaceAfter=16),
    }

    def clean(s):
        return s.translate(str.maketrans({'\u2010': '-', '\u2011': '-', '\u2012': '-', '\u2013': '-', '\u2014': '-'}))

    def p(text, style='body', source=ROOT / 'README.md'):
        return Paragraph(clean(inline(text, source, pdf=True)), styles[style])

    class ResearchDoc(BaseDocTemplate):
        def afterFlowable(self, flowable):
            anchor = getattr(flowable, '_research_anchor', None)
            if anchor:
                self.canv.bookmarkPage(anchor)
                self.canv.addOutlineEntry(flowable.getPlainText(), anchor, 0, False)
                self.notify('TOCEntry', (0, flowable.getPlainText(), self.page, anchor))

    def furniture(canvas, doc):
        canvas.saveState()
        if doc.page > 1:
            canvas.setFillColor(teal)
            canvas.setFont('Research-Bold', 8)
            canvas.drawString(54, height - 29, 'CYRUS SCATTER / VEGETATION INTERACTION')
            canvas.setFillColor(muted)
            canvas.setFont('Research', 8)
            canvas.drawRightString(width - 54, height - 29, '24 OCTOBER 2026')
            canvas.setStrokeColor(colors.HexColor('#d7e4e1'))
            canvas.line(54, height - 37, width - 54, height - 37)
        canvas.setFillColor(muted)
        canvas.setFont('Research', 8)
        canvas.drawString(54, 29, 'Research and proposed design | No new DCC qualification')
        canvas.drawRightString(width - 54, 29, str(doc.page))
        canvas.restoreState()

    doc = ResearchDoc(str(ROOT / 'handbook.pdf'), pagesize=A4, leftMargin=54,
        rightMargin=54, topMargin=56, bottomMargin=50,
        title='CyrusScatter Vegetation Interaction Research Library',
        author='CyrusScatter research consolidation', pageCompression=1)
    frame = Frame(54, 50, usable, height - 106, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    doc.addPageTemplates(PageTemplate(id='research', frames=frame, onPage=furniture))
    story = [Spacer(1, 46), p('CYRUS SCATTER / RESEARCH LIBRARY', 'kicker'),
        Paragraph('Vegetation<br/>interaction', styles['cover']),
        p('A consolidated decision library for rooted vegetation around fixed obstacles', 'subtitle'),
        p('24 October 2026 | Research and proposed design', 'kicker'), Spacer(1, 12),
        p('Prepare the source once. Keep accepted roots planted. Fit relevant contacts together. Validate the visible mesh and publish a complete result.'),
        Spacer(1, 22)]
    drawing = Drawing(usable, 76)
    gap, box = 7, (usable - 28) / 5
    for i, label in enumerate(['Prepare', 'Find contacts', 'Fit', 'Validate', 'Publish']):
        x = i * (box + gap)
        drawing.add(Rect(x, 18, box, 40, fillColor=colors.HexColor('#e7f1ed'), strokeColor=colors.HexColor('#bddbd1'), radius=3))
        drawing.add(String(x + box / 2, 34, label, textAnchor='middle', fontName='Research-Bold', fontSize=9, fillColor=teal))
        if i < 4:
            drawing.add(Line(x + box, 38, x + box + gap, 38, strokeColor=teal))
    story += [drawing, Spacer(1, 20), p(f'{len(CHAPTERS):02d} core documents / {source_count} preserved source files / {case_count} proposed validation cases', 'kicker'),
        p('This handbook consolidates the supplied research and records corrections, proposed workflows and experiment priorities. It does not report an implemented vegetation feature or executed simulation results.'),
        p('The editable Markdown, checklists, source manifest and original files accompany this PDF. Start with README.md for the complete document register.', 'small'), PageBreak(),
        p('Contents', 'h1')]
    toc = TableOfContents()
    toc.levelStyles = [ParagraphStyle('toc', fontName='Research', fontSize=11, leading=17, textColor=ink, leftIndent=0, firstLineIndent=0, spaceBefore=8)]
    story += [toc, Spacer(1, 22), p('Read Chapters 01, 02 and 09 for product decisions. Use Chapters 03-05 and 08 for engineering, Chapter 06 for vendor workflows, and Chapter 07 with the appendices for experiments.', 'small')]

    for index, source in enumerate([*CHAPTERS, *APPENDICES]):
        if index == 0:
            story.append(PageBreak())
        else:
            story += [CondPageBreak(320), HRFlowable(width='100%', thickness=0.6,
                color=colors.HexColor('#d7e4e1'), spaceBefore=16, spaceAfter=20)]
        for kind, value in blocks(source):
            if kind == 'heading':
                level, text = value
                para = p(text, 'h1' if level == 1 else 'h2', source)
                if level == 1:
                    para._research_anchor = doc_id(source)
                else:
                    story.append(CondPageBreak(110))
                story.append(para)
            elif kind == 'paragraph':
                story.append(p(value, source=source))
            elif kind == 'list':
                ordered, items = value
                for i, item in enumerate(items):
                    mark = str(i + 1) + '.' if ordered else '\u2022'
                    story.append(p(mark + ' ' + item, source=source))
            else:
                rows = value
                n = len(rows[0])
                fractions = {2: [0.29, 0.71], 3: [0.22, 0.35, 0.43], 4: [0.15, 0.30, 0.25, 0.30], 5: [0.09, 0.25, 0.41, 0.10, 0.15]}[n]
                if n == 3 and rows[0][0] == 'ID':
                    fractions = [0.09, 0.41, 0.50]
                if source.name == 'README.md':
                    fractions = [0.08, 0.30, 0.10, 0.52]
                data = [[p(c, 'headcell' if i == 0 else 'cell', source) for c in row] for i, row in enumerate(rows)]
                table = Table(data, colWidths=[usable * f for f in fractions], repeatRows=1, hAlign='LEFT')
                table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), teal),
                    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.HexColor('#f0f5f3'), colors.white]),
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                    ('LEFTPADDING', (0, 0), (-1, -1), 8), ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                    ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                    ('LINEBELOW', (0, 0), (-1, 0), 0.5, teal),
                    ('LINEBELOW', (0, 1), (-1, -1), 0.3, colors.HexColor('#d7e4e1'))]))
                story += [table, Spacer(1, 11)]
    doc.multiBuild(story)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pdf', action='store_true', help='Also build PDF; requires ReportLab and Calibri fonts')
    args = parser.parse_args()
    if len(CHAPTERS) != 9:
        raise RuntimeError('Expected nine numbered chapters')
    build_html()
    if args.pdf:
        build_pdf()
    outputs = ['handbook.html', *(['handbook.pdf'] if args.pdf else [])]
    print(json.dumps({'outputs': [{ 'path': str(ROOT / n), 'bytes': (ROOT / n).stat().st_size,
        'sha256': hashlib.sha256((ROOT / n).read_bytes()).hexdigest()} for n in outputs]}, indent=2))


if __name__ == '__main__':
    main()
