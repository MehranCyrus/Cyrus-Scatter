"""Host-thread prepared-source adapter; uses the existing native package engine."""
from copy import deepcopy
import time
import pymxs
from pymxs import runtime as rt
from .contracts import Fault,digest,number,require

STAGE_SELECTED=r'''(
    fn cyrusMCPStageSelectedSources graph directory token nodeIDs created = (
        local copy=CyrusRecipeObject (for pair in graph[2] collect #(pair[1],pair[2]))
        local selected=#()
        for identity in nodeIDs do for row in (CyrusRecipeGet graph "nodes") where (CyrusRecipeGet row "id")==identity do append selected row
        CyrusRecipePut copy "nodes" selected
        with animate off (CyrusAssetStage #(copy,directory,token) #() createdNodes:created)
    )
)'''

from .asset_use import preflight

class PreparedSources:
    def __init__(self,host):
        self.host=host;self.parts=[];self.entries={};self.started=None
        self.preflight_revision=None;self.resources=None;self.stage=None

    @property
    def token(self):return next((part["token"] for part in self.parts if part["token"] is not None),None)

    @property
    def graph(self):return next((part["graph"] for part in self.parts if part["graph"] is not None),None)

    def supported(self):
        try:return int(rt.cyrusAssetPreparedSourceVersion())==1 and int(rt.CyrusAssetStageTrackingVersion())==1
        except (AttributeError,RuntimeError,TypeError,ValueError):return False

    def cohort_supported(self):
        try:return int(rt.cyrusAssetPackageRetainVersion())==1
        except (AttributeError,RuntimeError,TypeError,ValueError):return False

    def begin(self,directory):
        self.begin_many([dict(directory=directory)])

    def begin_many(self,selections):
        from .asset_use import MAX_FILE_BYTES,MAX_PIXELS
        self.host.assert_main();self.release()
        require(self.supported(),"Prepared source use requires matching native metadata and tracked stage APIs","UNSUPPORTED_CAPABILITY")
        require(not self.host.busy(),"Prepare source assets when Max is idle","HOST_BUSY")
        require(type(selections) is list and 1<=len(selections)<=3,"Choose 1–3 installed source references","BUDGET_EXCEEDED")
        require(len(selections)==1 or self.cohort_supported(),"Multiple packages require native retained snapshot API 1","UNSUPPORTED_CAPABILITY")
        for selection in selections:
            root,revision,resources=preflight(selection["directory"])
            part=next((p for p in self.parts if p["root"]==root),None)
            if part is None:
                part=dict(root=root,revision=revision,resources=resources,token=None,graph=None,selection=[])
                self.parts.append(part)
            part["selection"].append(deepcopy(selection))
        resources=[p["resources"] for p in self.parts]
        self.resources={key:sum(row[key] for row in resources) for key in ("file_bytes","mesh_encoded_bytes","image_pixels","source_nodes","materials","maps")}
        self.resources["packages"]=len(self.parts)
        require(self.resources["file_bytes"]<=MAX_FILE_BYTES and self.resources["mesh_encoded_bytes"]<=32*1024**2
                and self.resources["image_pixels"]<=MAX_PIXELS and self.resources["maps"]<=128 and self.resources["materials"]<=64,
                "Aggregate selected-source package admission exceeded","BUDGET_EXCEEDED")
        self.preflight_revision=self.parts[0]["revision"] if len(self.parts)==1 else digest([p["revision"] for p in self.parts])
        if any(row["graph_version"]==3 for row in resources):
            admission=rt.cyrusAssetPlantSceneAdmission(self.resources["mesh_encoded_bytes"],self.resources["image_pixels"])
            self.resources["native_working_estimate_bytes"]=int(admission[0])
        self.started=time.monotonic();self.start_part(self.parts[0])

    def start_part(self,part):
        # Serial file workers avoid racing publication of identical cache images.
        part["token"]=rt.cyrusAssetPackagePrepare(str(part["root"]),str(rt.CyrusAssetBitmapDirectory()))

    def dependencies(self):
        statuses=[self.check_dependencies(part["graph"]) for part in self.parts]
        return dict(status="native_finite_adapter_preflight",packages=statuses,
                    limits="No render or material-equivalence verification; proxies and arbitrary shader classes are unsupported")

    def check_dependencies(self,graph):
        get=rt.CyrusRecipeGet
        version=int(get(graph,"version"))
        if version==3:
            rt.CyrusAssetCheckImageBuild();rt.CyrusAssetCheckRenderer()
            expected=rt.CyrusAssetAdapterProfile();saved=get(graph,"rendererProfile")
            require(all(get(saved,key)==get(expected,key) for key in ("id","hostYear","pluginVersion")),"Renderer adapter profile differs","UNSUPPORTED_CAPABILITY")
            if any(str(get(row,"kind")) in ("forest-color-v1","forest-edge-v1") for row in get(graph,"maps")):rt.CyrusAssetCheckForest()
        return dict(renderer_profile=version==3)

    def poll(self):
        self.host.assert_main();require(self.parts,"No prepared source job","UNKNOWN_REFERENCE")
        require(time.monotonic()-self.started<60,"Native source preparation timed out; re-share locally","BUDGET_EXCEEDED")
        for part in self.parts:
            if part["graph"] is not None:continue
            if part["token"] is None:self.start_part(part)
            state=rt.cyrusAssetPackagePoll(part["token"])
            if str(state[0])=="preparing":return None
            require(str(state[0])=="ready","Source package preparation failed; review the package locally","UNSUPPORTED_CAPABILITY")
            if self.cohort_supported():
                original=part["token"];part["token"]=rt.cyrusAssetPackageRetain(original)
                rt.cyrusAssetPackageRelease(original)
            self.freeze_part(part)
        entries=[];self.entries={}
        for index,part in enumerate(self.parts):
            for row in part["entries"]:
                key="p"+str(index)+"_"+row["node_id"]
                self.entries[key]=dict(part=part,node_id=row["node_id"])
                entries.append({**row,"node_id":key})
        require(1<=len(entries)<=3,"Selected source count exceeds the task bound","BUDGET_EXCEEDED")
        self.resources["source_nodes"]=len(entries)
        return dict(package_revision=self.preflight_revision,entries=entries,resources=deepcopy(self.resources),dependencies=self.dependencies())

    def freeze_part(self,part):
        from .max_host import frozen
        require(preflight(part["root"])[1]==part["revision"],"Source package changed during preparation","STALE_CONTEXT")
        package=rt.cyrusAssetPackagePrepared(part["token"],False);get=rt.CyrusRecipeGet
        graph=get(package,"graph")
        # Recheck the prepared metadata rather than trusting only the earlier file read.
        manifest=get(package,"manifest")
        manifest_fields={key:frozen(get(manifest,key)) for key in ("format","version","hostYear","redistribution")}
        for key in ("recipe","graph"):
            descriptor=get(manifest,key)
            manifest_fields[key]={name:frozen(get(descriptor,name)) for name in ("file","bytes","sha256")}
        require(digest(manifest_fields)==part["revision"],"Prepared package differs from the local review","STALE_CONTEXT")
        roles={str(get(row,"id")):row for row in get(get(package,"recipe"),"roles")}
        meshes={str(get(row,"id")):str(get(row,"file")) for row in get(graph,"meshes")}
        files={str(get(row,"id")):str(get(row,"sha256")) for row in get(graph,"files")}
        entries=[]
        selection={s["source_node_id"]:s for s in part["selection"] if "source_node_id" in s}
        for node in get(graph,"nodes"):
            node_id=str(get(node,"id"));node_roles=list(get(node,"roles"))
            if selection and node_id not in selection:continue
            require(node_roles and all(str(role) in roles and rt.CyrusAssetRoleIsSource(roles[str(role)]) for role in node_roles),
                    "Prepared nodes must be source-only; receivers/context need another operation","UNSUPPORTED_CAPABILITY")
            file_id=meshes[str(get(node,"mesh"))]
            raw=rt.cyrusAssetPreparedSourceInfo(part["token"],file_id)
            info={key:frozen(get(raw,key)) for key in ("schema","vertices","triangles","minimum_m","maximum_m","radius_xy_m","radius_xyz_m","mesh_storage_bytes","mapping_channels","stored_normals")}
            entries.append(dict(node_id=node_id,name=str(get(node,"name")),mesh_sha256=files[file_id],geometry=info))
            if node_id in selection:
                entries[-1].update(catalog_asset_ref=selection[node_id]["asset_ref"],catalog_entry_id=selection[node_id]["entry_id"])
        require(not selection or len(entries)==len(selection),"Prepared catalog node binding is missing","STALE_CONTEXT")
        part.update(graph=graph,entries=entries)

    def release(self):
        self.host.assert_main()
        parts=self.parts;self.parts=[];self.entries={}
        for part in parts:
            if part["token"] is not None:
                rt.cyrusAssetPackageCancel(part["token"]);rt.cyrusAssetPackageRelease(part["token"])

    def stage_sources(self,sources,created):
        ordered={}
        for part in self.parts:
            selected=[entry for entry in sources if self.entries[entry["node_id"]]["part"] is part]
            if not selected:continue
            offset=len(created)
            ids=[self.entries[entry["node_id"]]["node_id"] for entry in selected]
            self.stage(part["graph"],str(part["root"]),part["token"],rt.Array(*ids),created)
            require(len(created)==offset+len(selected),"Native source staging count differs","HOST_ERROR")
            for index,entry in enumerate(selected):ordered[entry["node_id"]]=created[offset+index]
            self.host.checkpoint("asset_after_package")
        return [ordered[entry["node_id"]] for entry in sources]

    def scope_state(self):
        from .max_host import frozen
        require(len(self.host.scene_nodes)<=32,"Shared source state exceeds its bound","BUDGET_EXCEEDED")
        require(len(rt.selection)<=32,"Source transaction selection exceeds 32 objects","BUDGET_EXCEEDED")
        return dict(metadata=self.host.scene_snapshot(),nodes=[dict(object_id=oid,transform=frozen(node.transform),renderable=bool(node.renderable))
                for oid,node in self.host.scene_nodes.items() if rt.isValidNode(node)],
                selection=[int(rt.getHandleByAnim(n)) for n in rt.selection])

    def use(self,proposal):
        self.host.assert_main()
        try:
            require(self.token is not None and self.graph is not None,"Prepared source grant was revoked","STALE_CONTEXT")
            require(not self.host.busy(),"Max is busy; source import was not started","HOST_BUSY")
            self.host.metre=1.0/float(rt.units.decodeValue("1m"))
            number(self.host.metre,1e-12,1e12)
            require(bool(rt.cyrusLicenseAllows()),"Cyrus source authoring requires an active license","LICENSE_REQUIRED")
            require(proposal["package_revision"]==self.preflight_revision,"Prepared source revision changed","STALE_CONTEXT")
            self.dependencies()
            ids=[entry["node_id"] for entry in proposal["sources"]]
            require(all(key in self.entries for key in ids),"Prepared source identity changed","STALE_CONTEXT")
            before=self.scope_state();history=[str(v) for v in rt.theHold.GetUndoNames()]
            selected=[node for node in rt.selection]
            require(len(history)<=128,"Prior Undo history exceeds the source transaction witness bound","BUDGET_EXCEEDED")
            self.stage=self.stage or rt.execute(STAGE_SELECTED)
        except Fault as exc:raise Fault(exc.code,exc.message,**{**exc.details,"effects":"none"}) from exc
        except Exception as exc:raise Fault("UNSUPPORTED_CAPABILITY","Prepared source preflight failed before mutation",effects="none") from exc
        from .service import uid
        identity=uid("asset_use");label="Cyrus source assets "+identity[-8:]
        created=rt.Array();failure=None;sources=[]
        with pymxs.undo(True,label):
            try:
                ordered_nodes=self.stage_sources(proposal["sources"],created)
                require(len(created)==len(ids),"Native source staging count differs","HOST_ERROR")
                self.host.checkpoint("asset_after_stage")
                for entry,node in zip(proposal["sources"],ordered_nodes):
                    rt.hide(node);node.renderable=False
                    rt.setUserProp(node,"CyrusAutomationAssetUse",identity)
                    rt.setUserProp(node,"CyrusAutomationAssetRef",entry["asset_ref"])
                    measured=self.host.source_descriptor(node)
                    require(measured["triangles"]==entry["geometry"]["triangles"] and measured["vertices"]==entry["geometry"]["vertices"],"Created source topology differs","HOST_ERROR")
                    for axis in range(3):
                        require(abs(measured["source_geometry"]["local_aabb_m"]["size"][axis]-entry["geometry"]["local_aabb_m"]["size"][axis])<=1e-5,
                                "Created source physical bounds differ","HOST_ERROR")
                    sources.append(dict(object_id=uid("object"),asset_ref=entry["asset_ref"],node_handle=int(rt.getHandleByAnim(node)),
                                        geometry=measured,name=self.host.node_label(node)))
                if selected:rt.select(rt.Array(*selected))
                else:rt.clearSelection()
            except Exception as exc:
                failure=exc
                raise  # The sole pymxs Undo context cancels and consumes the exception.
        if failure:
            restored=not any(rt.isValidNode(node) for node in created) and self.scope_state()==before and [str(v) for v in rt.theHold.GetUndoNames()]==history
            if restored:raise Fault("ASSET_USE_FAILED","Source import failed; native rollback was verified",rollback="verified") from failure
            raise Fault("ROLLBACK_FAILED","Source import restoration could not be verified; inspect locally") from failure
        self.host.undo_checkpoint=dict(kind="source_assets",label=label,before=before,history=history,created=list(created),scene_nodes=dict(self.host.scene_nodes))
        result=dict(operation_kind="import_sources",asset_use_id=identity,package_revision=proposal["package_revision"],sources=sources,
                    undo_label=label,selection_preserved=None,hidden=True,renderable=False,placements_calculated=False,
                    persistent_bitmap_cache="Native hash-addressed imported assets retained for scene references; not removed by Undo")
        # The native hold has committed. Failures from here carry the commit witness.
        try:
            self.host.checkpoint("asset_after_native_commit")
            require(self.scope_state()==before,"Source import changed pre-existing scope/selection","HOST_ERROR")
            result["selection_preserved"]=True
            for item,node in zip(sources,ordered_nodes):self.host.scene_nodes[item["object_id"]]=node
        except Exception as exc:raise Fault("POST_COMMIT_FAILED","Source assets committed; completion requires local review",effects="committed",result=result) from exc
        return result

    def undo(self,witness):
        pymxs.run_undo()
        self.host.scene_nodes=dict(witness["scene_nodes"])
        require(not any(rt.isValidNode(n) for n in witness["created"]) and self.scope_state()==witness["before"]
                and [str(v) for v in rt.theHold.GetUndoNames()]==witness["history"],"Source import Undo could not be verified","UNDO_UNVERIFIED")
        self.host.undo_checkpoint=None
        return dict(native_undo_verified=True,operation_kind="undo_import_sources",undo_label=witness["label"],removed_created_nodes=len(witness["created"]))
