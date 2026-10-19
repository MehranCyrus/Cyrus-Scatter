"""Composed rollout names must survive comments without renaming properties/literals."""
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[2]

def test_rollout_names_ignore_comment_punctuation_and_preserve_maxscript_atoms():
    program=r'''
const fs=require('fs'),vm=require('vm'),path=require('path');
const file=path.resolve('AminScatter/tools/ui/approved-layout.cjs');
const context={require:require('module').createRequire(file),module:{exports:{}}};
vm.runInNewContext(fs.readFileSync(file,'utf8')+'\nmodule.exports.testRename=rename;',context);
const names=new Map([['imagethumbnail','distributionUI_imageThumbnail'],['owner','distributionUI_owner'],['bitmap','SHOULD_NOT_RENAME_PROPERTY']]);
const input=[
 '-- A sentence ends here.\nimageThumbnail.bitmap=owner.densityMap',
 'owner. /* another sentence. */ bitmap',
 '#imageThumbnail "imageThumbnail" -- imageThumbnail.\nimageThumbnail.bitmap=undefined',
 'call imageThumbnail:owner'
];
process.stdout.write(JSON.stringify(input.map(s=>context.module.exports.testRename(s,names))));
'''
    result=subprocess.run(['node','-e',program],cwd=ROOT,text=True,capture_output=True,check=True)
    assert json.loads(result.stdout)==[
        '-- A sentence ends here.\ndistributionUI_imageThumbnail.bitmap=distributionUI_owner.densityMap',
        'distributionUI_owner. /* another sentence. */ bitmap',
        '#imageThumbnail "imageThumbnail" -- imageThumbnail.\ndistributionUI_imageThumbnail.bitmap=undefined',
        'call imageThumbnail:distributionUI_owner',
    ]
