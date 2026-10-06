"""Explicit local CLI for offline studies. It never connects to Max or MCP."""
import argparse
import json
import sys
from pathlib import Path
from ..contracts import Fault,canonical,decode,require
from ..diagnostics import save_report
from ..procedural_plan import compile_draft
from .store import Study
from .ranking import fit,layout_features


def read(path,limit=131072):
    path=Path(path)
    require(path.stat().st_size<=limit,"Input file exceeds its budget","BUDGET_EXCEEDED")
    return decode(path.read_bytes(),limit)


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest="command",required=True)
    draft=sub.add_parser("validate-draft",help="Validate policy-3 ownership/order/work offline; cannot apply")
    draft.add_argument("plan");draft.add_argument("enrollment")
    features=sub.add_parser("features",help="Prepare features from actual rows; JSONL, at most 20,000 rows")
    features.add_argument("rows");features.add_argument("--bounds",nargs=4,type=float,required=True)
    init=sub.add_parser("init",help="Create a bounded local study; no rendering starts")
    init.add_argument("directory");init.add_argument("--name",required=True);init.add_argument("--views",required=True)
    init.add_argument("--candidates",type=int,default=32);init.add_argument("--attempts",type=int,default=2)
    init.add_argument("--artifact-mib",type=int,default=128)
    for name in ("status","dataset","fit"):
        cmd=sub.add_parser(name);cmd.add_argument("directory")
        if name!="status":cmd.add_argument("--output",required=True)
    add=sub.add_parser("add");add.add_argument("directory");add.add_argument("candidate_file")
    claim=sub.add_parser("claim");claim.add_argument("directory");claim.add_argument("job_id");claim.add_argument("--seconds",type=int,default=120)
    finish=sub.add_parser("finish");finish.add_argument("directory");finish.add_argument("job_id");finish.add_argument("attempt_token")
    finish.add_argument("--receipt",required=True);finish.add_argument("--png",required=True)
    fail=sub.add_parser("fail");fail.add_argument("directory");fail.add_argument("job_id");fail.add_argument("attempt_token");fail.add_argument("reason")
    recover=sub.add_parser("recover");recover.add_argument("directory");recover.add_argument("--worker-stopped",action="store_true")
    resolve=sub.add_parser("resolve-unknown");resolve.add_argument("directory");resolve.add_argument("job_id")
    cancel=sub.add_parser("cancel");cancel.add_argument("directory");cancel.add_argument("job_id");cancel.add_argument("--worker-stopped",action="store_true")
    compare=sub.add_parser("compare");compare.add_argument("directory");compare.add_argument("a");compare.add_argument("b")
    compare.add_argument("--choice",choices=("a","b","tie","neither","skip"),required=True)
    compare.add_argument("--reviewer",required=True);compare.add_argument("--reason",default="");compare.add_argument("--consent",action="store_true")
    decide=sub.add_parser("decide");decide.add_argument("directory");decide.add_argument("candidate_id")
    decide.add_argument("decision",choices=("approve","reject","defer"));decide.add_argument("--reviewer",required=True)
    consent=sub.add_parser("consent");consent.add_argument("directory");consent.add_argument("candidate_id")
    group=consent.add_mutually_exclusive_group(required=True);group.add_argument("--allow",action="store_true");group.add_argument("--revoke",action="store_true")
    args=parser.parse_args(argv)
    study=None
    try:
        command=args.command
        result={"ok":True}
        if command=="validate-draft":result["compilation"]=compile_draft(read(args.plan),read(args.enrollment))
        elif command=="features":
            rows=[]
            path=Path(args.rows)
            require(path.stat().st_size<=16*1024*1024,"Feature file exceeds 16 MiB","BUDGET_EXCEEDED")
            with path.open("rb") as stream:
                while line:=stream.readline(16385):
                    require(len(rows)<20000,"Feature row budget exceeded","BUDGET_EXCEEDED")
                    rows.append(decode(line,16384))
            result["features"]=layout_features(rows,args.bounds)
        elif command=="init":
            study=Study.create(args.directory,args.name,read(args.views),args.candidates,args.attempts,args.artifact_mib*1024*1024)
            result["study"]=study.config
        else:
            study=Study(args.directory)
            if command=="status":result.update(study.status())
            elif command=="add":result["candidate_id"]=study.add_candidate(**read(args.candidate_file))
            elif command=="claim":result["job"]=study.claim(args.job_id,args.seconds)
            elif command=="finish":
                path=Path(args.png);require(path.stat().st_size<=16*1024*1024,"PNG exceeds 16 MiB","BUDGET_EXCEEDED")
                with path.open("rb") as stream:raw=stream.read(16*1024*1024+1)
                result["artifact_sha256"]=study.finish(args.job_id,args.attempt_token,read(args.receipt),raw)
            elif command=="fail":study.fail(args.job_id,args.attempt_token,args.reason)
            elif command=="recover":study.recover(args.worker_stopped)
            elif command=="resolve-unknown":study.resolve_unknown(args.job_id)
            elif command=="cancel":study.cancel(args.job_id,args.worker_stopped)
            elif command=="compare":result["feedback_id"]=study.compare(args.a,args.b,args.choice,args.reviewer,args.reason,args.consent)
            elif command=="decide":study.decide(args.candidate_id,args.decision,args.reviewer)
            elif command=="consent":study.set_consent(args.candidate_id,args.allow)
            elif command in ("dataset","fit"):
                dataset=study.dataset();artifact=fit(dataset) if command=="fit" else dataset
                save_report(args.output,artifact)
                result["written"]=str(Path(args.output).resolve());result["eligible_pairs"]=len(dataset["pairs"])
        print(json.dumps(result,indent=2))
        return 0
    except Fault as exc:
        print(canonical(exc.result()),file=sys.stderr);return 2
    except (OSError,TypeError,ValueError) as exc:
        print(canonical({"ok":False,"error":{"code":"LOCAL_INPUT_ERROR","message":str(exc)}}),file=sys.stderr);return 2
    finally:
        if study is not None:study.close()


if __name__=="__main__":raise SystemExit(main())
