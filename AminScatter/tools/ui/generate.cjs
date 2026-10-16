// The sole supported product model is maintained in unified-core.ms.
// Container views bind those same owners; generation adds no engine.
const fs=require('fs');
const crypto=require('crypto');
let text=fs.readFileSync('tools/ui/templates/unified-core.ms','utf8').replace(/\r/g,'');
text=require('./licensing.cjs')(text);
const check=process.argv.includes('--check');
// Keep semantic MCP identities independent of the approved presentation.
require('./inventory.cjs')(text+'\n'+fs.readFileSync('tools/ui/templates/container-properties-ui.ms','utf8').replace(/\r/g,''),{check});
text=require('./approved-layout.cjs')(text,{check});
text=require('./container-system.cjs')(text);
text=fs.readFileSync('tools/ui/templates/presets.ms','utf8').replace(/\r/g,'')+'\n'+text;
text=fs.readFileSync('tools/ui/templates/recipes.ms','utf8').replace(/\r/g,'')+'\n'+text;
text=fs.readFileSync('tools/ui/templates/assets.ms','utf8').replace(/\r/g,'')+'\n'+text;
text=fs.readFileSync('tools/ui/templates/licensing.ms','utf8').replace(/\r/g,'')+'\n'+text;
text=text.replace(/\r\n/g,'\n').replace(/^[ \t]+$/gm,'');
const hash=crypto.createHash('sha256').update(text,'utf8').digest('hex');
// Explicit UTF-8 prevents localized Windows code pages from corrupting glyphs.
const source='\uFEFFglobal CyrusLoadedScriptFingerprint="'+hash+'"\n'+text;
if(check){
 if(fs.readFileSync('scripts/AminScatterObject.ms','utf8')!==source)throw new Error('Generated MAXScript is stale');
}else fs.writeFileSync('scripts/AminScatterObject.ms',source);
