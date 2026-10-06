from copy import deepcopy
from io import BytesIO
import json
import pytest
Image=pytest.importorskip("PIL.Image",reason="Install the design-lab extra to run image-backed study tests")
from cyrus_mcp.contracts import Fault,digest
from cyrus_mcp.design_lab.store import Study,inspect_png
from cyrus_mcp.design_lab.ranking import ABI,NAMES,layout_features,fit,score
from cyrus_mcp.design_lab.__main__ import main


def png(colour=(30,80,20)):
    output=BytesIO();Image.new("RGB",(32,32),colour).save(output,format="PNG");return output.getvalue()


def views():return [dict(view_id=v,camera_sha256=("a" if v=="hero" else "b")*64,profile_sha256="c"*64,width=32,height=32,colour="sRGB display") for v in ("hero","detail")]


def features(value=0):return dict(schema=ABI,values=[value]+[0.0]*(len(NAMES)-1))


@pytest.fixture
def study(tmp_path):
    s=Study.create(tmp_path/"study","Test study",views(),max_candidates=12)
    yield s
    s.close()


def add(study,**kw):
    args=dict(recipe={"seed":7},publication_id="published_1",features=features(),project_id="project_1",task_id="task_1",lineage_id="lineage_1")
    args.update(kw);return study.add_candidate(**args)


def receipt(job):
    return dict(candidate_id=job["candidate_id"],publication_id=job["publication_id"],recipe_sha256=job["recipe_sha256"],
                **{k:job["view"][k] for k in ("view_id","camera_sha256","profile_sha256","colour")},assets_complete=True,host_qualified=True)


def complete(study,candidate):
    for job in study.status()["jobs"]:
        if job["candidate_id"]==candidate:
            lease=study.claim(job["id"],now=100)
            study.finish(job["id"],lease["attempt_token"],receipt(lease),png(),now=110)


def test_required_views_join_and_relative_feedback_is_not_approval(study):
    a=add(study,consent=True);b=add(study,features=features(1),consent=True)
    job=study.status()["jobs"][0];lease=study.claim(job["id"],now=100)
    study.finish(job["id"],lease["attempt_token"],receipt(lease),png(),now=110)
    with pytest.raises(Fault,match="required views"):study.ready(a)
    remaining=study.status()["jobs"][1];lease=study.claim(remaining["id"],now=100)
    study.finish(remaining["id"],lease["attempt_token"],receipt(lease),png(),now=110)
    complete(study,b)
    study.compare(a,b,"a","artist",consent=True)
    assert study.db.execute("SELECT count(*) FROM decisions").fetchone()[0]==0
    dataset=study.dataset();assert len(dataset["pairs"])==1 and dataset["pairs"][0]["target"]==1
    study.decide(a,"approve","artist")
    assert study.db.execute("SELECT count(*) FROM decisions").fetchone()[0]==1
    study.set_consent(a,False)
    assert study.dataset()["pairs"]==[]


def test_latest_vote_tie_neither_skip_and_synthetic_quarantine(study):
    a=add(study,consent=True);b=add(study,consent=True);complete(study,a);complete(study,b)
    for choice,count,target in (("a",1,1),("b",1,0),("tie",1,.5),("neither",0,None),("skip",0,None)):
        study.compare(a,b,choice,"artist",consent=True)
        pairs=study.dataset()["pairs"];assert len(pairs)==count
        if pairs:assert pairs[0]["target"]==target
    assert study.status()["feedback_count"]==5
    fixture=add(study,consent=True,synthetic=True);complete(study,fixture)
    study.compare(a,fixture,"b","artist",consent=True)
    assert study.dataset()["pairs"]==[]


def test_attempts_recovery_one_active_and_late_outputs(study):
    a=add(study);jobs=study.status()["jobs"];first=study.claim(jobs[0]["id"],now=100)
    with pytest.raises(Fault,match="One active"):study.claim(jobs[1]["id"])
    with pytest.raises(Fault,match="Confirm"):study.recover()
    study.recover(worker_stopped=True)
    with pytest.raises(Fault,match="requires local recovery"):study.claim(jobs[0]["id"])
    study.resolve_unknown(jobs[0]["id"])
    second=study.claim(jobs[0]["id"],now=200)
    assert second["ordinal"]==2 and second["attempt_token"]!=first["attempt_token"]
    with pytest.raises(Fault,match="Late"):study.finish(first["job_id"],first["attempt_token"],receipt(first),png(),now=210)
    study.fail(second["job_id"],second["attempt_token"],"injected failure")
    with pytest.raises(Fault,match="attempt budget"):study.claim(second["job_id"])
    assert study.db.execute("SELECT count(*) FROM attempts").fetchone()[0]==2


