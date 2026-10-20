import { inspectGLB } from '../assets/glb';
self.onmessage = async event => { try { self.postMessage({ asset: await inspectGLB(event.data.bytes, event.data.name, event.data.logicalId) }); } catch (error) { self.postMessage({ error: error instanceof Error ? error.message : String(error) }); } };
