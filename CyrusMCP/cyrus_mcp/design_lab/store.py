"""A bounded local study journal. Jobs describe work for a future qualified
worker; this module never starts Max, renders, applies recipes or deletes data.
"""
from contextlib import contextmanager
from copy import deepcopy
from io import BytesIO
from pathlib import Path
import hashlib
import json
import os
import sqlite3
import time
import uuid

from ..contracts import Fault, canonical, digest, fields, identifier, label, number, require


def token():return uuid.uuid4().hex


def sha(value):
    require(type(value) is str and len(value)==64 and all(c in "0123456789abcdef" for c in value),"Invalid SHA-256")
    return value


def inspect_png(raw, width, height):
    """Decode pixels, not just the header. No resize, colour conversion or write."""
    require(0<len(raw)<=16*1024*1024,"PNG exceeds the 16 MiB artifact budget","BUDGET_EXCEEDED")
    number(width,16,4096,True);number(height,16,4096,True)
    from PIL import Image, UnidentifiedImageError
    try:
        with Image.open(BytesIO(raw)) as image:
            require(image.format=="PNG" and image.size==(width,height) and not getattr(image,"is_animated",False),
                    "Artifact dimensions, format or animation do not match its view")
            image.verify()
        with Image.open(BytesIO(raw)) as image:
            image.load()
            require(image.mode in ("RGB","RGBA"),"Use an RGB/RGBA display PNG with an explicit colour profile label")
    except (OSError,ValueError,SyntaxError,UnidentifiedImageError,Image.DecompressionBombError) as exc:
        raise Fault("ARTIFACT_INVALID","PNG did not decode completely") from exc
    return hashlib.sha256(raw).hexdigest()


def expected_receipt(candidate,view):
    return dict(candidate_id=candidate["id"],publication_id=candidate["publication_id"],recipe_sha256=candidate["recipe_sha"],
                view_id=view["view_id"],camera_sha256=view["camera_sha256"],profile_sha256=view["profile_sha256"],colour=view["colour"],
                assets_complete=True,host_qualified=True)


