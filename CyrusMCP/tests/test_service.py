from copy import deepcopy
import pytest
from cyrus_mcp.contracts import Fault
from cyrus_mcp.service import Service,Journal
from test_contracts import plan


class Host:
    def __init__(self):self.revision=0;self.generated=0;self.fail=False;self.is_busy=False
    def enroll(self,*_):return {"site":{},"sources":[{"source_id":"source_x","radius_m":.5}],"regions":[{"region_id":"region_x","polygon_m":[[-10,-10],[10,-10],[10,10],[-10,10]]}],"excluded":[]}
    def observe(self,*_):return {"controller_id":"observed_x","generation_id":"inspection_x","layers":[]}
    def fingerprint(self):return str(self.revision)
    def version(self):return {"fixture":True}
    def viewport_id(self):return "viewport_1"
    def busy(self):return self.is_busy
    def diagnostics(self):return {"generated":self.generated}
    def generate(self,*_):
        if self.fail:raise Fault("GENERATION_FAILED","Injected",rollback="verified")
        self.revision+=1;self.generated+=1
        return {"controller_id":"controller_1","generation_id":"generation_"+str(self.generated),"emitted":99,"undo_label":"Cyrus"}
    def undo(self,*_):self.revision+=1
    def capture(self):return {"fixture_image":True}


@pytest.fixture
def service(tmp_path):
    value=Service(Host(),Journal(tmp_path/"journal.json"))
    value.enroll(None,[],[],capture=True)
    return value


def validated(service):
    context=service.context(service.scope["scope_id"])
    return service.validate(plan(context["context_id"]))


def apply(service, value, key="key_x"):
    return service.apply(value["validation_id"],value["digest"],value["scene_epoch"],value["scene_revision"],key)


def test_pure_reads_and_validation(service):
    before=service.host.fingerprint()
    for _ in range(3):
        validated(service)
        service.diagnostics(service.epoch)
    assert service.host.fingerprint()==before and service.host.generated==0


def test_approval_idempotency_and_conflict(service):
    value=validated(service)
    with pytest.raises(Fault,match="Approve"):apply(service,value)
    service.approve(value["validation_id"])
    queued=apply(service,value)
    assert queued["operation"]["state"]=="queued"
    service.step()
    result=apply(service,value)
    assert result["operation"]["state"]=="succeeded"
    assert service.host.generated==1
    assert apply(service,value)==result
    with pytest.raises(Fault,match="different request"):apply(service,{**value,"digest":"0"*64})


@pytest.mark.parametrize("when",["before_validate","before_apply","while_queued"])
def test_external_edits_fail_closed(service,when):
    value=validated(service)
    service.approve(value["validation_id"])
    if when=="while_queued":apply(service,value)
    service.host.revision+=1
    if when=="while_queued":
        service.step()
        assert list(service.journal.records.values())[-1]["state"]=="failed"
    else:
        with pytest.raises(Fault,match="changed"):apply(service,value)
    assert service.host.generated==0


def test_cancel_before_generation(service):
    value=validated(service);service.approve(value["validation_id"])
    apply(service,value);service.cancel();service.step()
    assert service.host.generated==0
    assert apply(service,value)["operation"]["state"]=="cancelled"


def test_failed_host_never_reports_success(service):
    value=validated(service);service.approve(value["validation_id"])
    service.host.fail=True
    apply(service,value);service.step()
    record=apply(service,value)["operation"]
    assert record["state"]=="failed" and record["error"]["rollback"]=="verified"
    assert service.host.generated==0


def test_queued_restart_is_unknown_not_replayed(service):
    value=validated(service);service.approve(value["validation_id"])
    apply(service,value)
    journal=Journal(service.journal.path)
    restarted=Service(Host(),journal)
    assert apply(restarted,value)["operation"]["state"]=="outcome_unknown"
    assert restarted.host.generated==0


def test_corrupt_journal_blocks_startup(tmp_path):
    file=tmp_path/"x.json";file.write_text("{")
    with pytest.raises(Fault,match="damaged"):Journal(file)


def test_capture_permissions_revision_generation_and_budget(service):
    value=validated(service);service.approve(value["validation_id"])
    apply(service,value);service.step()
    args=(service.epoch,service.revision,"viewport_1","generation_1")
    service.scope["allow_capture"]=False
    with pytest.raises(Fault,match="sharing"):service.capture(*args)
    service.scope["allow_capture"]=True
    assert service.capture(*args)["fixture_image"]
    assert service.capture(*args)["fixture_image"]
    with pytest.raises(Fault,match="Two captures"):service.capture(*args)


def test_unknown_operation_and_reset(service):
    with pytest.raises(Fault):service.dispatch("execute",{"code":"anything"})
    epoch=service.epoch
    service.reset()
    with pytest.raises(Fault):service.check_epoch(epoch)
    with pytest.raises(Fault):service.context("old_scope")


def test_inspection_cannot_be_promoted_to_design(service):
    service.observe(None,capture=True)
    context=service.context(service.scope["scope_id"])
    assert context["budget"]["candidates_remaining"]==0
    assert context["capabilities"]==["cached_inspection","viewport_capture"]
    with pytest.raises(Fault,match="inspection only"):
        service.validate(plan(context["context_id"]))
    assert service.status(service.epoch,controller_id="observed_x")["controller"]["generation_id"]=="inspection_x"
    assert service.capture(service.epoch,service.revision,"viewport_1","inspection_x")["fixture_image"]
    assert service.host.generated==0


def test_capture_that_rebuilds_preview_is_not_reported_fresh(service):
    service.observe(None,capture=True)
    def changed():
        service.host.revision+=1
        return {"fixture_image":True}
    service.host.capture=changed
    with pytest.raises(Fault,match="changed"):
        service.capture(service.epoch,service.revision,"viewport_1","inspection_x")
