"""Read-only product audit; writes only this review bundle and its owned build root."""
from pathlib import Path
import csv,datetime,hashlib,json,re,shutil,statistics,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[4];REPORT=Path(__file__).resolve().parent.parent;BUILD=ROOT/'build/full-system-review-08763-20261029-01';E=REPORT/'evidence';E.mkdir(exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(path,value):path.write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT,text=True,encoding='utf-8')

native=json.loads((BUILD/'native/receipt.json').read_text());old=json.loads((ROOT/'build/interaction-review-08763-20261029-01/native-2027/receipt.json').read_text())
changed={p:{'built':h,'now':sha(ROOT/p) if (ROOT/p).is_file() else None} for p,h in native['sources'].items() if not (ROOT/p).is_file() or sha(ROOT/p)!=h}
qualified_changed={p:{'qualified':h,'now':sha(ROOT/p) if (ROOT/p).is_file() else None} for p,h in old['sources'].items() if not p.startswith('build/') and (not (ROOT/p).is_file() or sha(ROOT/p)!=h)}
identity={'branch':git('branch','--show-current').strip(),'head':git('rev-parse','HEAD').strip(),'current_native_sources':len(native['sources']),'changed_since_fresh_build':changed,'changed_since_qualified_build':qualified_changed,'product_source_edited_by_review':False,'max_year':2027,'computer_use':False,'host_authority':'Ephemeral unique test trust; same product source, different public-key configuration. Shipped owner-trust package was inspected, not installed or launched.'}
identity.update(final_check_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),qualification_scope='Fresh 0.87.6.3 build and recorded test payload; later concurrent workspace changes are not qualified by these passes.',fresh_vs_qualified_source_differences={p:{'fresh':h,'qualified':old['sources'][p]} for p,h in native['sources'].items() if p in old['sources'] and not p.startswith('build/') and h!=old['sources'][p]})
dump(E/'identity.json',identity);dump(E/'source-hashes.json',native['sources']);(E/'git-status-end.txt').write_text(git('status','--short','--untracked-files=all'),encoding='utf-8')
shutil.copy2(BUILD/'git-status.txt',E/'git-status-start.txt');dump(E/'initial-diff-hash.json',{'sha256':sha(BUILD/'git-diff.patch'),'path':str((BUILD/'git-diff.patch').relative_to(ROOT)),'note':'Original local diff retained in owned build directory; unrelated source changes not redistributed.'})
q=json.loads((ROOT/'docs/plans/interaction-review-08763-20261029/QUALIFICATION.json').read_text());archive=ROOT/'dist/CyrusScatter-0.87.6.3-20261029/CyrusScatter-0.87.6.3-Max2027.mzp'
with zipfile.ZipFile(archive) as z:
 manifest=json.loads(z.read('manifest.json'));assert z.testzip() is None
 assert manifest['version']=='0.87.6.3' and manifest['max_year']==2027
 assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 assert all(hashlib.sha256(z.read(p)).hexdigest()==h for p,h in manifest['files'].items())
 assert all(hashlib.sha256(z.read(p)).hexdigest()==h for p,h in q['package']['payload'].items())
 assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
 assert sha(archive)==q['package']['sha256']
 dump(E/'package-check.json',{'path':str(archive.relative_to(ROOT)),'sha256':sha(archive),'bytes':archive.stat().st_size,'archive_integrity':True,'all_manifest_hashes':True,'payload_matches_qualification':True,'host_guard_2027':True,'source_difference':qualified_changed,'installed':False,'manifest':manifest})

for src,dest in [
 ('native/receipt.json','native-receipt.json'),('native/Testing/Temporary/LastTest.log','native-tests.log'),('generated/generated-check.json','generated-check.json'),('generated/CONTROL_PORT_RESULTS.csv','historical-control-ports.csv'),('python-tests.xml','python-tests.xml'),('mcp-tests.xml','mcp-tests.xml'),('managed-r08763b/receipt.json','managed-tests.json'),('probes/regression.json','native-regression.json'),('probes/benchmark.csv','benchmark.csv'),('probes/benchmark-first.csv','benchmark-first.csv'),('supplemental/managed.log','library-probe.log'),('supplemental/permit-benchmark.log','permit-benchmark.json'),('library-host/library-host.json','library-host.json'),('host/host-regressions.json','host-regressions.json'),('host/smoke.json','selection-smoke.json'),('host/host-review.json','host-review.json'),('garden-host/garden-pick.json','garden-pick.json'),('garden-host/navigation.json','garden-navigation.json'),('garden-host/garden-drag.json','garden-drag.json'),('garden-host/garden-review.json','garden-review.json'),('render-host/render-host.json','render-host.json'),('render-host/scanline.png','scanline.png'),('knowledge-status.txt','knowledge-status.txt')]:
 if (BUILD/src).exists():shutil.copy2(BUILD/src,E/dest)
