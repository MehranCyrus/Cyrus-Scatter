"""Preserve primary brush pages privately with retrieval identity."""
import argparse
import hashlib
import importlib.util
import json
from datetime import datetime,timezone
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import requests

PAGES={
 'areas':'https://docs.itoosoft.com/forestpack/forest-plugin/areas',
 'item-editor':'https://docs.itoosoft.com/forestpack/forest-plugin/item-editor',
 'brush-size-change':'https://docs.itoosoft.com/changelog/2022/11/02/forestpack-8_0_4',
 'paint-transform-kb':'https://docs.itoosoft.com/kb/forest-pack/when-i-use-the-paint-tool-the-items-are-displaced-in-relation-to-the-brush-strokes-why',
 'paint-tutorial':'https://www.itoosoft.com/tutorials/modernbarn2',
 'painting-lite':'https://www.itoosoft.com/tutorials/getting-started-with-forest-pack-lite',
}

def main():
 p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);args=p.parse_args();run=args.run.resolve()
 if not run.is_relative_to(Path.cwd()/'build'):raise ValueError('Use build')
 folder=run/'official-docs';folder.mkdir(exist_ok=False)
 spec=importlib.util.spec_from_file_location('docs_parser',Path('docs/ForestPack_Research_2026-10-08/reproduce/collect_docs.py'))
 module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 def fetch(item):
  name,url=item
  try:
   r=requests.get(url,timeout=30);r.raise_for_status();(folder/(name+'.html')).write_bytes(r.content)
   article=module.Article();article.feed(r.content.decode('utf-8'))
   (folder/(name+'.txt')).write_text('\n'.join(x.strip() for x in ''.join(article.text).splitlines() if x.strip()),encoding='utf-8')
   return dict(name=name,url=url,status=r.status_code,sha256=hashlib.sha256(r.content).hexdigest(),utc=datetime.now(timezone.utc).isoformat())
  except Exception as e:return dict(name=name,url=url,error=str(e))
 with ThreadPoolExecutor(max_workers=4) as pool:records=list(pool.map(fetch,PAGES.items()))
 (folder/'sources.json').write_text(json.dumps(records,indent=2),encoding='utf-8');print(json.dumps(records,indent=2))

if __name__=='__main__':main()
