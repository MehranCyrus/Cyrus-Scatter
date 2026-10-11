"""Finish the append-only inspection scene, then verify it in a separate request.

Run prepare first, then verify; do not rerun prepare after it creates case 25.
No production settings/code or normal Max profile are changed.
"""
from pathlib import Path
import json, textwrap, traceback
HERE=Path(__file__).resolve().parent
exec((HERE/'area_examples_extra.py').read_text().split('try:\n    c=get_case(17)')[0],globals())
phase=str(rt.QA_AreaPhase)
try:
    if phase=='prepare':
        if len(cases)!=24:raise RuntimeError('Prepare requires the completed 24-case scene')
        # Complete the original linear ramp with five samples: ensureFallCurves
        # fills arrays shorter than five, so a two-value fixture was not linear.
        c=get_case(24);c['leaf'].fallScaleCurve=arr([.25,.4375,.625,.8125,1])
        actual=update(c);cx,cy=c['center']
        d=lambda row:1.5-max(abs(row['xy'][0]-cx),abs(row['xy'][1]-cy))
        check(all(abs(row['scale']-(.25+.75*min(1,max(0,(d(row)-.15)/.3))))<2e-4 for row in actual),'Corrected five-sample Analyzer scale ramp matches boundary distances')
        # Add the complementary outward falloff case for direct artist inspection.
        c=new('Exclude - outward delete and scale')
        g=rect(c,'Exclude',w=1.3,h=1.3);area(c,g,2);baseline=verify(c)
        c['leaf'].setFallConfig(g[0],arr([True,.1*M,True,.3*M,arr([.2,1]),False,.3*M,arr([0,1])]))
        c['leaf'].setSourceRadius(rt.execute('#{1}'),.035*M)
        c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=2)
        c['leaf'].setSourceRadius(rt.execute('#{1}'),True,kind=3)
        actual=update(c)
        check({r['id'] for r in actual}=={r['id'] for r in baseline if distance(r['xy'],g[1])>=.1},'Exclude falloff deletes exactly 100 mm outside its border')
        check(all(abs(row['scale']-(.2+.8*min(1,max(0,(distance(row['xy'],g[1])-.1)/.3))))<2e-4 for row in actual),'Exclude scale ramp follows the outward world-distance curve')
        # A completed fresh Analyze, after all queued scene construction events,
        # distinguishes an invalid saved publication from a reopen invalidation.
        rt.QA_Pump(500)
        c=get_case(22);a=c['leaf'].areaAnalyzer;a.runAnalysis();update(c)
        rt.QA_Pump(500)
        check(bool(a.analysisCurrent()),'Street Analyzer is current after explicit Analyze and message drain')
        # Keep captions inside each cell; no layout or placement edits.
        for item in cases:
            label=rt.getNodeByName('CSQA_Label_'+str(item['number']))
            label.size=.075*M;label.text=f"{item['number']:02d}  "+'\n'.join(textwrap.wrap(item['title'],32))
        rt.viewport.setType(rt.Name('view_top'))
        rt.select(arr([n for n in rt.shapes if str(n.name).startswith('CSQA_')]))
        mx('max zoomext sel all');rt.clearSelection();rt.CyrusPointSync();rt.redrawViews()
        bmp=rt.gw.getViewportDib();bmp.filename=str(OUT/'Area_Examples_Overview.png');rt.save(bmp);rt.close(bmp)
        focus=get_case(14);receiver=rt.getNodeByName('CSQA_Receiver_14')
        receiver.isHidden=False
        rt.select(arr([receiver,rt.getNodeByName('CSQA_Label_14')]))
        mx('max zoomext sel all');receiver.isHidden=True
        rt.QA_Activate(focus['obj']);focus['root'].mainUI.mountTimer.tick()
        focus['root'].areasUI.open=True;focus['root'].layoutUI.open=True
        rt.CyrusPointSync();rt.redrawViews()
        bmp=rt.gw.getViewportDib();bmp.filename=str(OUT/'Area_Example_14_Closeup.png');rt.save(bmp);rt.close(bmp)
        snapshots={}
        for item in cases:
            c=get_case(item['number']);r=c['root'];r.refreshAll()
            item['count']=len(r.groupSnapshotRows[0])
            snapshots[item['node_name']]=dict(fingerprint=str(rt.cyrusEditFingerprint(r.groupSnapshotRows[0],'areas')),error=str(c['leaf'].previewError))
        (OUT/'final-before-save.json').write_text(json.dumps(snapshots,indent=2))
        check(all(not item['error'] for item in snapshots.values()),'All 25 cases have a complete error-free result before final save')
        rt.saveMaxFile(str(OUT/'Include_Exclude_Point_Examples.max'),quiet=True)
    elif phase=='verify':
        before=json.loads((OUT/'final-before-save.json').read_text())
        rt.loadMaxFile(str(OUT/'Include_Exclude_Point_Examples.max'),quiet=True)
        rt.QA_Pump(750)
        after={}
        for item in cases:
            c=get_case(item['number']);r=c['root'];r.refreshAll()
            error=str(c['leaf'].previewError)
            fp=str(rt.cyrusEditFingerprint(r.groupSnapshotRows[0],'areas')) if len(r.groupSnapshotRows) else ''
            ok=not error and fp==before[item['node_name']]['fingerprint']
            after[item['node_name']]=dict(passed=ok,error=error,fingerprint=fp)
            check(ok,item['title']+': final separate-request save/reopen')
        (OUT/'final-after-reopen.json').write_text(json.dumps(after,indent=2))
        # Preserve any failure in receipts, while leaving a usable scene open.
        if not after[cases[21]['node_name']]['passed']:
            c=get_case(22);c['leaf'].areaAnalyzer.runAnalysis();update(c)
            check(str(rt.cyrusEditFingerprint(c['root'].groupSnapshotRows[0],'areas'))==before[c['node_name']]['fingerprint'],'Street Analyzer explicit Analyze restores the same saved point result')
        focus=get_case(14);rt.QA_Activate(focus['obj']);focus['root'].mainUI.mountTimer.tick()
        focus['root'].areasUI.open=True;focus['root'].layoutUI.open=True
        rt.CyrusPointSync();rt.redrawViews()
        rt.saveMaxFile(str(OUT/'Include_Exclude_Point_Examples.max'),quiet=True)
    else:raise RuntimeError('Unknown finalize phase')
    write_results()
except Exception:
    (OUT/('area-examples-'+phase+'-error.txt')).write_text(traceback.format_exc());raise
finally:rt.execute('CyrusInteractionHeld=QA_PreviousHeld')
