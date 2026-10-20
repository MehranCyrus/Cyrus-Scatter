import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dedup, prune, quantize, textureCompress, weld } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';
import sharp from 'sharp';
import { createHash } from 'node:crypto';
import { readFile, writeFile, access } from 'node:fs/promises';
import { resolve } from 'node:path';

const args = process.argv.slice(2), input = args[0], output = args[1], profile = args.includes('--mobile') ? 'mobile' : 'balanced';
if (!input || !output) { console.error('Usage: npm run prepare:asset -- input.glb output.glb [--mobile] [--force]'); process.exit(1); }
const sourcePath = resolve(input), outputPath = resolve(output);
if (sourcePath === outputPath) throw new Error('Preserve the original: output must be a different path');
if (!args.includes('--force')) { let exists = false; try { await access(outputPath); exists = true; } catch {} if (exists) throw new Error('Output already exists; choose a fresh path or pass --force'); }
const bytes = await readFile(sourcePath); await MeshoptDecoder.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.decoder': MeshoptDecoder });
const doc = await io.readBinary(bytes);
if (doc.getRoot().listAnimations().length || doc.getRoot().listSkins().length) throw new Error('Export a static scene before preparing');
// Keep node IDs, root transforms, layers and instance counts. No density reduction or geometry simplification.
await doc.transform(dedup({ propertyTypes: ['Mesh', 'Material', 'Texture', 'Accessor'] }), weld(), prune({ keepLeaves: true }), textureCompress({ encoder: sharp, targetFormat: 'webp', resize: profile === 'mobile' ? [1024, 1024] : [2048, 2048] }), quantize());
const prepared = await io.writeBinary(doc); await writeFile(outputPath, prepared);
const hash = data => createHash('sha256').update(data).digest('hex');
const receipt = { tool: 'Cyrus asset preparation 0.1.0', profile, sourceSha256: hash(bytes), outputSha256: hash(prepared), sourceBytes: bytes.length, outputBytes: prepared.length, operations: ['dedup-resources', 'weld', 'prune-unused-resources', 'webp-resize', 'quantize'], versions: { gltfTransform: '4.5.1', meshoptimizer: '1.3.0', sharp: '0.35.5' }, nodeCount: doc.getRoot().listNodes().length, assetOriginalPreserved: true };
await writeFile(`${outputPath}.receipt.json`, JSON.stringify(receipt, null, 2)); console.log(JSON.stringify(receipt, null, 2));