@pytest.mark.parametrize("bad",["publication_id","view_id","camera_sha256","recipe_sha256","assets_complete","host_qualified"])
def test_matching_receipt_is_required(study,bad):
    add(study);job=study.claim(study.status()["jobs"][0]["id"],now=100);r=receipt(job)
    r[bad]=False if bad in ("assets_complete","host_qualified") else "wrong"
    with pytest.raises(Fault):study.finish(job["job_id"],job["attempt_token"],r,png(),now=110)
    assert list((study.directory/"artifacts").iterdir())==[]


def test_corrupted_or_modified_artifacts_are_never_ready(study):
    a=add(study)
    with pytest.raises(Fault):inspect_png(png()[:50],32,32)
    with pytest.raises(Fault):inspect_png(png(),64,32)
    complete(study,a)
    artifact=next((study.directory/"artifacts").iterdir());artifact.write_bytes(png((1,2,3)))
    with pytest.raises(Fault,match="digest changed"):study.ready(a)


def test_a_green_job_with_a_changed_receipt_is_not_accepted(study):
    a=add(study);complete(study,a)
    job=study.status()["jobs"][0]
    with study.db:
        study.db.execute("UPDATE jobs SET receipt='{}' WHERE id=?",(job["id"],))
    with pytest.raises(Fault,match="receipt no longer matches"):study.ready(a)


def test_deadline_cancel_disk_budget_and_reopen(study):
    add(study);job=study.claim(study.status()["jobs"][0]["id"],seconds=1,now=100)
    with pytest.raises(Fault,match="deadline expired"):study.finish(job["job_id"],job["attempt_token"],receipt(job),png(),now=102)
    with pytest.raises(Fault,match="Stop the worker"):study.cancel(job["job_id"])
    study.cancel(job["job_id"],worker_stopped=True)
    reopened=Study(study.directory)
    assert reopened.status()["jobs"][0]["state"]=="cancelled";reopened.close()
    next_job=study.claim(study.status()["jobs"][1]["id"],now=100)
    study.config["max_artifact_bytes"]=1
    with pytest.raises(Fault,match="disk budget"):study.finish(next_job["job_id"],next_job["attempt_token"],receipt(next_job),png(),now=110)


def test_no_overwrite_or_budget_expansion(tmp_path,study):
    with pytest.raises(FileExistsError):Study.create(study.directory,"New",views())
    with pytest.raises(Fault,match="3,000"):Study.create(tmp_path/"large","Large",views(),1000,3)
    study.config["max_candidates"]=1;add(study)
    with pytest.raises(Fault,match="Candidate budget"):add(study)


def dataset():
    pairs=[]
    for project in range(3):
        for i in range(3):
            pairs.append(dict(feedback_id=f"vote_{project}_{i}",project_id=f"project_{project}",task_id="task",
                              a_id=f"a_{project}_{i}",b_id=f"b_{project}_{i}",a=features(.8+i*.02),b=features(.1+i*.02),target=1.0))
    return dict(schema="cyrus.preference-dataset/1.0",pairs=pairs,sha256=digest(pairs),training_eligible=True)


def test_ranker_learns_synthetic_direction_with_grouped_holdout_and_abi_guards():
    data=dataset();model=fit(data)
    assert not model["deployable"] and not (set(model["train_projects"])&set(model["held_out_projects"]))
    assert model["evaluation"]["log_loss"]<model["evaluation"]["constant_probability_log_loss"]
    assert score(model,features(.8),data["sha256"])>score(model,features(.1),data["sha256"])
    with pytest.raises(Fault,match="consent or content"):score(model,features(1),"changed")
    with pytest.raises(Fault,match="ABI"):score(model,{"schema":"other","values":[0]*10},data["sha256"])
    data["pairs"][0]["b_id"]=data["pairs"][-1]["b_id"];data["sha256"]=digest(data["pairs"])
    with pytest.raises(Fault,match="split boundaries"):fit(data)


def test_feature_preparation_is_bounded_and_ignores_point_placeholders():
    rows=[dict(set_id="set",instance_id="c:1",included_in_exact_output=True,transform=[[1,0,0,5],[0,1,0,5],[0,0,1,0],[0,0,0,1]],
               effective_radius_m=1,protected=True,source_entry_id="asset")]
    f=layout_features(rows,[0,0,10,10]);assert f["values"][2:4]==[.5,.5] and f["values"][-1]==1
    placeholder=deepcopy(rows[0]);placeholder.update(instance_id="c:2",included_in_exact_output=False)
    assert layout_features(rows+[placeholder],[0,0,10,10])==f
    with pytest.raises(Fault,match="Duplicate"):layout_features(rows+rows,[0,0,10,10])
    with pytest.raises(Fault,match="outside"):layout_features(rows,[0,0,1,1])


def test_cli_init_status_and_empty_dataset_does_not_train(tmp_path,capsys):
    v=tmp_path/"views.json";v.write_text(json.dumps(views()))
    target=tmp_path/"local-study"
    assert main(["init",str(target),"--name","CLI test","--views",str(v)])==0
    assert main(["status",str(target)])==0
    assert main(["fit",str(target),"--output",str(tmp_path/"model.json")])==2
    assert not (tmp_path/"model.json").exists()
