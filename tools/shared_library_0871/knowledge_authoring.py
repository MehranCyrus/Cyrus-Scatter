"""Draft current source/locator successors for explicit agent review, never activate."""
from pathlib import Path
import json,hashlib,difflib,copy,re,argparse
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'_local/rag/indexes/20261022-knowledge-08684-06-candidate-01'
def load(p):return json.loads(p.read_text(encoding='utf8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True);a=parser.parse_args();out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=False)
    corpus=load(ROOT/'tools/rag/corpus-v31.json');sources={s['path']:s for s in corpus['sources']};old={};ends={}
    for line in (BASE/'chunks.jsonl').read_text(encoding='utf8').splitlines():
        c=json.loads(line);contract=c.get('contract',c);loc=contract['locator'];path=c['path'];rows=old.setdefault(path,{})
        for i,text in enumerate(contract['original_text'].splitlines(),loc['start_line']):
            if i in rows:assert rows[i]==text,(path,i)
            rows[i]=text
        ends[path]=max(ends.get(path,0),loc['end_line'])
    current={p:(ROOT/p).read_text(encoding='utf8').splitlines() for p in sources};manual=[]
    def interval(path,start,end,kind):
        prior=[old[path].get(i,'') for i in range(start,end+1)];now=current[path]
        if path=='AminScatter/tools/ui/templates/unified-core.ms' and [start,end]==[3266,3364]:
            # Explicitly inspected source-aware radii/binding successor. The
            # changed function declaration cannot be relocated by exact text.
            first=next(i for i,line in enumerate(now) if 'fn procRadii rows plants geometry:' in line)
            last=next(i for i in range(first,len(now)) if now[i:i+3]==prior[-3:])
            return [first+1,last+3]
        hits=[i for i in range(len(now)-len(prior)+1) if now[i:i+len(prior)]==prior]
        if len(hits)==1:return [hits[0]+1,hits[0]+len(prior)]
        # A draft only. Every changed/ambiguous passage is emitted for semantic
        # inspection, including both complete texts and current surrounding lines.
        known_start=min(old[path]);before=[old[path].get(i,'') for i in range(known_start,max(old[path])+1)]
        matcher=difflib.SequenceMatcher(None,before,now,autojunk=False)
        def boundary(pos,right=False):
            pos-=known_start
            for tag,i,j,x,y in matcher.get_opcodes():
                if i<=pos<j:return x+(pos-i) if tag=='equal' else (y-1 if right else x)
            return len(now)-1
        left=max(0,boundary(start));right=max(left,boundary(end,True));right=min(right,len(now)-1)
        result=[left+1,right+1];manual.append(dict(path=path,kind=kind,old=[start,end],proposed=result,prior='\n'.join(prior),current='\n'.join(now[left:right+1]),context='\n'.join(now[max(0,left-3):min(len(now),right+4)])))
        return result
    for source in corpus['sources']:
        path=source['path'];digest=sha(ROOT/path)
        if digest==source['sha256']:continue
        prior=copy.deepcopy(source);full=len(source['ranges'])==1 and source['ranges'][0]==[1,ends[path]]
        source['sha256']=digest;source['ranges']=[[1,len(current[path])]] if full else [interval(path,x,y,'source range') for x,y in source['ranges']]
        if path.endswith('.md') and full:
            heads=[i+1 for i,line in enumerate(current[path]) if re.match(r'^#{1,4} ',line)]
            heads=sorted(set([1,*heads]));source['contract_sections']=[[x,y-1] for x,y in zip(heads,heads[1:]+[len(current[path])+1]) if x<y]
        elif 'contract_sections' in source:source['contract_sections']=[interval(path,x,y,'source contract') for x,y in source['contract_sections']]
        source['review_status']='26 October 2026 source/section review; agent review only, human semantic review not performed.'
        source['applicability']={**source.get('applicability',{}),'previous_snapshot':source.get('applicability',{}).get('snapshot'),'snapshot':'Current enrolled source bytes at the 0.87.1 library delivery; independent products and dated qualification retain their own stated scope.'}
        save(out/(str(list(sources).index(path))+'.source-diff.json'),dict(before=prior,after=source))
    baseline=load(ROOT/'_local/rag/candidates/20261022-knowledge-08684-06/receipt.json');definitions=baseline['input_inventory']['evaluations'] if 'input_inventory' in baseline else None
    definitions=['evaluation-original-v25.json','evaluation-revised-v25.json','challenge-v24.json','evaluation-foundation-v19.json','evaluation-native-foundation-v14.json','evaluation-navigation-v11.json','evaluation-workflows-v10.json']
    def rebind(value):
        if isinstance(value,dict):
            if {'path','sha256','start_line','end_line'}<=value.keys() and value['path'] in sources:
                path=value['path'];value['start_line'],value['end_line']=interval(path,value['start_line'],value['end_line'],'evaluation evidence');value['sha256']=sources[path]['sha256']
            else:
                for child in value.values():rebind(child)
        elif isinstance(value,list):
            for child in value:rebind(child)
    for name in definitions:
        labels=load(ROOT/'tools/rag'/name);rebind(labels);save(out/name,labels)
    # Authority evidence is metadata, not executable instructions; retain its
    # historical decisions while relocating citations to the reviewed source.
    rebind(corpus['authority_decisions']);save(out/'corpus.json',corpus);save(out/'manual-locators.json',manual)
    print(json.dumps(dict(output=str(out),manual_passages=len(manual),changed_sources=sum(sha(ROOT/p)!=s['sha256'] for p,s in sources.items()))))
if __name__=='__main__':main()
