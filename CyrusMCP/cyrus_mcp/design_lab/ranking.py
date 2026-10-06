"""Small, inspectable pairwise logistic baseline. No provider or GPU needed.

Feature preparation is shared by training and scoring. Models are experiments,
never automatically installed into the scatter engine or treated as an artist.
"""
import hashlib
import math
from ..contracts import digest, fields, identifier, number, require

ABI="cyrus.layout-features/1.0"
NAMES=("log_density","occupied_grid_fraction","centre_x","centre_y","spread_x","spread_y",
       "covariance_xy","source_entry_entropy","log_radius_fraction","protected_fraction")


def validate_features(value):
    fields(value,("schema","values"))
    require(value["schema"]==ABI and type(value["values"]) is list and len(value["values"])==len(NAMES),"Feature ABI mismatch")
    for v in value["values"]:number(v,-100,100)
    return value["values"]


def layout_features(rows,bounds_m):
    require(type(rows) is list and len(rows)<=20000,"Feature preparation supports at most 20,000 actual rows","BUDGET_EXCEEDED")
    require(type(bounds_m) is list and len(bounds_m)==4,"Bounds need min X/Y and max X/Y")
    for value in bounds_m:number(value,-1e9,1e9)
    x0,y0,x1,y1=bounds_m
    require(x1>x0 and y1>y0,"Feature bounds have no area")
    points=[];radii=[];protected=0;sources={};seen=set()
    for row in rows:
        key=(row["set_id"],row["instance_id"])
        require(key not in seen,"Duplicate layout identity");seen.add(key)
        require(type(row["included_in_exact_output"]) is bool,"Invalid exact-output flag")
        if not row["included_in_exact_output"]:continue
        matrix=row["transform"]
        require(type(matrix) is list and len(matrix)==4 and all(type(r) is list and len(r)==4 for r in matrix),"Expected a column-vector 4x4 matrix")
        for r in matrix:
            for v in r:number(v,-1e30,1e30)
        require(matrix[3]==[0,0,0,1],"Invalid affine matrix")
        x,y=matrix[0][3],matrix[1][3]
        require(x0<=x<=x1 and y0<=y<=y1,"Layout extends outside the declared feature domain","GEOMETRY_CONSTRAINT")
        points.append(((x-x0)/(x1-x0),(y-y0)/(y1-y0)))
        number(row["effective_radius_m"],0,1e30);radii.append(row["effective_radius_m"])
        require(type(row["protected"]) is bool,"Invalid protected flag")
        protected+=row["protected"]
        sid=row["source_entry_id"];sources[sid]=sources.get(sid,0)+1
    n=len(points)
    if not n:return dict(schema=ABI,values=[0.0]*len(NAMES))
    cx=sum(p[0] for p in points)/n;cy=sum(p[1] for p in points)/n
    vx=sum((p[0]-cx)**2 for p in points)/n;vy=sum((p[1]-cy)**2 for p in points)/n
    covariance=sum((p[0]-cx)*(p[1]-cy) for p in points)/n
    occupied={(min(3,int(x*4)),min(3,int(y*4))) for x,y in points}
    entropy=-sum((count/n)*math.log(count/n) for count in sources.values())
    result=dict(schema=ABI,values=[math.log1p(n/((x1-x0)*(y1-y0))),len(occupied)/16,cx,cy,
                math.sqrt(vx),math.sqrt(vy),covariance,entropy,
                math.log1p((sum(radii)/n)/max(x1-x0,y1-y0)),protected/n])
    validate_features(result)
    return result


def sigmoid(value):
    if value>=0:return 1/(1+math.exp(-value))
    ex=math.exp(value);return ex/(1+ex)