for p in (BUILD/'supplemental').glob('signed-*.log'):
 if '-compile' not in p.name:shutil.copy2(p,E/p.name)
for host in ('host','library-host','garden-host','render-host'):
 for name in ('loaded-identity.json','receipt.json'):
  if (BUILD/host/name).exists():shutil.copy2(BUILD/host/name,E/(host+'-'+name))
rows=list(csv.DictReader((E/'benchmark.csv').open()));groups={}
for row in rows:
 if int(row['iteration'])==9:continue
 groups.setdefault((row['case'],int(row['rows']),int(row['threads'])),[]).append(float(row['total_ms']))
summary=[dict(case=k[0],rows=k[1],threads=k[2],samples=len(v),median_ms=statistics.median(v),min_ms=min(v),max_ms=max(v)) for k,v in groups.items()]
dump(E/'benchmark-summary.json',summary)

# Every semantic inventory row is accounted for. Declaration/handler matching is
# source evidence, never a claim that a physical widget or all settings ran.
inv=json.loads((ROOT/'AminScatter/tools/ui/layers-control-inventory.json').read_text());help=json.loads((ROOT/'AminScatter/tools/ui/control-tooltips.json').read_text());layout=json.loads((ROOT/'AminScatter/tools/ui/approved-layout-manifest.json').read_text())
legacy={}
for line in (ROOT/'docs/plans/ui-settings-0876-20261028/CONTROL_LEDGER.md').read_text(encoding='utf-8').splitlines():
 if not line.startswith('| ['):continue
 parts=re.split(r'(?<!\\)\|',line)[1:-1];key=re.search(r'\(`([^`]+)`\)',parts[0])
 if key and len(parts)>=4:legacy[key[1]]={'meaning':parts[1].strip(),'prerequisites':parts[2].strip(),'evidence':parts[3].strip()}
templates=list((ROOT/'AminScatter/tools/ui/templates').glob('*.ms'));decls=[];handlers={};controls=r'checkbox|checkbutton|button|pickbutton|radiobuttons|spinner|dropdownlist|multiListBox|listbox|edittext|colorpicker|curvecontrol|dotNetControl|slider|mapbutton|combobox|imgTag'
for path in templates:
 rollout='module';lines=path.read_text(encoding='utf-8-sig').splitlines()
 for number,line in enumerate(lines,1):
  match=re.match(r'\s*rollout\s+(\w+)',line)
  if match:rollout=match[1]
  match=re.match(r'\s*('+controls+r')\s+(\w+)\s+(.*)',line,re.I)
  if match:decls.append(dict(kind=match[1],name=match[2],text=match[3],rollout=rollout,path=str(path.relative_to(ROOT)),line=number))
  match=re.match(r'\s*on\s+(\w+)\s+(\w+).*',line)
  if match:handlers.setdefault((str(path.relative_to(ROOT)),rollout,match[1]),[]).append((number,' '.join(lines[number-1:min(len(lines),number+4)]).strip()))
allrows=[];used=set()
for group in ('general','layer','container'):
 for section,entries in inv[group].items():
  for entry in entries:
   name=entry['name'];possible=[d for d in decls if d['name']==name];best=next((d for d in possible if d['rollout'] in (section,'flow_'+section)),possible[0] if possible else None)
   old=next((legacy[k] for k in (section+'_'+name,'flow_'+section+'_'+name,name) if k in legacy),{})
   canonical=group+'/'+section+'/'+name
   meaning=old.get('meaning',help.get(section,{}).get(name,best['text'] if best else name))
   callback=handlers.get((best['path'],best['rollout'],name),[]) if best else []
   if best:used.add((best['path'],best['line']))
   owner='Source container node' if group=='container' else 'Selected layer / selected source or Paint Area' if group=='layer' else 'Scatter controller / explicit selected layer'
   if 'Owner:' in meaning:owner=meaning.split('Owner:')[-1].strip()
   update='Authored setting follows Manual/Live dependency rules; explicit commands execute immediately. Exact handler attached; individual physical path not retested.'
   if section in ('previewUI','statisticsUI'):update='Display/inspection scope; display refresh must preserve pending Manual placement. Preview budget exercised in fresh Max.'
   persistence='Host authored parameter/reference state; saved-scene/recipe coverage varies by command. UI selection/presentation only does not imply persisted data.'
   status='source inventory + generated mapping verified; per-control runtime not rerun'
   allrows.append(dict(id=canonical,kind=entry['kind'],meaning=meaning,owner=owner,prerequisites=old.get('prerequisites','See contextual handler; not assumed enabled'),update=update,persistence=persistence,status=status,historical_evidence=old.get('evidence','No inherited control-specific witness'),historical_scope='0.87.6 ledger only; never upgraded to current runtime acceptance',source=best['path'] if best else 'AminScatter/tools/ui/layers-control-inventory.json',line=best['line'] if best else '',handler_lines=';'.join(str(x[0]) for x in callback),handler_excerpt=' | '.join(x[1] for x in callback)[:1800],limits='No Computer Use; no physical/DPI/all-combination acceptance'))
