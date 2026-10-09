"""Copy closed, pinned prior analysis projects into a fresh owned backend run."""
import argparse
import json
import shutil
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
PROJECTS={
    'ChaosOwnership':('vendor-surface-paint-20261009-01','ScatterMax_Release-2027.dll','f7fdd25428e8374174501e6bb4ebd3b83e21c5ba2c33fcdc94280c022695b887'),
    'ReceivingSurfaceCore':('vendor-surface-paint-20261009-01','ScatterCore.ForScatter_Release.dll','069ababd0dbc09218928f24d5bdc860509b237f34af703581e3fd78ed5d3cf86'),
    'ForestPack943':('forest-brush-research-20261008-01','ForestPackLite.dlo','23b25adf28954a4cd6c3d7fe5f7ea90b6a6e9be480f8a422fa7ef8b99c9a325d'),
}

def main():
    p=argparse.ArgumentParser();p.add_argument('--run',type=Path,required=True);a=p.parse_args()
    run=a.run.resolve();assert run.is_relative_to(ROOT/'build') and run.is_dir()
    capture=json.loads((run/'capture.json').read_text());records=[]
    for name,(prior,binary,pinned) in PROJECTS.items():
        entry=next(x for x in capture['inputs'] if Path(x['copy']).name==binary)
        assert entry['sha256']==pinned,'Binary changed; import a new project and rediscover addresses'
        source=ROOT/'build'/prior/'projects';target=run/'projects'
        assert source.is_relative_to(ROOT/'build') and target.is_relative_to(run)
        assert (source/(name+'.gpr')).is_file() and (source/(name+'.rep')).is_dir()
        assert not (target/(name+'.gpr')).exists() and not (target/(name+'.rep')).exists()
        target.mkdir(exist_ok=True);shutil.copy2(source/(name+'.gpr'),target/(name+'.gpr'))
        shutil.copytree(source/(name+'.rep'),target/(name+'.rep'))
        records.append(dict(project=name,source=source.relative_to(ROOT).as_posix(),binary=binary,sha256=pinned))
    (run/'project-copy.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(records,indent=2))

if __name__=='__main__':main()
