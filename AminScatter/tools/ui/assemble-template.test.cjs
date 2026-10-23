const assert=require('assert'),fs=require('fs');
const assemble=require('./assemble-template.cjs');
assert.strictEqual(assemble.expand('a\n-- @include section.ms\nb\n',name=>name==='section.ms'?'x\n':null),'a\nx\nb\n');
assert.throws(()=>assemble.expand('-- @include section.ms\n-- @include section.ms\n',()=>''),/Duplicate/);
assert.throws(()=>assemble.expand('-- @include ../bad.ms\n',()=>''),/Malformed/);
assert.throws(()=>assemble('tools/ui/templates/absent.ms'),/ENOENT/);
assert.throws(()=>assemble('../outside.ms'),/Invalid/);
if(process.argv[2]){
 const folder=process.argv[2];
 const before=fs.readFileSync(folder+'/pre-extraction-core.ms','utf8');
 const extracted=fs.readFileSync(folder+'/extracted-core-snapshot.ms','utf8');
 const expanded=assemble.expand(extracted,name=>fs.readFileSync('tools/ui/templates/'+name,'utf8').replace(/\r/g,''));
 assert.strictEqual(expanded,before,'Structural extraction changed runtime text');
}
console.log('PASS: deterministic assembly, include failures and requested byte-parity baseline');