class Study:
    def __init__(self, directory):
        self.directory=Path(directory).resolve()
        require((self.directory/"study.sqlite").is_file(),"Initialize a study directory first","UNKNOWN_REFERENCE")
        self.db=sqlite3.connect(self.directory/"study.sqlite",timeout=5)
        self.db.row_factory=sqlite3.Row
        self.db.execute("PRAGMA foreign_keys=ON")
        self.db.execute("PRAGMA busy_timeout=5000")
        self.config=json.loads(self.db.execute("SELECT value FROM metadata WHERE key='study'").fetchone()[0])
        require(self.config.get("schema")=="cyrus.study/1.0","Unsupported study schema")

    @classmethod
    def create(cls,directory,name,views,max_candidates=32,max_attempts=2,max_bytes=128*1024*1024):
        label(name);number(max_candidates,1,1000,True);number(max_attempts,1,3,True)
        number(max_bytes,1024*1024,512*1024*1024,True)
        require(type(views) is list and 1<=len(views)<=8,"Choose one to eight required views")
        seen=set()
        for view in views:
            fields(view,("view_id","camera_sha256","profile_sha256","width","height","colour"))
            identifier(view["view_id"]);sha(view["camera_sha256"]);sha(view["profile_sha256"])
            require(view["view_id"] not in seen,"Duplicate required view");seen.add(view["view_id"])
            number(view["width"],16,4096,True);number(view["height"],16,4096,True);label(view["colour"])
        require(max_candidates*len(views)*max_attempts<=3000,"Study candidate × view × attempt budget exceeds 3,000","BUDGET_EXCEEDED")
        directory=Path(directory).resolve();directory.mkdir(parents=True,exist_ok=True)
        database=directory/"study.sqlite"
        # An exclusive create prevents overwriting another study or racing init.
        with database.open("xb"):pass
        db=sqlite3.connect(database)
        try:
            db.executescript("""
                PRAGMA foreign_keys=ON;
                CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);
                CREATE TABLE candidates(id TEXT PRIMARY KEY,project_id TEXT NOT NULL,task_id TEXT NOT NULL,
                    lineage_id TEXT NOT NULL,recipe TEXT NOT NULL,recipe_sha TEXT NOT NULL,publication_id TEXT NOT NULL,
                    features TEXT NOT NULL,synthetic INTEGER NOT NULL,consent INTEGER NOT NULL);
                CREATE TABLE jobs(id TEXT PRIMARY KEY,candidate_id TEXT NOT NULL REFERENCES candidates(id),
                    view_id TEXT NOT NULL,state TEXT NOT NULL DEFAULT 'queued',attempts INTEGER NOT NULL DEFAULT 0,
                    active_token TEXT,deadline REAL,artifact_sha TEXT,receipt TEXT,error TEXT,
                    UNIQUE(candidate_id,view_id));
                CREATE UNIQUE INDEX one_active_job ON jobs((1)) WHERE state='running';
                CREATE TABLE attempts(token TEXT PRIMARY KEY,job_id TEXT NOT NULL REFERENCES jobs(id),
                    ordinal INTEGER NOT NULL,state TEXT NOT NULL,started REAL NOT NULL,ended REAL,error TEXT);
                CREATE TABLE feedback(id TEXT PRIMARY KEY,a TEXT NOT NULL REFERENCES candidates(id),
                    b TEXT NOT NULL REFERENCES candidates(id),choice TEXT NOT NULL,reviewer TEXT NOT NULL,
                    reason TEXT NOT NULL,consent INTEGER NOT NULL,created REAL NOT NULL);
                CREATE TABLE decisions(id TEXT PRIMARY KEY,candidate_id TEXT NOT NULL REFERENCES candidates(id),
                    decision TEXT NOT NULL,reviewer TEXT NOT NULL,created REAL NOT NULL);
            """)
            config=dict(schema="cyrus.study/1.0",study_id=token(),name=name,views=deepcopy(views),
                        max_candidates=max_candidates,max_attempts=max_attempts,max_artifact_bytes=max_bytes,
                        renderer_execution_supported=False,training_consent_default=False)
            with db:db.execute("INSERT INTO metadata VALUES('study',?)",(canonical(config),))
        finally:db.close()
        (directory/"artifacts").mkdir(exist_ok=True)
        return cls(directory)

    def close(self):self.db.close()

    @contextmanager
    def transaction(self):
        self.db.execute("BEGIN IMMEDIATE")
        try:yield
        except BaseException:
            self.db.rollback();raise
        else:self.db.commit()

    def add_candidate(self,recipe,publication_id,features,project_id,task_id,lineage_id,synthetic=False,consent=False):
        for value in (project_id,task_id,lineage_id):identifier(value)
        require(type(publication_id) is str and 1<=len(publication_id)<=256,"Missing publication identity")
        from .ranking import validate_features
        validate_features(features)
        payload=canonical(recipe)
        require(len(payload.encode())<=131072,"Recipe exceeds 128 KiB","BUDGET_EXCEEDED")
        require(type(synthetic) is bool and type(consent) is bool,"Candidate provenance flags must be explicit booleans")
        cid=token()
        with self.transaction():
            count=self.db.execute("SELECT count(*) FROM candidates").fetchone()[0]
            require(count<self.config["max_candidates"],"Candidate budget exhausted","BUDGET_EXCEEDED")
            self.db.execute("INSERT INTO candidates VALUES(?,?,?,?,?,?,?,?,?,?)",
                            (cid,project_id,task_id,lineage_id,payload,digest(recipe),publication_id,canonical(features),synthetic,consent))
            for view in self.config["views"]:
                self.db.execute("INSERT INTO jobs(id,candidate_id,view_id) VALUES(?,?,?)",(token(),cid,view["view_id"]))
        return cid

    def claim(self,job_id,seconds=120,now=None):
        number(seconds,1,3600,True);now=time.time() if now is None else now
        with self.transaction():
            require(not self.db.execute("SELECT 1 FROM jobs WHERE state='running'").fetchone(),"One active job per study","HOST_BUSY")
            job=self.db.execute("SELECT * FROM jobs WHERE id=?",(job_id,)).fetchone()
            require(job is not None,"Unknown study job","UNKNOWN_REFERENCE")
            require(job["state"] in ("queued","failed"),"Job requires local recovery or is already final","OUTCOME_UNKNOWN")
            require(job["attempts"]<self.config["max_attempts"],"Job attempt budget exhausted","BUDGET_EXCEEDED")
            attempt=token();ordinal=job["attempts"]+1
            self.db.execute("UPDATE jobs SET state='running',attempts=?,active_token=?,deadline=?,error=NULL WHERE id=?",
                            (ordinal,attempt,now+seconds,job_id))
            self.db.execute("INSERT INTO attempts VALUES(?,?,?,'running',?,NULL,NULL)",(attempt,job_id,ordinal,now))
            candidate=self.db.execute("SELECT * FROM candidates WHERE id=?",(job["candidate_id"],)).fetchone()
            view=next(v for v in self.config["views"] if v["view_id"]==job["view_id"])
        return dict(job_id=job_id,attempt_token=attempt,ordinal=ordinal,deadline=now+seconds,
                    candidate_id=candidate["id"],publication_id=candidate["publication_id"],recipe_sha256=candidate["recipe_sha"],
                    view=deepcopy(view),renderer_execution_supported=False)

    def _running(self,job_id,attempt):
        row=self.db.execute("SELECT * FROM jobs WHERE id=?",(job_id,)).fetchone()
        require(row is not None and row["state"]=="running" and row["active_token"]==attempt,
                "Late or unknown attempt; its output cannot replace the current result","STALE_CONTEXT")
        return row

    def finish(self,job_id,attempt,receipt,png,now=None):
        now=time.time() if now is None else now
        fields(receipt,("candidate_id","publication_id","recipe_sha256","view_id","camera_sha256","profile_sha256","colour","assets_complete","host_qualified"))
        require(receipt["assets_complete"] is True and receipt["host_qualified"] is True,
                "Unqualified host output or missing assets cannot become a completed study artifact","ARTIFACT_INVALID")
        with self.transaction():
            job=self._running(job_id,attempt)
            require(now<=job["deadline"],"Job deadline expired; record failure before another attempt","STALE_CONTEXT")
            candidate=self.db.execute("SELECT * FROM candidates WHERE id=?",(job["candidate_id"],)).fetchone()
            view=next(v for v in self.config["views"] if v["view_id"]==job["view_id"])
            expected=expected_receipt(candidate,view)
            require(all(receipt[k]==v for k,v in expected.items()),"Artifact receipt does not match this job","ARTIFACT_INVALID")
            file_sha=inspect_png(png,view["width"],view["height"])
            folder=self.directory/"artifacts"
            require(not folder.is_symlink(),"Artifact directory cannot be a symlink","ARTIFACT_INVALID")
            files=list(folder.iterdir())
            require(len(files)<=3000,"Unexpected artifact directory size","BUDGET_EXCEEDED")
            target=folder/(file_sha+".png")
            require(not target.is_symlink(),"Artifact cannot be a symlink","ARTIFACT_INVALID")
            used=sum(p.stat().st_size for p in files if p.is_file())
            require(used+(0 if target.exists() else len(png))<=self.config["max_artifact_bytes"],"Study artifact disk budget exhausted","BUDGET_EXCEEDED")
            if target.exists():
                require(target.stat().st_size==len(png) and hashlib.sha256(target.read_bytes()).hexdigest()==file_sha,"Existing artifact was modified","ARTIFACT_INVALID")
            else:
                # If interrupted between file and DB publication, an orphan stays
                # unjoined and counts toward disk budget; it is never auto-adopted.
                with target.open("xb") as stream:
                    stream.write(png);stream.flush();os.fsync(stream.fileno())
            self.db.execute("UPDATE jobs SET state='succeeded',artifact_sha=?,receipt=?,active_token=NULL WHERE id=?",
                            (file_sha,canonical(receipt),job_id))
            self.db.execute("UPDATE attempts SET state='succeeded',ended=? WHERE token=?",(now,attempt))
        return file_sha

    def fail(self,job_id,attempt,reason,now=None):
        label(reason);now=time.time() if now is None else now
        with self.transaction():
            self._running(job_id,attempt)
            self.db.execute("UPDATE jobs SET state='failed',active_token=NULL,error=? WHERE id=?",(reason,job_id))
            self.db.execute("UPDATE attempts SET state='failed',ended=?,error=? WHERE token=?",(now,reason,attempt))

    def recover(self,worker_stopped=False):
        require(worker_stopped is True,"Confirm the worker has stopped before recovering running jobs","APPROVAL_REQUIRED")
        with self.transaction():
            self.db.execute("UPDATE attempts SET state='outcome_unknown',ended=? WHERE state='running'",(time.time(),))
            self.db.execute("UPDATE jobs SET state='outcome_unknown',active_token=NULL WHERE state='running'")

    def resolve_unknown(self,job_id):
        with self.transaction():
            row=self.db.execute("SELECT state FROM jobs WHERE id=?",(job_id,)).fetchone()
            require(row is not None and row[0]=="outcome_unknown","Job is not awaiting recovery")
            self.db.execute("UPDATE jobs SET state='failed',error='Locally inspected; retry may be requested' WHERE id=?",(job_id,))

    def cancel(self,job_id,worker_stopped=False):
        with self.transaction():
            row=self.db.execute("SELECT * FROM jobs WHERE id=?",(job_id,)).fetchone()
            require(row is not None,"Unknown job","UNKNOWN_REFERENCE")
            require(row["state"] not in ("succeeded","outcome_unknown"),"Completed/unknown jobs require inspection")
            require(row["state"]!="running" or worker_stopped is True,"Stop the worker before cancelling its active attempt","HOST_BUSY")
            self.db.execute("UPDATE attempts SET state='cancelled',ended=? WHERE token=?",(time.time(),row["active_token"]))
            self.db.execute("UPDATE jobs SET state='cancelled',active_token=NULL WHERE id=?",(job_id,))

    def ready(self,candidate_id):
        jobs=self.db.execute("SELECT * FROM jobs WHERE candidate_id=? ORDER BY view_id",(candidate_id,)).fetchall()
        require({j["view_id"] for j in jobs}=={v["view_id"] for v in self.config["views"]} and all(j["state"]=="succeeded" for j in jobs),
                "Candidate lacks completed required views","ARTIFACT_INVALID")
        candidate=self.db.execute("SELECT * FROM candidates WHERE id=?",(candidate_id,)).fetchone()
        try:recipe=json.loads(candidate["recipe"])
        except (ValueError,TypeError) as exc:raise Fault("ARTIFACT_INVALID","Candidate recipe is damaged") from exc
        require(digest(recipe)==candidate["recipe_sha"],"Candidate recipe digest changed","ARTIFACT_INVALID")
        for job in jobs:
            view=next(v for v in self.config["views"] if v["view_id"]==job["view_id"])
            try:recorded=json.loads(job["receipt"])
            except (ValueError,TypeError) as exc:raise Fault("ARTIFACT_INVALID","Candidate receipt is damaged") from exc
            require(canonical(recorded)==canonical(expected_receipt(candidate,view)),"Candidate receipt no longer matches its required view","ARTIFACT_INVALID")
            path=self.directory/"artifacts"/(sha(job["artifact_sha"])+".png")
            require(not path.parent.is_symlink() and not path.is_symlink() and path.is_file() and path.stat().st_size<=16*1024*1024,
                    "Candidate artifact is missing or oversized","ARTIFACT_INVALID")
            with path.open("rb") as stream:raw=stream.read(16*1024*1024+1)
            require(inspect_png(raw,view["width"],view["height"])==job["artifact_sha"],
                    "Candidate artifact digest changed","ARTIFACT_INVALID")
        return [dict(j) for j in jobs]

    def compare(self,a,b,choice,reviewer,reason="",consent=False):
        identifier(reviewer)
        require(a!=b and choice in ("a","b","tie","neither","skip"),"Invalid comparison")
        require(type(reason) is str and len(reason)<=1000 and type(consent) is bool,"Invalid feedback metadata")
        self.ready(a);self.ready(b)
        ca=self.db.execute("SELECT project_id,task_id FROM candidates WHERE id=?",(a,)).fetchone()
        cb=self.db.execute("SELECT project_id,task_id FROM candidates WHERE id=?",(b,)).fetchone()
        require(tuple(ca)==tuple(cb),"Compare candidates from the same project and task")
        event=token()
        with self.transaction():
            require(self.db.execute("SELECT count(*) FROM feedback").fetchone()[0]<10000,"Feedback budget exhausted","BUDGET_EXCEEDED")
            self.db.execute("INSERT INTO feedback VALUES(?,?,?,?,?,?,?,?)",(event,a,b,choice,reviewer,reason,consent,time.time()))
        return event

    def decide(self,candidate_id,decision,reviewer):
        identifier(reviewer);require(decision in ("approve","reject","defer"),"Invalid explicit decision")
        self.ready(candidate_id)
        with self.transaction():
            require(self.db.execute("SELECT count(*) FROM decisions").fetchone()[0]<10000,"Decision budget exhausted","BUDGET_EXCEEDED")
            self.db.execute("INSERT INTO decisions VALUES(?,?,?,?,?)",(token(),candidate_id,decision,reviewer,time.time()))

    def set_consent(self,candidate_id,allowed):
        require(type(allowed) is bool,"Consent must be boolean")
        with self.transaction():
            row=self.db.execute("UPDATE candidates SET consent=? WHERE id=?",(allowed,candidate_id))
            require(row.rowcount==1,"Unknown candidate","UNKNOWN_REFERENCE")

    def dataset(self):
        # Latest vote per reviewer and unordered pair supersedes earlier votes.
        votes={}
        for vote in self.db.execute("SELECT rowid,* FROM feedback ORDER BY rowid"):
            votes[(vote["reviewer"],*sorted((vote["a"],vote["b"])))] = dict(vote)
        candidates={r["id"]:dict(r) for r in self.db.execute("SELECT * FROM candidates")}
        pairs=[];checked=set()
        for vote in votes.values():
            a,b=candidates[vote["a"]],candidates[vote["b"]]
            if not vote["consent"] or not a["consent"] or not b["consent"] or a["synthetic"] or b["synthetic"] or vote["choice"] in ("neither","skip"):
                continue
            for c in (a,b):
                if c["id"] not in checked:self.ready(c["id"]);checked.add(c["id"])
            pairs.append(dict(feedback_id=vote["id"],project_id=a["project_id"],task_id=a["task_id"],
                              a_id=a["id"],b_id=b["id"],a_lineage_id=a["lineage_id"],b_lineage_id=b["lineage_id"],
                              a=json.loads(a["features"]),b=json.loads(b["features"]),
                              target={"a":1.0,"b":0.0,"tie":.5}[vote["choice"]]))
        return dict(schema="cyrus.preference-dataset/1.0",study_id=self.config["study_id"],pairs=pairs,
                    sha256=digest(pairs),training_eligible=True,
                    semantics="Explicitly consented comparisons with complete verified views. Relative preference is not final approval. Synthetic/technical failures/neither/skip are excluded from this pairwise baseline.")

    def status(self):
        return dict(study=deepcopy(self.config),candidates=[dict(r) for r in self.db.execute("SELECT id,project_id,task_id,lineage_id,synthetic,consent FROM candidates ORDER BY rowid")],
                    jobs=[dict(r) for r in self.db.execute("SELECT id,candidate_id,view_id,state,attempts,artifact_sha,error FROM jobs ORDER BY rowid")],
                    feedback_count=self.db.execute("SELECT count(*) FROM feedback").fetchone()[0])
