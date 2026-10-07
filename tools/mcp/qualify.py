"""External qualification runner against the separately launched Max fixture."""
import argparse
import json
from pathlib import Path
import time
import uuid
from cyrus_mcp.transport import Client


class Qualification:
    def __init__(self,folder):
        self.folder=Path(folder)
        self.client=Client(self.folder/"connection")
        self.evidence=[]

    def local(self,action,**args):
        nonce=uuid.uuid4().hex
        path=self.folder/"fixture-command.json"
        temporary=path.with_suffix(".tmp")
        temporary.write_text(json.dumps({"id":nonce,"action":action,**args}))
        deadline=time.monotonic()+2
        while True:
            try:
                temporary.replace(path)
                break
            except PermissionError:
                if time.monotonic()>=deadline:raise
                time.sleep(.01)
        deadline=time.monotonic()+45
        while time.monotonic()<deadline:
            output=self.folder/"fixture-result.json"
            try:
                result=json.loads(output.read_text())
                if result["id"]==nonce:
                    assert result["ok"],result
                    return result["result"]
            except (FileNotFoundError,json.JSONDecodeError):pass
            time.sleep(.1)
        raise TimeoutError(action)

    def call(self,method,**args):
        result=self.client.call(method,**args)
        assert result.get("ok"),result
        return result

    def context(self):
        connection=self.call("connection.get_status")
        return self.call("scene.get_context",scope_id=connection["scope_id"])

    def plan(self,context,count=200,layers=1):
        source=context["scope"]["sources"][0]["source_id"]
        region=context["scope"]["regions"][0]["region_id"]
        return {"schema_version":"0.73","context_id":context["context_id"],"name":"MCP Qualified Layout","layers":[{"name":"Trees "+str(i+1),"region_id":region,"count":count,"seed":42+i*101,"sources":[{"source_id":source,"weight":1}],"scale":[.8,1.2],"yaw_degrees":[0,360],"underfill":"allow"} for i in range(layers)]}

    def apply(self,plan):
        value=self.call("scatter.validate_plan",plan=plan)
        self.local("approve",validation_id=value["validation_id"])
        args={key:value[key] for key in ("validation_id","digest","scene_epoch","scene_revision")}
        args["idempotency_key"]=uuid.uuid4().hex
        queued=self.call("scatter.apply_plan",**args)
        oid=queued["operation"]["operation_id"]
        deadline=time.monotonic()+45
        while time.monotonic()<deadline:
            status=self.call("scatter.get_status",scene_epoch=value["scene_epoch"],operation_id=oid)["operation"]
            if status["state"] not in ("queued","running"):
                retry=self.call("scatter.apply_plan",**args)["operation"]
                assert retry==status,"Idempotent replay diverged"
                return status
            time.sleep(.2)
        raise TimeoutError(oid)

    def run(self,cycles):
        for i in range(cycles):
            self.local("setup",kind=i%3)
            before=self.local("snapshot")
            context=self.context()
            proposal=self.plan(context,layers=1+i%3)
            value=self.call("scatter.validate_plan",plan=proposal)
            after=self.local("snapshot")
            assert before==after,("Inspection changed the scene",before,after)
            status=self.apply(proposal)
            assert status["state"]=="succeeded",status
            result=status["result"]
            assert 0<result["emitted"]<=result["requested"]
            assert not self.local("snapshot")["redraw_disabled"],"Generation left viewport redraw disabled"
            self.local("undo")
            undo=self.local("snapshot")
            assert undo["nodes"]==before["nodes"],("Undo leaked scene nodes",before,undo)
            self.evidence.append({"cycle":i+1,"fixture":i%3,"layers":len(proposal["layers"]),"requested":result["requested"],"emitted":result["emitted"],"duration_ms":status["duration_ms"],"transform_digest":result["transform_digest"],"pure_inspection":True,"idempotent_retry":True,"undo_nodes_restored":True})
            (self.folder/"cycles.json").write_text(json.dumps(self.evidence,indent=2))
            print(json.dumps(self.evidence[-1]),flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("folder",type=Path)
    parser.add_argument("--cycles",type=int,default=1)
    args=parser.parse_args()
    Qualification(args.folder).run(args.cycles)
