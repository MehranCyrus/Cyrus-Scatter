// Owned building experiment; source GLB and Max scenes are never overwritten.
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dedup, weld, weldPrimitive, prune, quantize, textureCompress, simplifyPrimitive } from '@gltf-transform/functions';
import { MeshoptSimplifier } from 'meshoptimizer';
import { BufferGeometry, BufferAttribute } from 'three';
import { toCreasedNormals } from 'three/addons/utils/BufferGeometryUtils.js';
import sharp from 'sharp';
import { readFile, writeFile, rename, access } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve } from 'node:path';

const folder = resolve('exports/building-20261016');
const nativeVersion=process.argv.includes('--native-v3')?'v3':process.argv.includes('--native-v2')?'v2':'v1';
const generation=nativeVersion==='v3'?'v5':nativeVersion==='v2'?'v4':'v3';
const source = await readFile(`${folder}/prepared-pbr-native-${nativeVersion}.glb`);
const metadata = JSON.parse(await readFile(`${folder}/export-node-map-${nativeVersion==='v3'?'v5':nativeVersion==='v2'?'v4':'v2'}.json`, 'utf8'));
const mapping = new Map(metadata.map(n => [n.exportName, n]));
const protectedLayers = new Set(['300-Walls', '100-Win', '200-Glass']);
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
const results = [];
const triangleCount = mesh => mesh.listPrimitives().reduce((sum, p) => sum + (p.getIndices()?.getCount() ?? p.getAttribute('POSITION').getCount()) / 3, 0);
const definitions=[{name:'quantized', error:0}, {name:'selective-e0001', error:.0001}, {name:'selective-e0003', error:.0003}, {name:'grille-smooth-e0001', error:.0001, smoothGrilles:true}, {name:'support-creases-e0001', error:.0001, creaseSupport:true}, {name:'support-creases-e0003', error:.0003, creaseSupport:true}, {name:'support-creases-e0003-context', error:.0003, creaseSupport:true,contextRatio:.3}];
const requested=process.argv.slice(2).filter(v=>!v.startsWith('--'));
for (const variant of definitions.filter(v=>!requested.length || requested.includes(v.name))) {
    const output = `${folder}/building-${variant.name}-${generation}.glb`;
    let exists = false; try { await access(output); exists = true; } catch {}
    if (exists) throw new Error(`Choose a fresh output: ${output}`);
    const started = performance.now(), doc = await io.readBinary(source), root = doc.getRoot();
    if (root.listAnimations().length || root.listSkins().length) throw new Error('Static building expected.');
    const meshLayers = new Map();
    let identified = 0; const used = new Set(), identityBindings = [];
    for (const node of root.listNodes()) {
        const prototype = mapping.get(node.getName());
        let original;
        if (prototype) {
            const actual = node.getWorldMatrix();
            const candidates=metadata.filter(n=>n.instanceOwner===prototype.instanceOwner && !used.has(n.handle) && n.objectMatrix.every((value,i)=>Math.abs(value-actual[i])<(i>=12 && i<15 ? .001 : .00001)));
            if (candidates.length!==1) throw new Error(`Instance binding ambiguous for ${node.getName()}: ${candidates.map(n=>n.handle)}; actual=${actual}`);
            original=candidates[0];used.add(original.handle);
            identityBindings.push({handle:original.handle,prototypeHandle:prototype.handle,worldMatrix:actual});
        }
        if (original) {
            node.setName(original.name).setExtras({...node.getExtras(), cyrus: {entityId:`max-node:${original.handle}`, layerId:original.layer}});
            identified++;
            if (node.getMesh()) {
                const set = meshLayers.get(node.getMesh()) ?? new Set();
                set.add(original.layer); meshLayers.set(node.getMesh(),set);
            }
        }
        if (node.getMesh() && !original) throw new Error(`Renderable node lacks source identity: ${node.getName()}`);
    }
    // Native Max emits one root wrapper per object. Group them by source layer
    // with identity transforms, so import creates useful layers within its limit.
    for (const scene of root.listScenes()) {
        const groups = new Map();
        for (const child of scene.listChildren()) {
            const layers = new Set(); child.traverse(n => { for (const layer of meshLayers.get(n.getMesh()) ?? []) layers.add(layer); });
            if (layers.size !== 1) throw new Error(`Root has ambiguous source layer: ${child.getName()} (${[...layers]})`);
            const layer = [...layers][0];
            let group = groups.get(layer);
            if (!group) { group=doc.createNode(layer).setExtras({cyrus:{entityId:`max-layer:${layer}`,layerId:layer}});groups.set(layer,group);scene.addChild(group); }
            scene.removeChild(child);group.addChild(child);
        }
    }
    const images = [];
    for (const texture of root.listTextures()) {
        const image = texture.getImage(), info = await sharp(image).metadata(), stats = await sharp(image).stats();
        images.push({name:texture.getName(),width:info.width,height:info.height,channels:info.channels,means:stats.channels.map(c=>c.mean)});
    }
    await doc.transform(weld());
    const reductions = [];
    if (variant.error) for (const mesh of root.listMeshes()) {
        const layers = [...(meshLayers.get(mesh) ?? [])];
        if (!layers.length || layers.some(layer => protectedLayers.has(layer))) continue;
        const before = triangleCount(mesh);
        for (const primitive of mesh.listPrimitives()) {
            const crease = variant.creaseSupport && layers.every(layer=>['Fance-Peoxy','500-Fance','600-objects'].includes(layer));
            const smooth = crease || variant.smoothGrilles && layers.every(layer=>layer==='Fance-Peoxy');
            if (smooth) { primitive.setAttribute('NORMAL',null);weldPrimitive(primitive); }
            simplifyPrimitive(primitive, {simplifier:MeshoptSimplifier,ratio:crease?.3:(variant.contextRatio??.5),error:variant.error,lockBorder:true});
            if (smooth) {
                const position=primitive.getAttribute('POSITION'),geometry=new BufferGeometry();
                geometry.setAttribute('position',new BufferAttribute(position.getArray(),3));geometry.setIndex(new BufferAttribute(primitive.getIndices().getArray(),1));geometry.computeVertexNormals();
                if (crease) {
                    for (const semantic of primitive.listSemantics().filter(s=>s!=='POSITION' && s!=='NORMAL')) { const a=primitive.getAttribute(semantic);geometry.setAttribute(semantic,new BufferAttribute(a.getArray(),a.getElementSize())); }
                    const creased=toCreasedNormals(geometry,Math.PI/4);
                    for (const [name,a] of Object.entries(creased.attributes)) {
                        const semantic=name==='position'?'POSITION':name==='normal'?'NORMAL':name;
                        const original=primitive.getAttribute(semantic);
                        primitive.setAttribute(semantic,doc.createAccessor().setType(original?.getType()??'VEC3').setArray(a.array).setBuffer(position.getBuffer()));
                    }
                    primitive.setIndices(null);weldPrimitive(primitive);creased.dispose();
                } else primitive.setAttribute('NORMAL',doc.createAccessor().setType('VEC3').setArray(geometry.getAttribute('normal').array).setBuffer(position.getBuffer()));
                geometry.dispose();
            }
        }
        reductions.push({name:mesh.getName(),layers,before,after:triangleCount(mesh)});
    }
    await doc.transform(dedup({propertyTypes:['Mesh','Material','Texture','Accessor']}), prune({keepLeaves:true}), textureCompress({encoder:sharp,targetFormat:'webp',resize:[2048,2048],quality:92}), quantize({quantizePosition:16,quantizeNormal:12,quantizeTexcoord:16}), weld(), dedup({propertyTypes:['Accessor']}), prune({keepLeaves:true}));
    const bytes = await io.writeBinary(doc);
    await writeFile(`${output}.partial`, bytes); await rename(`${output}.partial`,output);
    const receipt = {
        variant:variant.name,output,sourceSha256:digest(source),outputSha256:digest(bytes),sourceBytes:source.length,outputBytes:bytes.length,
        elapsedMs:performance.now()-started,identifiedNodes:identified,nodeCount:root.listNodes().length,
        uniqueTriangles:root.listMeshes().reduce((n,m)=>n+triangleCount(m),0),
        submittedTriangles:root.listNodes().reduce((n,node)=>n+(node.getMesh()?triangleCount(node.getMesh()):0),0),
        materials:root.listMaterials().length,textures:root.listTextures().length,
        protectedLayers:[...protectedLayers],ratio:variant.error?.5:null,relativeError:variant.error,
        operations:['source-node-identity-and-layer-extras','identity-layer-groups','weld',...(variant.error?['selective-meshopt-simplification']:[]),...(variant.smoothGrilles?['explicit-grille-normal-reconstruction']:[]),...(variant.creaseSupport?['explicit-support-layer-normal-reconstruction-45deg']:[]),'dedup-resources','prune-unused','webp-2048','quantize-position16-normal12-uv16','weld-after-quantization'],
        reductions,sourceImages:images,identityBindings,
    };
    await writeFile(`${output}.receipt.json`,JSON.stringify(receipt,null,2)+'\n');results.push(receipt);
    console.log(JSON.stringify({variant:receipt.variant,bytes:receipt.outputBytes,submittedTriangles:receipt.submittedTriangles,elapsedMs:receipt.elapsedMs}));
}
await writeFile(`${folder}/post-variants-${generation}${requested.length?'-'+requested.join('-'):''}.json`,JSON.stringify(results,null,2)+'\n');
