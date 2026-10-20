import sharp from 'sharp';
import {writeFile} from 'node:fs/promises';
const folder='exports/building-20261016/final-silhouette-v1',rows=[];
for (const view of ['establishing','street-corner','reverse','courtyard','facade-detail']) {
    const source=await sharp(`${folder}/baseline-native-${view}.png`).removeAlpha().raw().toBuffer({resolveWithObject:true});
    const target=await sharp(`${folder}/final-${view}.png`).removeAlpha().raw().toBuffer({resolveWithObject:true});
    if(source.info.width!==target.info.width||source.info.height!==target.info.height)throw Error('Unmatched viewport');
    let intersection=0,union=0,sourcePixels=0,targetPixels=0,differingPixels=0;
    for(let i=0;i<source.data.length;i+=3) {
        const a=source.data[i]<128,b=target.data[i]<128;intersection+=+(a&&b);union+=+(a||b);sourcePixels+=+a;targetPixels+=+b;differingPixels+=+(a!==b);
    }
    rows.push({view,width:source.info.width,height:source.info.height,threshold:128,intersectionOverUnion:intersection/union,sourcePixels,targetPixels,differingPixels,passed:intersection/union>=.995});
}
const report={method:'Opaque black geometry masks; identical native-baseline and candidate camera poses; source architectural layers isolated; strict pixel IoU without dilation',baseline:'baseline-native.glb',candidate:'reproduction-v4/delivery/optimized.glb',limits:['This measures projected architectural silhouette, not shading/material fidelity or world surface Hausdorff error.','The analytical baseline viewer intentionally operates outside production admission; its timing is not application baseline performance.'],rows,passed:rows.every(r=>r.passed)};
await writeFile(`${folder}/metrics.json`,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
