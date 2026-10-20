import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS, EXTMeshoptCompression } from '@gltf-transform/extensions';
import { MeshoptEncoder } from 'meshoptimizer';
import { weld } from '@gltf-transform/functions';
import { demoGLB } from '../../src/assets/demo';
export async function meshoptFixture() {
  await MeshoptEncoder.ready;
  const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({ 'meshopt.encoder': MeshoptEncoder });
  const doc = await io.readBinary(demoGLB(24));
  await doc.transform(weld());
  const original = await io.writeBinary(doc);
  doc.createExtension(EXTMeshoptCompression).setRequired(true).setEncoderOptions({ method: EXTMeshoptCompression.EncoderMethod.QUANTIZE });
  return { original, compressed: await io.writeBinary(doc) };
}