def fit(dataset,iterations=400):
    require(dataset.get("schema")=="cyrus.preference-dataset/1.0" and dataset.get("training_eligible") is True,
            "Use an explicitly eligible preference dataset")
    pairs=dataset["pairs"]
    require(type(pairs) is list and 6<=len(pairs)<=10000,"Need 6–10,000 eligible comparisons","INSUFFICIENT_DATA")
    require(dataset.get("sha256")==digest(pairs),"Dataset changed after its manifest was produced")
    number(iterations,1,2000,True)
    projects=set();candidate_projects={};lineage_projects={};candidate_features={}
    for pair in pairs:
        pid=identifier(pair["project_id"]);projects.add(pid)
        require(pair["target"] in (0.0,.5,1.0) and type(pair["target"]) in (int,float),"Invalid preference target")
        for side in ("a","b"):
            validate_features(pair[side]);cid=identifier(pair[side+"_id"])
            require(candidate_projects.get(cid,pid)==pid,"Candidate crosses project split boundaries")
            require(candidate_features.get(cid,pair[side])==pair[side],"Candidate features changed across feedback records")
            candidate_projects[cid]=pid
            candidate_features[cid]=pair[side]
            lineage=pair.get(side+"_lineage_id")
            if lineage:
                require(lineage_projects.get(lineage,pid)==pid,"Lineage crosses project split boundaries")
                lineage_projects[lineage]=pid
    require(len(projects)>=3,"Need at least three independent projects for grouped evaluation","INSUFFICIENT_DATA")
    ordered=sorted(projects,key=lambda p:hashlib.sha256(("cyrus-split-v1:"+p).encode()).hexdigest())
    held_out=set(ordered[:max(1,len(ordered)//3)])
    train=[p for p in pairs if p["project_id"] not in held_out]
    test=[p for p in pairs if p["project_id"] in held_out]
    require(len(train)>=4 and sum(p["target"]!=.5 for p in train)>=2,"Too few decisive training comparisons","INSUFFICIENT_DATA")
    unique={p[side+"_id"]:p[side]["values"] for p in train for side in ("a","b")}
    mean=[sum(v[j] for v in unique.values())/len(unique) for j in range(len(NAMES))]
    scale=[max(1e-8,math.sqrt(sum((v[j]-mean[j])**2 for v in unique.values())/len(unique))) for j in range(len(NAMES))]
    def difference(p):return [(a-b)/s for a,b,s in zip(p["a"]["values"],p["b"]["values"],scale)]
    prepared=[(difference(p),p["target"]) for p in train]
    weights=[0.0]*len(NAMES)
    for _ in range(iterations):
        gradient=[.02*w for w in weights]
        for x,y in prepared:
            error=sigmoid(sum(w*v for w,v in zip(weights,x)))-y
            for j in range(len(weights)):gradient[j]+=error*x[j]/len(train)
        weights=[w-.15*g for w,g in zip(weights,gradient)]
    probabilities=[sigmoid(sum(w*x for w,x in zip(weights,difference(p)))) for p in test]
    log_loss=-sum(p["target"]*math.log(max(1e-12,q))+(1-p["target"])*math.log(max(1e-12,1-q)) for p,q in zip(test,probabilities))/len(test)
    decisive=[((q>.5)==(p["target"]==1)) if q!=.5 else .5 for p,q in zip(test,probabilities) if p["target"]!=.5]
    return dict(schema="cyrus.preference-ranker/1.0",feature_abi=ABI,feature_names=list(NAMES),
                mean=mean,scale=scale,weights=weights,dataset_sha256=dataset["sha256"],
                train_projects=sorted(projects-held_out),held_out_projects=sorted(held_out),
                train_comparisons=len(train),held_out_comparisons=len(test),
                evaluation=dict(log_loss=log_loss,constant_probability_log_loss=math.log(2),
                                decisive_accuracy=sum(decisive)/len(decisive) if decisive else None),
                deployable=False,qualification="Offline pairwise baseline only. Hold out independent projects; compare with a strong recipe baseline and artists before product use. Consent changes require rebuilding the dataset/model.")


def score(model,features,current_dataset_sha256):
    values=validate_features(features)
    require(model.get("schema")=="cyrus.preference-ranker/1.0" and model.get("feature_abi")==ABI and model.get("feature_names")==list(NAMES),"Ranker feature ABI mismatch")
    require(model.get("dataset_sha256")==current_dataset_sha256,"Dataset consent or content changed; retrain before scoring","STALE_CONTEXT")
    for name in ("weights","mean","scale"):
        require(type(model[name]) is list and len(model[name])==len(NAMES),"Malformed ranker checkpoint")
        for v in model[name]:number(v,1e-12 if name=="scale" else -1e30,1e30)
    return sum(w*(x-m)/s for w,x,m,s in zip(model["weights"],values,model["mean"],model["scale"]))
