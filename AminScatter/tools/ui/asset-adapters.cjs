// Build-owned schema shared by native validation and bounded host adapters.
// Package data cannot add a class, constructor or permitted property.
const fs=require('fs');
const assert=require('assert');
module.exports=function({check=false}={}) {
  const schema=JSON.parse(fs.readFileSync('config/asset-adapters.json','utf8'));
  const known=new Set(['corona-physical-v1','corona-legacy-v1','corona-normal-v1','multi-sub-v1','max-color-correction-v1','max-vertex-color-v1','corona-front-back-v1','max-mix-v1','corona-color-v1','corona-mix-v1','corona-color-correct-v1','max-composite-v1','forest-color-v1','forest-edge-v1','corona-bitmap-v1','max-gradient-v1']);
  const seen=new Set();
  const quoted=value=>JSON.stringify(value);
  const array=values=>'#('+values.join(',')+')';
  const cases=(name,entries)=>'fn '+name+' kind = (\n    local result=case kind of (\n'+entries.map(([kind,value])=>'        '+quoted(kind)+': '+value).join('\n')+'\n        default: undefined\n    )\n    result\n)\n';
  for(const adapter of schema.adapters) {
    assert(known.has(adapter.kind)&&!seen.has(adapter.kind),'Unknown/duplicate adapter');seen.add(adapter.kind);
    assert(['material','map'].includes(adapter.category));
    assert(adapter.classID.length===2&&adapter.classID.every(v=>Number.isInteger(v)&&v>=0&&v<=0xffffffff));
    for(const [name,field] of Object.entries(adapter.fields)) {
      assert(/^[A-Za-z][A-Za-z0-9_]*$/.test(name));
      assert(['number','distance','integer','boolean','color','point3','point3-distance','string','empty-array','null-array','absent-filename','boolean-array','integer-array','color-array','number-array','string-array'].includes(field.type));
      if(['number','distance','color','point3','point3-distance','number-array','color-array'].includes(field.type))assert(Number.isFinite(field.lo)&&Number.isFinite(field.hi)&&field.lo<=field.hi);
      if(field.type==='integer'||field.type==='integer-array')assert(Array.isArray(field.members)&&field.members.length>0&&field.members.every(Number.isSafeInteger));
    }
    if(adapter.arrayLinks) for(const [name,bounds]of Object.entries(adapter.arrayLinks)) {
      assert(/^[A-Za-z][A-Za-z0-9_]*$/.test(name)&&!adapter.links.includes(name)&&!Object.hasOwn(adapter.fields,name));
      assert(Number.isInteger(bounds.minCount)&&Number.isInteger(bounds.maxCount)&&bounds.minCount>=1&&bounds.maxCount<=128&&bounds.minCount<=bounds.maxCount);
    }
    for(const field of Object.values(adapter.fields))if(field.type.endsWith('-array')&&!['empty-array','null-array'].includes(field.type))assert(Number.isInteger(field.minCount)&&Number.isInteger(field.maxCount)&&field.minCount>=1&&field.maxCount<=128&&field.minCount<=field.maxCount);
    if(adapter.alignedArrays)assert(adapter.kind==='max-composite-v1'&&adapter.alignedArrays.length===8&&new Set(adapter.alignedArrays).size===8);
    assert(adapter.links.length===new Set(adapter.links).size);
    for(const name of adapter.links)assert(/^[A-Za-z][A-Za-z0-9_]*$/.test(name)&&!Object.hasOwn(adapter.fields,name));
    if(Object.hasOwn(adapter,'output'))assert(['max-mix-v1','corona-bitmap-v1','max-gradient-v1'].includes(adapter.kind)&&adapter.output==='standard-output-v1');
  }
  assert(Array.isArray(schema.subobjects)&&schema.subobjects.length===3);
  const output=schema.subobjects.find(a=>a.kind==='standard-output-v1');assert(output);
  const coordinates=schema.subobjects.find(a=>a.kind==='corona-uvw-v1');assert(coordinates);
  assert.deepStrictEqual(Object.keys(coordinates.fields).sort(),['uvwChannel','enviroMapping','realWorldScale','triplanarMapping','useObjectTransform','uvwOffset','tilingU','tilingV','clippingOn','clippingMode','clippingU','clippingV','clippingWidth','clippingHeight','domeOrigin','domeRadius','domeCameraHeight','wAngle','uAngle','triplanarBlending','triplanarScale','uvwScale'].sort());
  for(const field of Object.values(coordinates.fields)) {
    assert(['number','distance','point3','point3-distance','integer','boolean'].includes(field.type));
    if(['number','distance','point3','point3-distance'].includes(field.type))assert(Number.isFinite(field.lo)&&Number.isFinite(field.hi)&&field.lo<=field.hi);
    if(field.type==='integer')assert(Array.isArray(field.members)&&field.members.length>0&&field.members.every(Number.isSafeInteger));
  }
  const ordinary=schema.subobjects.find(a=>a.kind==='ordinary-gradient-uv-v1');assert(ordinary);
  assert.deepStrictEqual(Object.keys(ordinary.fields).sort(),['realWorldScale','mappingType','mapping','mapChannel','UVW_Type','U_Mirror','V_Mirror','U_Tile','V_Tile','showMapOnBack','Noise_On','Noise_Animate','phase','U_Angle','V_Angle','Noise_Amount','Noise_Size','Noise_Levels','W_Angle','Blur_Offset','U_Offset','V_Offset','blur','U_Tiling','V_Tiling'].sort());
  for(const field of Object.values(ordinary.fields)){
    assert(['number','integer','boolean'].includes(field.type));
    if(field.type==='number')assert(Number.isFinite(field.lo)&&Number.isFinite(field.hi)&&field.lo<=field.hi);
    if(field.type==='integer')assert(Array.isArray(field.members)&&field.members.length>0&&field.members.every(Number.isSafeInteger));
    if(field.type==='boolean')assert(Array.isArray(field.members)&&field.members.length===1&&typeof field.members[0]==='boolean');
  }
  assert.deepStrictEqual(ordinary.fields.realWorldScale,{type:'boolean',members:[false]});
  for(const adapter of schema.adapters)if(adapter.coordinates)assert((adapter.kind==='corona-bitmap-v1'&&adapter.coordinates==='corona-uvw-v1')||(adapter.kind==='max-gradient-v1'&&adapter.coordinates==='ordinary-gradient-uv-v1'));
  assert.deepStrictEqual(Object.keys(output.fields).sort(),['invert','clamp','alphaFromRGB','enableColorMap','useRGBColorMap','Bump_Amount','RGB_Level','RGB_Offset','Output_Amount'].sort());
  for(const [name,field] of Object.entries(output.fields)) {
    assert(/^[A-Za-z][A-Za-z0-9_]*$/.test(name));
    assert(['boolean','number'].includes(field.type));
    if(field.type==='number')assert(Number.isFinite(field.lo)&&Number.isFinite(field.hi)&&field.lo<=field.hi);
  }
  // Adjacent bounded raw literals preserve the exact JSON bytes while staying
  // below MSVC's per-literal limit as finite adapters are added.
  const compact=JSON.stringify(schema),chunks=[];
  for(let offset=0;offset<compact.length;offset+=8000)chunks.push(compact.slice(offset,offset+8000));
  const header='// Generated by tools/ui/asset-adapters.cjs; edit config/asset-adapters.json.\n'+chunks.map(chunk=>'R"CYRUS_SHADER('+chunk+')CYRUS_SHADER"').join('\n')+'\n';
  const path='include/asset_adapter_schema.inc';
  if(check)assert.strictEqual(fs.readFileSync(path,'utf8'),header,'Generated asset schema is stale');
  else fs.writeFileSync(path,header);
  let text='-- Generated finite adapter tables; constructors are authored in asset-shaders.ms.\nglobal CyrusAssetAdapterFields,CyrusAssetAdapterLinks,CyrusAssetAdapterClassID,CyrusAssetAdapterProfile\nglobal CyrusAssetAdapterCategory,CyrusAssetAdapterKinds,CyrusAssetAdapterOutput,CyrusAssetSubobjectFields\nglobal CyrusAssetAdapterArrayLinks,CyrusAssetAdapterAlignedArrays,CyrusAssetAdapterCoordinates\n';
  text+=cases('CyrusAssetAdapterFields',schema.adapters.map(a=>[a.kind,array(Object.entries(a.fields).map(([name,v])=>array([quoted(name),quoted(v.type)])))]));
  text+=cases('CyrusAssetAdapterLinks',schema.adapters.map(a=>[a.kind,array(a.links.map(quoted))]));
  text+=cases('CyrusAssetAdapterArrayLinks',schema.adapters.map(a=>[a.kind,array(Object.keys(a.arrayLinks||{}).map(quoted))]));
  text+=cases('CyrusAssetAdapterAlignedArrays',schema.adapters.map(a=>[a.kind,array((a.alignedArrays||[]).map(quoted))]));
  text+=cases('CyrusAssetAdapterClassID',schema.adapters.map(a=>[a.kind,array(a.classID.map(v=>v+'L'))]));
  text+=cases('CyrusAssetAdapterCategory',schema.adapters.map(a=>[a.kind,quoted(a.category)]));
  text+=cases('CyrusAssetAdapterCoordinates',schema.adapters.filter(a=>a.coordinates).map(a=>[a.kind,quoted(a.coordinates)]));
  text+=cases('CyrusAssetAdapterOutput',schema.adapters.filter(a=>a.output).map(a=>[a.kind,quoted(a.output)]));
  text+=cases('CyrusAssetSubobjectFields',schema.subobjects.map(a=>[a.kind,array(Object.entries(a.fields).map(([name,v])=>array([quoted(name),quoted(v.type)])))]));
  text+='fn CyrusAssetAdapterKinds = ('+array(schema.adapters.map(a=>quoted(a.kind)))+')\n';
  text+='fn CyrusAssetAdapterProfile = (CyrusRecipeObject '+array(Object.entries(schema.profile).map(([key,value])=>array([quoted(key),typeof value==='string'?quoted(value):String(value)])))+')\n';
  return text;
};