semantic_count=len(allrows)
for d in decls:
 if (d['path'],d['line']) in used:continue
 # Other template declarations include popup, advanced, shared-selection,
 # licensing, memory, recipe and preparation editor surfaces. Some are retained
 # generator inputs; presence alone does not prove active mounting.
 callback=handlers.get((d['path'],d['rollout'],d['name']),[])
 allrows.append(dict(id='aux/'+d['path'].split('/')[-1]+'/'+d['rollout']+'/'+d['name']+':'+str(d['line']),kind=d['kind'],meaning=d['text'],owner=d['rollout']+' callback owner; see excerpt',prerequisites='Conditional/popup or generator source; mounting path not individually exercised',update='See handler; no inferred authoring or persistence contract',persistence='Classify via containing controller/editor; presentation state is not authored geometry',status='declaration/handler indexed; runtime and mounting not independently qualified',historical_evidence='',historical_scope='',source=d['path'],line=d['line'],handler_lines=';'.join(str(x[0]) for x in callback),handler_excerpt=' | '.join(x[1] for x in callback)[:1800],limits='Supplemental source inventory can include retained generator inputs; not a count of visible controls'))
for line_number,line in enumerate((ROOT/'AminScatter/src/cyrus_edit.rc').read_text(encoding='utf-8',errors='replace').splitlines(),1):
 if re.match(r'\s*(CONTROL|PUSHBUTTON|DEFPUSHBUTTON|EDITTEXT|COMBOBOX|LISTBOX)',line):
  row={k:'' for k in allrows[0]};row.update(id='native-edit:'+str(line_number),kind='native dialog',meaning=line.strip(),owner='Cyrus Edit modifier',update='Host-native authored command / selection',persistence='Edit state chunks; selection/gizmo transient',status='resource declaration indexed; current selection smoke and native Edit tests cover subsets',source='AminScatter/src/cyrus_edit.rc',line=line_number,limits='No physical mouse/gizmo/DPI walkthrough');allrows.append(row)
for line_number,line in enumerate((ROOT/'AminScatter/ui/LibraryGallery.cs').read_text().splitlines(),1):
 if re.search(r'private readonly (?:ToolStrip\w*|TreeView|Label)\b',line):
  for name in re.findall(r'(\w+)\s*=\s*new',line):
   row={k:'' for k in allrows[0]};row.update(id='managed-library/'+name+':'+str(line_number),kind='managed control',meaning=line.strip(),owner='LibraryPanel / file-only catalog; Max actions delegated to script',update='UI event dispatch, asynchronous bounded catalog/thumbnail workers',persistence='Library catalog for mutations; view/search/page state only for navigation',status='source inspected; managed transaction tests cover storage, physical control not exercised',source='AminScatter/ui/LibraryGallery.cs',line=line_number,limits='Not a physical or DPI pass; see Library workflow coverage');allrows.append(row)
for row in allrows:
 source=row['source'].replace('\\','/');path=ROOT/source
 row['built_source_sha256']=native['sources'].get(source,'')
 row['inventory_source_sha256']=sha(path) if path.is_file() else ''
 row['identity_status']='concurrent change: final inventory source differs from tested snapshot; no inherited runtime qualification' if source in changed else 'source matches tested snapshot' if source in native['sources'] else 'supplemental inventory source; not an input in the native build receipt'
 if source in changed:row['status']+='; FINAL INVENTORY ONLY: source changed concurrently after tested snapshot'
with (REPORT/'coverage.csv').open('w',encoding='utf-8-sig',newline='') as f:
 writer=csv.DictWriter(f,fieldnames=list(allrows[0]));writer.writeheader();writer.writerows(allrows)
dump(E/'coverage-summary.json',{'semantic_controls':semantic_count,'supplemental_rows':len(allrows)-semantic_count,'total_rows':len(allrows),'semantic_declaration_matches':sum(r['source']!='AminScatter/tools/ui/layers-control-inventory.json' for r in allrows[:semantic_count]),'inherited_ledger_descriptions':sum(r['historical_evidence']!='No inherited control-specific witness' for r in allrows[:semantic_count]),'not_an_all_controls_runtime_pass':True})
print(json.dumps({'branch':identity['branch'],'head':identity['head'],'fresh_source_count':len(native['sources']),'concurrently_changed_files':list(changed),'fresh_vs_qualified_source_differences':identity['fresh_vs_qualified_source_differences'],'coverage_rows':len(allrows),'package_verified':True},indent=2))
