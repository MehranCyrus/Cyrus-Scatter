"""Synthetic validator regressions only. Never launches Max or measures the plugin."""
import copy
import csv
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

# Two deliberate layouts only: colocated build-only frozen draft/snapshot, or
# the promoted repository tests/python test plus tools/ validator and tests/max.
HERE=Path(__file__).resolve().parent
if HERE.name=="python" and HERE.parent.name=="tests":
    PROJECT=HERE.parent.parent
    VALIDATOR=PROJECT/"tools/verify_cache_performance.py"
    HARNESS=PROJECT/"tests/max"
else:
    VALIDATOR=HERE/"verify_cache_performance.py"
    HARNESS=HERE
SPEC=importlib.util.spec_from_file_location("cache_performance_validator_under_test",VALIDATOR)
v=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(v)


def write_rows(path, records, header):
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=header)
        writer.writeheader()
        writer.writerows(records)


def synthetic(folder, reverse=False):
    folder.mkdir(parents=True, exist_ok=True)
    (folder/"result.txt").write_text("SUCCESS passes=999 failures=0\nSYNTHETIC_VALIDATOR_TEST_ONLY\n")
    (folder/"performance-environment.txt").write_text(
        "SYNTHETIC_VALIDATOR_TEST_ONLY; not host or timing evidence\nNativeVersion=0.3.2\n"
        "OwnedPID=55224\nObservedMaxProcess=3dsmax PID=55224\nStopwatchFrequency=1000000000\n"
        f"StopwatchHighResolution=true\nReverseOrder={str(reverse).lower()}\n")
    data = {name: [] for name in ("metrics.csv", "poses.csv", "groups.csv", "regions.csv", "preview-bounds.csv",
                                 "warnings.csv", "sources.csv", "assets.csv", "cache-commands.csv", "cache-phases.csv", "composition-stats.csv")}
    for case in v.CASES:
        for index, box in enumerate(v.expected_source_boxes(case), 1):
            data["sources.csv"].append(dict(case=case, source_index=index, **{f"{end}_{a}_mm": box[i*3+j] for i,end in enumerate(("min","max")) for j,a in enumerate("xyz")}))
        for index, size in enumerate(((20,120,100),(30,120,200),(40,120,300)), 1):
            data["assets.csv"].append(dict(case=case, asset_id=index, **{f"size_{a}_mm":size[j] for j,a in enumerate("xyz")}))
    revisions, publications, previous = {}, {}, {}
    for serial, (case, operation, phase, iteration, seed, condition, position) in enumerate(v.expected_schedule(reverse), 1):
        shelf = case == v.CASES[1]
        center = 5200 if shelf else 2600
        z = 1800 if shelf else 600
        offset = 100 if seed == 9349 else -100
        meta = dict(serial=serial, case=case, operation=operation, phase=phase, iteration=iteration, seed=seed)
        poses=[]
        for index, (width,height,delta) in enumerate(((20,100,0),(30,200,28)), 1):
            x=center+offset+delta
            handle = previous[case][index-1]["node_handle"] if operation == "Preview" else serial*10+index
            pose=dict(meta, placement_id=index, asset_id=index, region_id=1, anchor_x_mm=x, anchor_y_mm=0, anchor_z_mm=z,
                      yaw_degrees=0, scale=1, locked="false", parent_stack_id=0, node_handle=handle,
                      bounds_min_x=x-width/2,bounds_min_y=-60,bounds_min_z=z,bounds_max_x=x+width/2,bounds_max_y=60,bounds_max_z=z+height)
            pose.update({f"tm_row{r}_{a}":int(i==r-1) for r in range(1,4) for i,a in enumerate("xyz")})
            pose.update(tm_row4_x=x,tm_row4_y=0,tm_row4_z=z)
            poses.append(pose)
        data["poses.csv"].extend(poses)
        if shelf:
            data["groups.csv"].append(dict(meta,group_id=77,kind=1,region_id=1,ordered_member_ids="#(1L, 2L)",front_x=0,front_y=-1,front_z=0,gap_mm=3))
        data["regions.csv"].append(dict(serial=serial,case=case,region_id=1,role=1,bounds_min_x=center-400,bounds_min_y=-150,bounds_min_z=z,
            bounds_max_x=center+400,bounds_max_y=150,bounds_max_z=z,minimum_clearance_mm=-1,open_above="true",excluded="false"))
        if operation == "Preview":
            for index, pose in enumerate(poses, 1):
                box=dict(serial=serial,case=case,index=index,yaw_degrees=0)
                for a in "xyz":
                    box[f"center_{a}_mm"]=(pose[f"bounds_min_{a}"]+pose[f"bounds_max_{a}"])/2
                    box[f"half_{a}_mm"]=(pose[f"bounds_max_{a}"]-pose[f"bounds_min_{a}"])/2
                data["preview-bounds.csv"].append(box)
        revision=revisions.get(case,1);publication=publications.get(case,0)
        duration=2 if condition in ("warm", "preparation") else 3
        metric=dict(meta,computation="geometry_query_cache_enabled",elapsed_ms=duration,elapsed_ticks=duration*1000000,
            requested=2,accepted=2,kept=0,candidates=4,underfilled=0,warnings=0,committed_outputs=2,committed_groups=int(shelf),regions=1,
            preview_boxes=2 if operation=="Preview" else 0,prior_publications_in_case=publication,revision_before=revision,
            revision_after=revision+(operation!="Preview"),condition=condition,position=position,reverse_order=str(reverse).lower())
        metric.update({key:1000000 if "peak" not in key else 2000000 for key in v.MEMORY})
        data["metrics.csv"].append(metric)
        data["composition-stats.csv"].append(dict(meta,available="true",row_attempts=int(shelf),rows_formed=int(shelf),row_failures=0,balance_anchor_attempts=8*int(shelf),rows_moved=0))
        revisions[case]=metric["revision_after"];publications[case]=publication+(operation!="Preview")
        previous[case]=poses
        command=dict(serial=serial,enabled="true",operation=operation[0].lower()+operation[1:],disposition="hit" if condition in ("warm", "preparation") else "cold",
            reason="none" if condition in ("warm", "preparation") else "explicitClear",completed="true",published=str(operation!="Preview").lower(),lookup_validated=str(condition in ("warm", "preparation")).lower(),
            inspection_work_original=512,inspection_work_executed=0 if condition in ("warm", "preparation") else 512,
            query_build_work_original=1024,query_build_work_executed=0 if condition in ("warm", "preparation") else 1024,solver_work=4096,command_sequence=serial,
            resident=1,retired_borrowed=0,live_entries=1,live_bytes=10000,live_triangles=100,live_cells=200,
            peak_entries=1,peak_bytes=10000,peak_triangles=100,peak_cells=200,entry_metadata_live_bytes=1000,entry_metadata_peak_bytes=1000,
            fixed_service_inline_bytes=5000,fixed_control_object_bytes=100,document_instance=1+int(shelf),scene_epoch=1,geometry_epoch=1,time_ticks=0)
        data["cache-commands.csv"].append(command)
        for name in v.PHASES:
            ns=100000
            if condition in ("warm", "preparation") and name in ("furnitureCapture","inspect","obstacleCapture","queryBuild"):
                ns=0
            if operation=="Preview" and name in ("visualCapture","publish"):
                ns=0
            if name=="total":
                ns=(duration-1)*1000000
            data["cache-phases.csv"].append(dict(serial=serial,phase=name,nanoseconds=ns))
    headers={name:list(records[0]) if records else (['serial','index','warning'] if name=='warnings.csv' else []) for name,records in data.items()}
    for name,records in data.items():
        write_rows(folder/name,records,headers[name])
    return data,headers


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix="cache-validator-synthetic-")
        self.folder=Path(self.temp.name)
        self.data,self.headers=synthetic(self.folder)

    def tearDown(self):
        self.temp.cleanup()

    def altered(self, name, change):
        data=copy.deepcopy(self.data[name]);change(data)
        write_rows(self.folder/name,data,self.headers[name])
        with self.assertRaises(ValueError):
            v.verify(self.folder)

    def test_complete_synthetic_forward(self):
        result=v.verify(self.folder)
        self.assertEqual(result["paired_commands"],120)
        self.assertEqual(len(result["samples"]),6)
        self.assertEqual(result["samples"][0]["paired_delta_cold_minus_warm_ms"]["script_ms"]["median"],1)

    def test_complete_synthetic_reverse(self):
        synthetic(self.folder,reverse=True)
        self.assertTrue(v.verify(self.folder)["reverse_order"])

    def test_proven_invariant_dotnet_boolean_csv(self):
        for name, records in self.data.items():
            changed = [{key: value.title() if value in ("true", "false") else value for key,value in row.items()} for row in records]
            write_rows(self.folder/name,changed,self.headers[name])
        self.assertEqual(v.verify(self.folder)["separate_context_commands"],20)

    def test_initial_empty_output_work_not_a_repeated_solver_baseline(self):
        data=copy.deepcopy(self.data["cache-commands.csv"])
        data[0]["solver_work"]=1
        write_rows(self.folder/"cache-commands.csv",data,self.headers["cache-commands.csv"])
        self.assertEqual(v.verify(self.folder)["paired_commands"],120)

    def test_reject_unequal_per_pair_solver_work(self):
        self.altered("cache-commands.csv",lambda rs:rs[3].update(solver_work=4097))

    def test_complete_warning_text_inventory(self):
        data=copy.deepcopy(self.data['metrics.csv'])
        for row in data:
            row['warnings']=1
        write_rows(self.folder/'metrics.csv',data,self.headers['metrics.csv'])
        warnings=[dict(serial=row['serial'],index=1,warning='SYNTHETIC warning, exact text') for row in data]
        write_rows(self.folder/'warnings.csv',warnings,self.headers['warnings.csv'])
        self.assertEqual(v.verify(self.folder)['paired_commands'],120)
        warnings[-1]['warning']='Silently changed warning'
        write_rows(self.folder/'warnings.csv',warnings,self.headers['warnings.csv'])
        with self.assertRaises(ValueError):
            v.verify(self.folder)

    def test_warning_difference_after_twentieth_element_is_rejected(self):
        data=copy.deepcopy(self.data['metrics.csv'])
        for row in data:
            row['warnings']=25
        write_rows(self.folder/'metrics.csv',data,self.headers['metrics.csv'])
        warnings=[dict(serial=row['serial'],index=index,warning=f'SYNTHETIC full warning {index}')
                  for row in data for index in range(1,26)]
        write_rows(self.folder/'warnings.csv',warnings,self.headers['warnings.csv'])
        self.assertEqual(v.verify(self.folder)['paired_commands'],120)
        self.assertEqual(warnings[-1]['index'],25)
        warnings[-1]['warning']='Changed only warning25 beyond array printer truncation'
        write_rows(self.folder/'warnings.csv',warnings,self.headers['warnings.csv'])
        with self.assertRaises(ValueError):
            v.verify(self.folder)

    def test_reject_region_metadata_change(self):
        self.altered('regions.csv',lambda rs:rs[-1].update(bounds_min_x=123))

    def test_emitted_harness_avoids_array_printer_equality_and_id_export(self):
        for name in ('arrange_cache_performance_tests.ms','arrange_cache_performance_reverse_tests.ms'):
            source=(HARNESS/name).read_text()
            self.assertIn('deepEqual first[6] second[6] strictCompare:true',source)
            self.assertIn('deepEqual firstWork solverWork strictCompare:true',source)
            self.assertIn('deepEqual (caPBounds sourceNodes) sourceBounds strictCompare:true',source)
            self.assertNotIn('(first[6] as string)',source)
            self.assertNotIn('(firstWork as string)',source)
            self.assertNotIn('(sourceBounds as string)',source)
            self.assertNotIn('row[4] as string,row[5]',source)
            self.assertIn('(caPIdText row[4]),row[5]',source)
            self.assertIn('text+=(caPNumber id)',source)
            self.assertIn('warningB[25]="changed warning after element20"',source)
            self.assertIn('for index = 1 to first.count while same do',source)
            self.assertIn('for field in #(1,2,3,5,6,7,8) where row[field] != other[field]',source)
            self.assertIn('for axis = 1 to 3 where row[4][axis] != other[4][axis]',source)
            self.assertIn('deepEqual first second strictCompare:true',source)
            self.assertNotIn('local other = caPFind second row[1]',source)
            self.assertIn('#(poses,caCompositionRows setup,caCompositionStats setup)',source)
            self.assertIn('deepEqual expected[2][3] composition strictCompare:true',source)

    def test_reject_subtolerance_native_pose_drift(self):
        for field,delta in (("anchor_x_mm",.001),("yaw_degrees",.000001),("scale",.000001)):
            with self.subTest(field=field):
                self.altered("poses.csv",lambda rs:rs[-1].update({field:float(rs[-1][field])+delta}))

    def test_reject_native_placement_row_reorder(self):
        def reorder(rs):
            rs[-2],rs[-1]=rs[-1],rs[-2]
        self.altered("poses.csv",reorder)

    def test_reject_duplicate_placement_id(self):
        self.altered("poses.csv",lambda rs:rs[-1].update(placement_id=rs[-2]["placement_id"]))

    def test_complete_ordered_group_comparison(self):
        first=copy.deepcopy(self.data["groups.csv"][0])
        second=dict(first,group_id=78,ordered_member_ids="#(3L, 4L)")
        values=[{key:str(value) for key,value in row.items()} for row in (first,second)]
        v.same_groups(values,copy.deepcopy(values))
        for change in ("rows","members","front","gap","duplicate"):
            with self.subTest(change=change):
                changed=copy.deepcopy(values)
                if change=="rows":
                    changed.reverse()
                elif change=="members":
                    changed[0]["ordered_member_ids"]="#(2L, 1L)"
                elif change=="front":
                    changed[0]["front_x"]="0.000001"
                elif change=="gap":
                    changed[0]["gap_mm"]="3.000001"
                else:
                    changed[1]["group_id"]=changed[0]["group_id"]
                with self.assertRaises(ValueError):
                    v.same_groups(values,changed)

    def test_independent_bounds_and_tm_measurement_tolerance_remains(self):
        data=copy.deepcopy(self.data["poses.csv"])
        data[-1]["bounds_min_x"]+=.001
        data[-1]["tm_row4_x"]+=.001
        data[-1]["tm_row1_x"]+=.000001
        write_rows(self.folder/"poses.csv",data,self.headers["poses.csv"])
        self.assertEqual(v.verify(self.folder)["paired_commands"],120)

    def test_reject_complete_composition_counter_change(self):
        self.altered("composition-stats.csv",lambda rs:rs[-1].update(rows_moved=1))

    def test_reject_missing_composition_statistics(self):
        self.altered("composition-stats.csv",lambda rs:rs.pop())

    def test_reject_elapsed_hit_inference(self):
        self.altered("cache-commands.csv",lambda rs:next(r for r in rs if r['disposition']=='hit' and int(r['serial'])>3).update(disposition="cold"))

    def test_reject_hidden_warm_build_work(self):
        self.altered("cache-commands.csv",lambda rs:next(r for r in rs if r['disposition']=='hit').update(query_build_work_executed=1))

    def test_reject_hidden_warm_capture_phase(self):
        self.altered("cache-phases.csv",lambda rs:next(r for r in rs if r['serial']==7 and r['phase']=='inspect').update(nanoseconds=1))

    def test_reject_missing_phase(self):
        self.altered("cache-phases.csv",lambda rs:rs.pop())

    def test_reject_wrong_command_sequence(self):
        self.altered("cache-commands.csv",lambda rs:rs[1].update(command_sequence=1))

    def test_reject_integer_suffix(self):
        self.altered("poses.csv",lambda rs:rs[0].update(node_handle="4294967295P"))

    def test_integerptr_maximum_exact(self):
        self.assertEqual(v.integer("4294967295",1,2**32-1),4294967295)
        self.assertEqual(v.signed("-8100984552319297358"),-8100984552319297358)

    def test_reject_wrong_tick_conversion(self):
        self.altered("metrics.csv",lambda rs:rs[0].update(elapsed_ticks=1))

    def test_reject_cache_cap(self):
        self.altered("cache-commands.csv",lambda rs:rs[0].update(live_bytes=268435457))

    def test_reject_stale_dependency_ticket(self):
        self.altered("cache-commands.csv",lambda rs:rs[1].update(geometry_epoch=2))

    def test_reject_incorrect_source_geometry(self):
        self.altered("sources.csv",lambda rs:rs[0].update(min_x_mm=0))

    def test_reject_incorrect_physical_output(self):
        self.altered("poses.csv",lambda rs:rs[0].update(bounds_min_x=0))

    def test_reject_preview_replaced_handle(self):
        self.altered("poses.csv",lambda rs:next(r for r in rs if r['operation']=='Preview').update(node_handle=4294967295))

    def test_reject_nonfinite_pose(self):
        self.altered("poses.csv",lambda rs:rs[0].update(anchor_x_mm="nan"))

    def test_reject_missing_group_member(self):
        self.altered("groups.csv",lambda rs:rs[0].update(ordered_member_ids="#(1L, 99L)"))

    def test_reject_logical_stats_change(self):
        self.altered("metrics.csv",lambda rs:rs[5].update(candidates=5))

    def test_reject_original_work_change(self):
        self.altered("cache-commands.csv",lambda rs:rs[5].update(query_build_work_original=1025))

    def test_reject_unreported_publication(self):
        self.altered("metrics.csv",lambda rs:rs[5].update(prior_publications_in_case=999))

    def test_reject_omitted_command(self):
        self.altered("metrics.csv",lambda rs:rs.pop())

    def test_reject_unknown_extra_pose(self):
        self.altered("poses.csv",lambda rs:rs.append(dict(rs[0],serial=999)))


if __name__=="__main__":
    unittest.main(verbosity=2)
