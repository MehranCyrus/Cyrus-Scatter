"""Cache official documentation privately; retain URLs and retrieval hashes."""
import argparse
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
import requests


PAGES = {
    'lite-pro':'https://docs.itoosoft.com/forestpack/lite-and-pro',
    'ui':'https://docs.itoosoft.com/forestpack/forest-plugin/ui',
    'geometry':'https://docs.itoosoft.com/forestpack/forest-plugin/add-geometry',
    'distribution':'https://docs.itoosoft.com/forestpack/forest-plugin/distribution',
    'image':'https://docs.itoosoft.com/forestpack/forest-plugin/distribution/image-mode',
    'areas':'https://docs.itoosoft.com/forestpack/forest-plugin/areas',
    'surfaces':'https://docs.itoosoft.com/forestpack/forest-plugin/surfaces',
    'transform':'https://docs.itoosoft.com/forestpack/forest-plugin/transform',
    'camera':'https://docs.itoosoft.com/forestpack/forest-plugin/camera',
    'items-editor':'https://docs.itoosoft.com/forestpack/forest-plugin/item-editor',
    'path':'https://docs.itoosoft.com/forestpack/forest-plugin/distribution/path-mode',
    'reference':'https://docs.itoosoft.com/forestpack/forest-plugin/distribution/reference-mode',
    'particle-flow':'https://docs.itoosoft.com/forestpack/forest-plugin/distribution/particle-flow-mode',
    'effects':'https://docs.itoosoft.com/forestpack/forest-plugin/effects',
    'effects-syntax':'https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/effects-syntax',
    'effects-attributes':'https://docs.itoosoft.com/forestpack/forest-plugin/effects/creating-and-editing-effects/attributes',
    'animation':'https://docs.itoosoft.com/forestpack/forest-plugin/animation',
    'display':'https://docs.itoosoft.com/forestpack/forest-plugin/display',
    'general':'https://docs.itoosoft.com/forestpack/forest-plugin/general',
}


class Article(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.text = []
        self.skip = 0
    def handle_starttag(self, tag, attrs):
        if tag == 'article': self.depth += 1
        if not self.depth: return
        if tag in {'script','style'}: self.skip += 1
        if tag in {'p','div','li','tr','h1','h2','h3','h4','h5'}: self.text.append('\n')
        if tag == 'img':
            alt = dict(attrs).get('alt','')
            if alt: self.text.append(f' [image: {alt}] ')
        if tag == 'td': self.text.append(' | ')
    def handle_endtag(self, tag):
        if tag == 'article': self.depth -= 1
        if self.depth and tag in {'script','style'}: self.skip -= 1
    def handle_data(self, data):
        if self.depth and not self.skip: self.text.append(data)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--supplement',action='store_true')
    args = parser.parse_args()
    run = args.run.resolve()
    if not run.is_relative_to(Path.cwd()/'build'): raise ValueError('Use build/')
    folder = run/('official-docs-supplement' if args.supplement else 'official-docs')
    folder.mkdir(exist_ok=False)
    def fetch(item):
        name,url = item
        try:
            response = requests.get(url,timeout=30)
            response.raise_for_status()
            (folder/f'{name}.html').write_bytes(response.content)
            article = Article()
            article.feed(response.content.decode('utf-8'))
            lines = [x.strip() for x in ''.join(article.text).splitlines() if x.strip()]
            (folder/f'{name}.txt').write_text('\n'.join(lines),encoding='utf-8')
            return dict(name=name,url=url,resolved_url=response.url,status=response.status_code,
                        sha256=hashlib.sha256(response.content).hexdigest(),text_lines=len(lines))
        except Exception as error:
            return dict(name=name,url=url,error=str(error))
    pages = {k:v for k,v in PAGES.items() if k in {'items-editor','path','reference','particle-flow'}} if args.supplement else PAGES
    with ThreadPoolExecutor(max_workers=4) as executor: records = list(executor.map(fetch,pages.items()))
    receipt = dict(retrieved_utc=datetime.now(timezone.utc).isoformat(),pages=records)
    (folder/'sources.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
    print(json.dumps(records,indent=2))


if __name__ == '__main__': main()
