"""Independent numerical oracle for bounded point sampling and unshown row validation."""
from pathlib import Path
import json,traceback
from pymxs import runtime as r
OUT=Path(str(r.MCPFixtureDir)).resolve();assert OUT.name.startswith('foundation-terrace0815-candidate')
data={'checks':[],'status':'started'}
def check(ok,label):
    data['checks'].append({'passed':bool(ok),'label':label})
    if not ok:raise AssertionError(label)
try:
    r.execute('''global TerracePreviewRows=for i=1 to 150003 collect #((matrix3 [2,0,0] [0,3,0] [0,0,4] [i*.25,-i*.5,i*.125]),(mod i 2)+1,(i as integer64),1,[1,0,0],(mod i 3)+101,false,2)
global TerracePreviewSamples=#(#([1,2,3],[-2,1,4],[0,0,0]),#([3,2,1],[4,1,-2],[0,0,0]))
global TerracePreviewPalette=#(1,3,#([11,22,33],[44,55,66]),#(#(101,[120,10,20]),#(102,[10,130,30]),#(103,[20,30,140])),true)''')
    budget=5003;cache=r.aminScatterBuildPreview(r.TerracePreviewRows,r.TerracePreviewSamples,r.TerracePreviewPalette,budget)
    actual=list(r.aminScatterPreviewPoints(cache));expected=[[],[]];total=150003*3;samples=[[(1,2,3),(-2,1,4),(0,0,0)],[(3,2,1),(4,1,-2),(0,0,0)]]
    colors=[(120,10,20),(10,130,30),(20,30,140)]
    for k in range(budget):
        flat=k*total//budget;plant=flat//3+1;source=plant%2;sample=samples[source][flat%3]
        expected[source].append(((sample[0]*2+plant*.25,sample[1]*3-plant*.5,sample[2]*4+plant*.125),colors[plant%3]))
    expected=expected[0]+expected[1]
    error=max(abs(float(row[0][axis])-point[axis]) for row,(point,color) in zip(actual,expected) for axis in range(3))
    color_error=max(abs(float(getattr(row[1],channel))-color[axis]) for row,(point,color) in zip(actual,expected) for axis,channel in enumerate(('r','g','b')))
    data['position_error']=error;data['color_error']=color_error
    data['sample']={'position':str(actual[0][0]),'color':str(actual[0][1]),'expected':expected[0]}
    check(len(actual)==budget and error<1e-4 and color_error<1e-3,'150003 transformed placements match independent sample positions and Band colors')
    # The last row is outside the sparse displayed sample. It must still validate.
    r.execute('TerracePreviewRows[TerracePreviewRows.count][2]=99')
    rejected=False
    try:r.aminScatterBuildPreview(r.TerracePreviewRows,r.TerracePreviewSamples,r.TerracePreviewPalette,budget)
    except Exception as error:rejected='source index' in str(error).lower()
    check(rejected,'Invalid source in an unshown final row is rejected')
    r.execute('TerracePreviewRows[TerracePreviewRows.count][2]=2;TerracePreviewRows[TerracePreviewRows.count][6]=999')
    rejected=False
    try:r.aminScatterBuildPreview(r.TerracePreviewRows,r.TerracePreviewSamples,r.TerracePreviewPalette,budget)
    except Exception as error:rejected='owner is missing' in str(error).lower()
    check(rejected,'Invalid Band owner in an unshown final row is rejected')
    check(int(r.aminScatterPreviewCount(cache))==budget,'Rejected successor preserves the existing immutable point cache')
    data['status']='complete'
except Exception:data['status']='failed';data['error']=traceback.format_exc()
finally:(OUT/'preview-oracle.json').write_text(json.dumps(data,indent=2)+'\n')
if data['status']!='complete':raise RuntimeError(data['error'])
