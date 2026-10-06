"""3ds Max adapter. Import and call exclusively on Max's UI thread."""
import base64
import math
import hashlib
import os
import threading
import ctypes
from ctypes import wintypes
from collections import Counter
from pathlib import Path
import pymxs
from pymxs import runtime as rt
from PySide6 import QtCore, QtGui, QtWidgets

from .contracts import Fault, digest, require
from .geometry import area, contains, convex, cross, hull, max_to_column_matrix
from .service import uid
from . import __version__


def point(p):
    return [float(p.x), float(p.y), float(p.z)]


def frozen(value):
    if value is None or isinstance(value, (str, bool, int, float)):
        return value
    kind = str(rt.classOf(value))
    if kind in ("Array", "ArrayParameter"):
        return [frozen(v) for v in value]
    if kind in ("Point3", "Color"):
        return str(value)
    if kind == "Matrix3":
        return [point(value[i]) for i in range(4)]
    try:
        if rt.isValidNode(value):
            return {"node_handle": int(rt.getHandleByAnim(value))}
    except RuntimeError:
        pass
    return str(value)


class MaxHost:
    def __init__(self):
        self.main_thread = threading.get_ident()
        self.nodes, self.controllers, self.masks = {}, {}, {}
        self.layouts={}
        self.metre = 1.0 / float(rt.units.decodeValue("1m"))
        self.site = None
        self.blocked = False
        self.fail_phase = None  # Private fixture hook; never exposed through IPC/MCP.
        self.read_only=False
        self.build_identity=None
        self.is_window_enabled=ctypes.WinDLL("user32").IsWindowEnabled
        self.is_window_enabled.argtypes=[wintypes.HWND]
        self.is_window_enabled.restype=wintypes.BOOL

    def assert_main(self):
        require(threading.get_ident() == self.main_thread, "Scene access requires Max's UI thread", "HOST_ERROR")

    def version(self):
        self.assert_main()
        if self.build_identity is None:
            kernel=ctypes.WinDLL("kernel32",use_last_error=True)
            kernel.GetModuleHandleW.argtypes=[wintypes.LPCWSTR]
            kernel.GetModuleHandleW.restype=wintypes.HMODULE
            kernel.GetModuleFileNameW.argtypes=[wintypes.HMODULE,wintypes.LPWSTR,wintypes.DWORD]
            modules=[]
            for name in ("AminScatter.dlx","CyrusScatterEdit.dlm","CyrusSurfaceAnalyzer.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh"):
                module=kernel.GetModuleHandleW(name)
                item={"module":name,"loaded":bool(module),"loaded_file_sha256":None}
                if module:
                    path=ctypes.create_unicode_buffer(32768)
                    if kernel.GetModuleFileNameW(module,path,len(path)):
                        try:
                            item["loaded_file_sha256"]=hashlib.sha256(Path(path.value).read_bytes()).hexdigest()
                        except OSError:
                            item["identity_status"]="loaded module file could not be read"
                modules.append(item)
            self.build_identity=modules
        script = getattr(rt, "CyrusLoadedScriptFingerprint", None)
        return {"max_version": frozen(rt.maxVersion()), "automation_version": __version__, "python_thread": self.main_thread,
                "pid":os.getpid(),"host_mode":"interactive_ui_thread", "loaded_modules":self.build_identity,
                "loaded_script_payload_sha256": str(script) if script is not None else None,
                "identity_semantics":"Module-file SHA-256 cached on first inspection; script payload fingerprint supplied by the loaded script (excluding its fingerprint line). Neither is a memory-image attestation."}

    def diagnostic_start(self, session_id):
        self.assert_main()
        from .contracts import identifier
        identifier(session_id)
        require(getattr(rt, "cyrusDiagnosticStart", None) is not None,
                "Load the matching diagnostic native/script build first", "UNSUPPORTED_CAPABILITY")
        rt.cyrusDiagnosticStart(session_id, 4096, 4 * 1024 * 1024, 600000)

    def diagnostic_stop(self):
        self.assert_main()
        require(getattr(rt, "cyrusDiagnosticStop", None) is not None,
                "Diagnostic recorder is unavailable", "UNSUPPORTED_CAPABILITY")
        rt.cyrusDiagnosticStop()

    def diagnostic_page(self, after=0, limit=100):
        self.assert_main()
        require(getattr(rt, "cyrusDiagnosticSnapshot", None) is not None,
                "Diagnostic recorder is unavailable", "UNSUPPORTED_CAPABILITY")
        return str(rt.cyrusDiagnosticSnapshot(after, limit))

    def publication_manifest(self, controller_id):
        self.assert_main()
        from .publication import manifest
        obj=self.controllers.get(controller_id)
        require(obj is not None and rt.isValidNode(obj), "Scoped controller is unavailable", "STALE_CONTEXT")
        require(int(obj.groupPolicy)==3 and getattr(obj,"procPublicationInfo",None) is not None,
                "This controller has no procedural publication reader; use the matching script/native pair", "UNSUPPORTED_CAPABILITY")
        try:
            info=frozen(obj.procPublicationInfo())
        except RuntimeError as exc:
            if "inspection budget" in str(exc):
                raise Fault("BUDGET_EXCEEDED","Published input signature exceeds the passive inspection budget") from exc
            raise Fault("PUBLICATION_UNAVAILABLE","Use Update locally to create a complete cached publication first") from exc
        result=manifest(info)
        result["cached_pending_flags"]=[bool(leaf.cacheSnapshot()[2]) for leaf in obj.layerObjects]
        result["pending_semantics"]="Cached flags only; no input-key comparison or container reconciliation is performed."
        return result

    def publication_page(self, controller_id, publication_id, offset, limit):
        self.assert_main()
        obj=self.controllers.get(controller_id)
        require(obj is not None and rt.isValidNode(obj), "Scoped controller is unavailable", "STALE_CONTEXT")
        try:
            return frozen(obj.procPublicationPage(publication_id,offset,limit))
        except RuntimeError as exc:
            raise Fault("STALE_CONTEXT","Publication changed or is unavailable; read its manifest again") from exc

    def busy(self):
        self.assert_main()
        return self.blocked or bool(rt.theHold.Holding()) or bool(rt.isAnimPlaying()) or QtWidgets.QApplication.activeModalWidget() is not None or not self.is_window_enabled(int(rt.windows.getMAXHWND()))

    def assert_static(self,node):
        # node.isAnimated describes the node track, not every geometry parameter.
        # Inspect bounded sub-animation graphs, including parent transforms.
        require(len(node.modifiers)==0,"Design inputs must be baked meshes or simple primitives without modifier stacks","UNSUPPORTED_CAPABILITY")
        stack=[node.baseObject]
        parent=node
        parents=set()
        while parent and rt.isValidNode(parent):
            handle=int(rt.getHandleByAnim(parent))
            require(handle not in parents and len(parents)<64,"Unsupported parent hierarchy","UNSUPPORTED_CAPABILITY")
            parents.add(handle)
            controller=rt.getSubAnim(parent,3).controller
            if controller:stack.append(controller)
            parent=parent.parent
        plain={"PRS","Position_Rotation_Scale","Position_XYZ","Euler_XYZ","ScaleXYZ","Bezier_Float","Linear_Float","TCB_Float",
               "Bezier_Position","Linear_Position","TCB_Position","Bezier_Rotation","Linear_Rotation","TCB_Rotation","Bezier_Scale","Linear_Scale","TCB_Scale",
               "Point_Controller_Container","Bezier_Point3","Linear_Point3","TCB_Point3"}
        plain={name.lower() for name in plain}
        visited=set()
        while stack:
            value=stack.pop()
            handle=int(rt.getHandleByAnim(value))
            if handle in visited:continue
            visited.add(handle)
            require(len(visited)<=2048,"Animation graph exceeds the inspection budget","BUDGET_EXCEEDED")
            if rt.isController(value):
                require(str(rt.classOf(value)).lower() in plain,"Procedural or constrained controllers are outside the static-input scope","UNSUPPORTED_CAPABILITY")
                require(int(rt.numKeys(value))<=0,"Animated inputs are outside the supported scope","UNSUPPORTED_CAPABILITY")
            count=int(value.numsubs)
            require(count<=2048,"Animation graph exceeds the inspection budget","BUDGET_EXCEEDED")
            for i in range(1,count+1):
                sub=rt.getSubAnim(value,i)
                child=sub.controller or sub.object
                if child is not None:stack.append(child)

    def mesh(self, node, world=True):
        require(rt.isValidNode(node), "An enrolled object was deleted", "STALE_CONTEXT")
        require(str(rt.classOf(node.baseObject)).lower() in {"editable_mesh","editable_poly","plane","box","cone","cylinder","sphere","geosphere","torus","teapot","pyramid","tube","chamferbox","chamfercyl","hedra"},
                "Use a baked Editable Mesh/Poly or a supported simple primitive; procedural/proxy sources require separate qualification","UNSUPPORTED_CAPABILITY")
        self.assert_static(node)
        counts = rt.getPolygonCount(node)
        require(int(counts[0]) <= 10000 and int(counts[1]) <= 12000, "Design inspection is limited to 10,000 faces / 12,000 vertices across its inputs", "BUDGET_EXCEEDED")
        mesh = rt.snapshotAsMesh(node)
        require(mesh.numfaces <= 10000 and mesh.numverts <= 12000 and mesh.numfaces > 0, "Unsupported evaluated mesh size", "BUDGET_EXCEEDED")
        # snapshotAsMesh already contains the evaluated world-space transform.
        # Match native meshOf(false) by removing only the node transform, retaining
        # object offsets. Applying objectTransform again double-transforms assets.
        tm = rt.matrix3(1) if world else rt.inverse(node.transform)
        vertices = [point(rt.getVert(mesh,i+1)*tm) for i in range(mesh.numverts)]
        faces = [tuple(int(v)-1 for v in point(rt.getFace(mesh,i+1))) for i in range(mesh.numfaces)]
        rt.delete(mesh)
        require(all(math.isfinite(x) and abs(x)*self.metre<=1e6 for v in vertices for x in v), "Mesh has non-finite or unsupported coordinates", "GEOMETRY_CONSTRAINT")
        return vertices, faces

    def polygon(self, node):
        require(rt.isValidNode(node), "Region is missing", "STALE_CONTEXT")
        self.assert_static(node)
        require(rt.numSplines(node) == 1 and rt.isClosed(node,1), "Region must be one closed spline", "GEOMETRY_CONSTRAINT")
        count = rt.numKnots(node,1)
        require(3 <= count <= 64, "Region needs 3–64 knots", "GEOMETRY_CONSTRAINT")
        vertices = []
        for i in range(1,count+1):
            require(str(rt.getSegmentType(node,1,i)) == "line", "Only straight region segments are supported", "UNSUPPORTED_CAPABILITY")
            vertices.append(point(rt.getKnotPoint(node,1,i)))
        # MAXScript spline queries return world coordinates in the default world context.
        require(max(p[2] for p in vertices)-min(p[2] for p in vertices) < 1e-4/self.metre, "Region must be horizontal", "GEOMETRY_CONSTRAINT")
        return convex([[p[0]*self.metre,p[1]*self.metre] for p in vertices])

    def site_polygon(self, verts, faces):
        z = [v[2]*self.metre for v in verts]
        require(max(z)-min(z) < 1e-4, "Site must be a static horizontal mesh", "UNSUPPORTED_CAPABILITY")
        xy = [[v[0]*self.metre,v[1]*self.metre] for v in verts]
        edges = Counter()
        for face in faces:
            require(cross(*(xy[i] for i in face)) > 1e-12, "Site faces must face upward and have positive area", "GEOMETRY_CONSTRAINT")
            for a,b in zip(face,face[1:]+face[:1]):
                edges[tuple(sorted((a,b)))] += 1
        require(all(n <= 2 for n in edges.values()), "Site is not manifold", "GEOMETRY_CONSTRAINT")
        boundary = [edge for edge,n in edges.items() if n == 1]
        links = {}
        for a,b in boundary:
            links.setdefault(a,[]).append(b)
            links.setdefault(b,[]).append(a)
        require(links and all(len(v) == 2 for v in links.values()), "Site has invalid boundaries", "GEOMETRY_CONSTRAINT")
        path=[next(iter(links))]
        previous=None
        while True:
            nxt = next(v for v in links[path[-1]] if v != previous)
            if nxt == path[0]:
                break
            require(nxt not in path, "Site boundary intersects itself", "GEOMETRY_CONSTRAINT")
            previous=path[-1]
            path.append(nxt)
        require(len(path) == len(links), "Sites with holes or disconnected islands are unsupported", "UNSUPPORTED_CAPABILITY")
        poly=convex(hull([xy[i] for i in path]))
        triangles=sum(cross(*(xy[i] for i in f))/2 for f in faces)
        require(abs(triangles-area(poly)) <= max(1e-6,area(poly)*1e-6), "Site triangulation does not cover its convex boundary", "GEOMETRY_CONSTRAINT")
        return poly, z[0]

    def enroll(self, site, sources, regions, excluded):
        self.assert_main()
        self.metre = 1.0 / float(rt.units.decodeValue("1m"))
        require(int(rt.maxVersion()[0]) == 29000, "This automation build is qualified for Max 2027 only", "UNSUPPORTED_CAPABILITY")
        require(1 <= len(sources) <= 3 and 1 <= len(regions) <= 3 and len(excluded) <= 3, "Enroll 1–3 sources, 1–3 planting regions and at most 3 protected regions")
        all_nodes=[site,*sources,*regions,*excluded]
        handles=[int(rt.getHandleByAnim(n)) for n in all_nodes]
        require(len(handles) == len(set(handles)), "Site, sources and regions must be distinct objects")
        counts=[rt.getPolygonCount(n) for n in [site,*sources]]
        require(sum(int(c[0]) for c in counts)<=10000 and sum(int(c[1]) for c in counts)<=12000,
                "Design scope exceeds the aggregate 10,000-face / 12,000-vertex inspection budget","BUDGET_EXCEEDED")
        verts,faces=self.mesh(site)
        total_faces,total_vertices=len(faces),len(verts)
        site_poly,z=self.site_polygon(verts,faces)
        data={"site":{"label":str(site.name)[:80],"polygon_m":site_poly,"z_m":z,"area_m2":area(site_poly)},"sources":[],"regions":[],"excluded":[]}
        nodes={uid("site"):site}
        for source in sources:
            v,f=self.mesh(source,False)
            total_faces+=len(f);total_vertices+=len(v)
            require(total_faces<=10000 and total_vertices<=12000,"Evaluated design meshes exceed the aggregate inspection budget","BUDGET_EXCEEDED")
            sid=uid("source")
            radius=max(math.hypot(p[0],p[1]) for p in v)*self.metre
            require(math.isfinite(radius) and radius > 0, "Source has no measurable footprint", "GEOMETRY_CONSTRAINT")
            data["sources"].append({"source_id":sid,"label":str(source.name)[:80],"radius_m":radius,"bounding_radius_m":max(math.sqrt(sum(x*x for x in p)) for p in v)*self.metre,"height_m":(max(p[2] for p in v)-min(p[2] for p in v))*self.metre,"triangles":len(f)})
            nodes[sid]=source
        for name,sequence in (("regions",regions),("excluded",excluded)):
            for region in sequence:
                poly=self.polygon(region)
                require(all(contains(site_poly,p) for p in poly), "Region extends outside the site", "GEOMETRY_CONSTRAINT")
                rid=uid("region")
                data[name].append({"region_id":rid,"label":str(region.name)[:80],"polygon_m":poly,"area_m2":area(poly)})
                nodes[rid]=region
        self.nodes,self.site,self.site_z=nodes,site,z
        self.controllers,self.masks={},{}
        self.layouts={}
        self.read_only=False
        return data

    def observe(self,obj):
        self.assert_main()
        require(int(rt.maxVersion()[0])==29000,"This automation build is qualified for Max 2027 only","UNSUPPORTED_CAPABILITY")
        require(rt.isValidNode(obj) and rt.classOf(obj)==rt.AminScatterObject,"Select one Cyrus Scatter controller","UNSUPPORTED_CAPABILITY")
        require(len(obj.layerObjects)<=32,"Inspection supports at most 32 layers","BUDGET_EXCEEDED")
        self.metre=1.0/float(rt.units.decodeValue("1m"))
        cid=uid("observed")
        self.nodes,self.masks={},{}
        self.layouts={}
        self.controllers={cid:obj}
        self.read_only=True
        layers=[]
        children=list(obj.layerObjects) or [obj]
        for i,layer in enumerate(children):
            state=layer.cacheSnapshot()
            layers.append({"index":i,"name":str(obj.layerNames[i])[:80] if i<len(obj.layerNames) else str(obj.name)[:80],
                           "enabled":bool(obj.layerEnabled[i]) if i<len(obj.layerEnabled) else True,
                           "amount_setting":int(layer.amount),"requested_cached":int(state[7]),
                           "generated_cached":int(state[4]),"displayed_cached":int(state[1]),
                           "dirty":bool(state[2]),"error":str(state[3])[:500],"source_count":len(layer.sources),
                           "update_mode":int(layer.updateMode),"viewport_mode":int(layer.viewportMode),"seed":int(layer.randomSeed)})
        return {"controller_id":cid,"generation_id":uid("inspection"),"name":str(obj.name)[:80],"layers":layers,
                "freshness":"cached preview only; inspection does not certify current source geometry or rebuild Manual layers",
                "ui_version":str(obj.uiVersion())}

    def controller_state(self, obj):
        keys = list(rt.AminScatterLayerFields)
        def params(layer):
            result={str(k):frozen(rt.getProperty(layer,k)) for k in keys}
            result["layer_id"]=str(layer.layerID)
            result["edit_layer_key"]=int(layer.editLayerKey)
            if layer.paintDocument is not None:
                stats=rt.cyrusBrushStats(layer.paintDocument)
                result["paint_revision"]=[int(stats[0]),int(stats[3])]
            return result
        shared={key:frozen(rt.getProperty(obj,rt.Name(key))) for key in ("groupPolicy","groupRuleA","groupRuleB","groupRuleEnabled","groupRuleGap","groupRuleFootprints","groupRulePlanar","groupCenters","viewportMode","proxyShape","viewportInstances","viewportFaces","radiusDisplayLimit","radiusDisplayAll")}
        if hasattr(obj,"procRuleScope"):
            from .procedural import RULE_FIELDS
            shared.update({key:frozen(rt.getProperty(obj,rt.Name(key))) for key in RULE_FIELDS})
        return {"root":params(obj),"shared":shared,"surfaceNodes":frozen(obj.surfaceNodes),"names":list(obj.layerNames),"enabled":list(obj.layerEnabled),"visible":list(obj.layerVisible),"layers":[params(layer) for layer in obj.layerObjects],"transform":frozen(obj.transform),"modifiers":[str(rt.classOf(m)) for m in obj.modifiers],"enabled_root":bool(obj.cyrusEnabled),"edit_revision":int(rt.cyrusEditRevision()) if len(obj.modifiers) else 0}

    def configuration(self,cid):
        self.assert_main()
        from .settings import LAYER_SETTINGS, SOURCE_SETTINGS, DISPLAY_SETTINGS
        obj=self.controllers.get(cid)
        require(obj is not None and rt.isValidNode(obj),"Controller is unavailable","UNKNOWN_REFERENCE")
        def read_settings(target,registry):
            result={}
            for key,(kind,_,_,prop) in registry.items():
                if not prop:continue
                value=[float(rt.getProperty(target,rt.Name(p))) for p in prop] if kind=="range" else frozen(rt.getProperty(target,rt.Name(prop)))
                if key.endswith("_m"):value=[v*self.metre for v in value] if isinstance(value,list) else value*self.metre
                result[key]=value
            return result
        layers=[]
        for i,leaf in enumerate(obj.layerObjects):
            parent=obj.logicalParent(leaf) if hasattr(obj,"logicalParent") else leaf
            settings=read_settings(parent,LAYER_SETTINGS)
            settings.update(enabled=bool(obj.enabledLayer(i+1)) if hasattr(obj,"enabledLayer") else bool(obj.layerEnabled[i]),visible=bool(obj.visibleLayer(i+1)))
            source_settings={key:frozen(rt.getProperty(leaf,rt.Name(spec[3]))) for key,spec in SOURCE_SETTINGS.items()}
            assets=[]
            for j,node in enumerate(leaf.sources):
                valid=node is not None and bool(rt.isValidNode(node))
                entry_id=str(leaf.procSourceSlots[j]) if hasattr(leaf,"procSourceSlots") and j<len(leaf.procSourceSlots) else None
                sid=next((key for key,value in self.nodes.items() if valid and key.startswith("source_") and value==node),"asset_"+digest([cid,str(leaf.layerID),entry_id or j])[:24])
                values={key:(source_settings[key][j] if j<len(source_settings[key]) else spec[1]) for key,spec in SOURCE_SETTINGS.items()}
                for key in values:
                    if key.endswith("_m"):values[key]*=self.metre
                point=bool(leaf.isPointSource(j+1));empty=bool(leaf.isEmptySource(j+1))
                assets.append({"source_id":sid,"entry_id":entry_id,"label":str(node.name)[:80] if valid else "Point" if point else "Empty" if empty else "Missing asset",
                               "kind":"point" if point else "empty" if empty else "mesh" if valid else "missing",
                               "weight":float(leaf.sourceWeights[j]) if j<len(leaf.sourceWeights) else 1.0,"settings":values})
            paint=rt.cyrusBrushStats(leaf.paintDocument) if leaf.paintDocument is not None else None
            layers.append({"layer_id":str(leaf.layerID),"parent_id":str(getattr(leaf,"logicalParentID","")) or None,"set_name":str(getattr(leaf,"paintSetName","Base")),
                           "name":str(obj.layerNames[i]),"count":int(parent.amount),"seed":int(parent.randomSeed),"settings":settings,"assets":assets,
                           "base_variation":{"advanced_axes":bool(parent.advancedAxes),"legacy_uniform_scale":[float(parent.scaleMinimum),float(parent.scaleMaximum)],"legacy_yaw_degrees":[float(parent.yawMinimum),float(parent.yawMaximum)],"whole_scale":[float(parent.wholeScaleMin),float(parent.wholeScaleMax)],"rotation_z_degrees":[float(parent.rotZMin),float(parent.rotZMax)]},
                           "allocation":{"parent_candidate_budget":int(parent.amount),"count_mode_candidates":int(obj.populationAllocation(leaf)[0]) if hasattr(obj,"populationAllocation") else int(leaf.amount),"population_mode":int(parent.populationMode),"plants_per_m2":float(parent.plantsPerM2),"set_weight":float(getattr(leaf,"paintSetWeight",1)),"set_enabled":bool(getattr(leaf,"paintSetEnabled",True)),"set_visible":bool(getattr(leaf,"paintSetVisible",True))},
                           "paint":{"enabled":bool(leaf.paintEnabled),"document_present":paint is not None,"stroke_count":int(paint[1]) if paint else 0,"revision":int(paint[0]) if paint else None}})
        display=read_settings(obj,DISPLAY_SETTINGS)
        display.update(mode="centres" if obj.groupCenters else {1:"point_cloud",2:"proxy",3:"mesh"}[int(obj.viewportMode)],proxy_shape={1:"box",2:"sphere",3:"pyramid"}[int(obj.proxyShape)],update_mode="manual" if obj.updateMode==1 else "real_time")
        from .procedural import read_procedural
        return {"configuration_schema":"cyrus.configuration/1.0","controller_id":cid,"layers":layers,"display":display,"group_policy":int(obj.groupPolicy),
                "procedural":read_procedural(obj,self.metre),
                "pair_rules":[{"a":str(obj.groupRuleA[i]),"b":str(obj.groupRuleB[i]),"enabled":bool(obj.groupRuleEnabled[i]),"gap_m":float(obj.groupRuleGap[i])*self.metre,"footprints":bool(obj.groupRuleFootprints[i]),"planar":bool(obj.groupRulePlanar[i])} for i in range(len(obj.groupRuleA))],
                "freshness":"current parameter values only; no generation or geometry certification"}

    def fingerprint(self):
        self.assert_main()
        state={"units":float(rt.units.decodeValue("1m")),"time":str(rt.sliderTime),"nodes":{},"controllers":{},"masks":{}}
        for key,node in self.nodes.items():
            require(rt.isValidNode(node), "An enrolled object was deleted", "STALE_CONTEXT")
            geometry=self.polygon(node) if key.startswith("region_") else self.mesh(node,not key.startswith("source_"))
            state["nodes"][key]={"geometry":geometry,"tm":frozen(node.transform),"hidden":bool(node.isHidden),"name":str(node.name)}
        for key,node in self.controllers.items():
            require(rt.isValidNode(node), "The owned controller was deleted", "STALE_CONTEXT")
            state["controllers"][key]=self.controller_state(node)
        for key,nodes in self.masks.items():
            state["masks"][key]=[self.polygon(n) for n in nodes]
        if self.read_only:
            state["preview"]=self.diagnostics()
        return digest(state)

    def checkpoint(self, phase):
        if self.fail_phase == phase:
            raise Fault("GENERATION_FAILED", "Injected fixture failure: "+phase)

    def generate(self, plan, compiled):
        self.assert_main()
        require(not self.busy(), "Host is busy", "HOST_BUSY")
        require(not rt.isSceneRedrawDisabled(),"Max viewport redraw is suspended; restore it locally before generating","HOST_BUSY")
        before=self.fingerprint()
        old_controllers,old_masks,old_layouts=dict(self.controllers),dict(self.masks),dict(self.layouts)
        created=[]
        selected=list(rt.selection)
        cid=plan.get("controller_id",uid("controller"))
        from .procedural import require_legacy_mutation
        require_legacy_mutation(self.controllers.get(cid))
        gid=uid("generation")
        undo_label="Cyrus Automation "+gid[-8:]
        failure=None
        result=None
        with pymxs.undo(True,undo_label), pymxs.redraw(False), pymxs.animate(False):
            try:
                obj=self.controllers.get(cid)
                if obj is None:
                    obj=rt.AminScatterObject(name=plan["name"])
                    created.append(obj)
                else:
                    require(len(obj.modifiers) == 0, "Controllers with modifiers cannot be refined", "UNSUPPORTED_CAPABILITY")
                self.checkpoint("controller")
                obj.setLayerTransfer(True)
                # Select semantics deliberately; never inherit a newer UI default.
                obj.groupPolicy=1 if plan["schema_version"]=="1.0" else 2
                obj.cyrusEnabled=True
                for field in ("groupRuleA","groupRuleB","groupRuleEnabled","groupRuleGap","groupRuleFootprints","groupRulePlanar"):
                    rt.setProperty(obj,rt.Name(field),rt.Array())
                obj.updateMode=1
                obj.surfaceNodes=rt.Array(self.site)
                obj.viewportMode=2
                obj.proxyShape=1
                obj.viewportInstances=2000
                obj.previewBudget=20000
                if plan["schema_version"]=="2.0":
                    from .settings import LAYER_SETTINGS, SOURCE_SETTINGS, DISPLAY_SETTINGS
                    for key,(_,_,_,prop) in DISPLAY_SETTINGS.items():
                        if prop:rt.setProperty(obj,rt.Name(prop),plan["display"][key])
                    mode=plan["display"]["mode"]
                    obj.viewportMode={"point_cloud":1,"proxy":2,"mesh":3,"centres":1}[mode]
                    obj.groupCenters=mode=="centres"
                    obj.proxyShape={"box":1,"sphere":2,"pyramid":3}[plan["display"]["proxy_shape"]]
                layers,new_masks,metrics=[],[],[]
                transform_rows=[]
                layout_instances=[]
                for spec,mask in zip(plan["layers"],compiled):
                    shape=rt.splineShape(name="Cyrus region "+spec["name"])
                    created.append(shape)
                    rt.addNewSpline(shape)
                    for x,y in mask["polygon_m"]:
                        rt.addKnot(shape,1,rt.Name("corner"),rt.Name("line"),rt.Point3(x/self.metre,y/self.metre,self.site_z/self.metre))
                    rt.close(shape,1)
                    rt.updateShape(shape)
                    shape.renderable=False
                    shape.isHidden=True
                    new_masks.append(shape)
                    layer=rt.createInstance(rt.AminScatterObject)
                    layer.setLayerTransfer(True)
                    layer.layerID=rt.CyrusNewLayerID()
                    layer.editLayerKey=len(layers)+1
                    layer.paintIdentity=plan["schema_version"]!="1.0"
                    sources=[self.nodes[s["source_id"]] for s in spec["sources"]]
                    layer.sources=rt.Array(*sources)
                    layer.amount=spec["count"]
                    layer.randomSeed=spec["seed"]
                    layer.advancedAxes=False
                    layer.scaleMinimum,layer.scaleMaximum=spec["scale"]
                    layer.yawMinimum,layer.yawMaximum=spec["yaw_degrees"]
                    # The area path uses advanced fields even when advancedAxes is off.
                    layer.sclXMin=layer.sclYMin=layer.sclZMin=spec["scale"][0]
                    layer.sclXMax=layer.sclYMax=layer.sclZMax=spec["scale"][1]
                    layer.rotZMin,layer.rotZMax=spec["yaw_degrees"]
                    layer.wholeScaleMin=layer.wholeScaleMax=1.0
                    layer.sourceWeights=rt.Array(*(s["weight"] for s in spec["sources"]))
                    for field,default in (("sourceZOffsets",0.0),("sourceScales",1.0),("sourceRadii",0.0),("sourceFollowScale",False),("sourceShowRadius",False),("sourcePoint",False),("sourceEmpty",False),("sourceForwardAxes",1)):
                        rt.setProperty(layer,rt.Name(field),rt.Array(*(default for _ in sources)))
                    layer.sourceColors=rt.Array(*(rt.color(65+45*i,175,110) for i in range(len(sources))))
                    layer.areaNodes=rt.Array(shape)
                    layer.areaModes=rt.Array(1)
                    for polygon in mask.get("exclusions_m",[]):
                        exclusion=rt.splineShape(name="Cyrus exclusion "+spec["name"])
                        created.append(exclusion);new_masks.append(exclusion)
                        rt.addNewSpline(exclusion)
                        for x,y in polygon:rt.addKnot(exclusion,1,rt.Name("corner"),rt.Name("line"),rt.Point3(x/self.metre,y/self.metre,self.site_z/self.metre))
                        rt.close(exclusion,1);rt.updateShape(exclusion)
                        exclusion.renderable=False;exclusion.isHidden=True
                        layer.areaNodes=rt.Array(*list(layer.areaNodes),exclusion)
                        layer.areaModes=rt.Array(*list(layer.areaModes),2)
                    if plan["schema_version"]=="2.0":
                        layer.advancedAxes=True
                        layer.wholeScaleMin,layer.wholeScaleMax=spec["scale"]
                        layer.projectMove=True
                        for key,(kind,_,_,prop) in LAYER_SETTINGS.items():
                            if not prop:continue
                            value=spec["settings"][key]
                            if kind=="range":
                                for target,item in zip(prop,value):rt.setProperty(layer,rt.Name(target),item/self.metre if key.endswith("_m") else item)
                            else:rt.setProperty(layer,rt.Name(prop),value/self.metre if key.endswith("_m") else value)
                        for key,(_,_,_,prop) in SOURCE_SETTINGS.items():
                            values=[s["settings"][key]/self.metre if key.endswith("_m") else s["settings"][key] for s in spec["sources"]]
                            rt.setProperty(layer,rt.Name(prop),rt.Array(*values))
                    layer.surfaceNodes=rt.Array(self.site)
                    layer.updateMode=1
                    layer.setLayerTransfer(False)
                    layers.append(layer)
                self.checkpoint("layers")
                obj.layerObjects=rt.Array(*layers)
                obj.layerNames=rt.Array(*(spec["name"] for spec in plan["layers"]))
                obj.layerEnabled=rt.Array(*(spec.get("settings",{}).get("enabled",True) for spec in plan["layers"]))
                obj.layerVisible=rt.Array(*(spec.get("settings",{}).get("visible",True) for spec in plan["layers"]))
                obj.nextEditLayerKey=len(layers)+1
                obj.activeLayer=1
                obj.setLayerTransfer(False)
                obj.syncLayerIdentity()
                for rule in plan.get("pair_rules",[]):
                    obj.setGroupPair(layers[rule["a"]],layers[rule["b"]],True,rule["gap_m"]/self.metre,rule["footprints"],rule["planar"])
                # Validate and report the same attached, final population that
                # viewport/output consume, after the complete graph exists.
                obj.refreshAll()
                for layer,spec,mask in zip(layers,plan["layers"],compiled):
                    rows=layer.placements(layer.validSources())
                    expected=spec["count"] if spec.get("settings",{}).get("enabled",True) else 0
                    require(spec["underfill"] == "allow" or len(rows) == expected, "Layer underfilled and policy is reject", "GEOMETRY_CONSTRAINT")
                    for ordinal,row in enumerate(rows):
                        position=point(row[0].row4)
                        require(contains(mask["original_m"],[position[0]*self.metre,position[1]*self.metre],mask["footprint_m"]+mask["clearance_m"]), "Final source footprint crosses its approved region", "GEOMETRY_CONSTRAINT")
                        require(not any(contains(poly,[position[0]*self.metre,position[1]*self.metre]) for poly in mask.get("validation_exclusions_m",[])),"Final source footprint intersects an excluded region","GEOMETRY_CONSTRAINT")
                        matrix=max_to_column_matrix([point(row[0][i]) for i in range(4)],self.metre)
                        transform_rows.append([matrix,int(row[1])])
                        candidate=str(row[2]) if len(row)>=3 else "ordinal_"+str(ordinal)
                        layout_instances.append({"instance_id":str(layer.layerID)+":"+candidate,"layer_id":str(layer.layerID),"set_id":str(layer.layerID),"source_id":spec["sources"][int(row[1])-1]["source_id"],"source_index":int(row[1]),"transform":matrix})
                    metric={"name":spec["name"],"layer_id":str(layer.layerID),"requested":spec["count"],"effective_requested":expected,"emitted":len(rows),"underfilled":len(rows)<expected}
                    state=layer.cacheSnapshot()
                    require(not str(state[3]), "Preview generation failed: "+str(state[3]), "GENERATION_FAILED")
                    require(expected==0 or int(state[4]) == metric["emitted"], "Preview count differs from validated generation", "GENERATION_FAILED")
                    mode=plan.get("display",{}).get("mode","proxy")
                    metric["displayed_samples"]=int(state[1]) if expected and spec.get("settings",{}).get("visible",True) else 0
                    metric["displayed_instances"]=metric["displayed_samples"] if mode!="point_cloud" else None
                    metrics.append(metric)
                self.checkpoint("preview")
                for old in self.masks.get(cid,[]):
                    require(rt.isValidNode(old), "Owned mask changed", "STALE_CONTEXT")
                    rt.delete(old)
                self.checkpoint("replace")
                rt.setUserProp(obj,"CyrusAutomationOwner",cid)
                rt.setUserProp(obj,"CyrusAutomationGeneration",gid)
                self.controllers[cid]=obj
                self.masks[cid]=new_masks
                if plan["schema_version"]=="2.0":obj.updateMode=1 if plan["display"]["update_mode"]=="manual" else 2
                result={"controller_id":cid,"generation_id":gid,"layers":metrics,"emitted":sum(m["emitted"] for m in metrics),"requested":sum(m["requested"] for m in metrics),"transform_digest":digest(transform_rows),"display_mode":"proxy_boxes","group_policy":int(obj.groupPolicy),"ui_version":str(obj.uiVersion()),"plan_schema":plan["schema_version"],"undo_label":undo_label,"constraint_check":"all emitted footprint circles inside approved regions"}
                if plan["schema_version"]=="2.0":result["display_mode"]=plan["display"]["mode"]
                self.layouts[cid]={"layout_schema":"cyrus.layout/1.0","controller_id":cid,"generation_id":gid,"transform_digest":result["transform_digest"],"identity_scope":"this generation; refinement creates new population IDs","instances":layout_instances}
                self.checkpoint("publish")
            except Exception as exc:
                failure=exc
                # Catch inside all pymxs contexts. In Max 2027 an exception
                # crossing redraw(False) leaks a redraw-disable reference.
                # Max 2027 can crash in pymxs' exception_handle when a detached
                # scripted layer was configured inside the hold. Finish the Python
                # context first, then invoke the same checked Undo as the local UI.
        if failure:
            names=list(rt.theHold.GetUndoNames())
            require(names and str(names[0]) == undo_label, "Failed transaction is not at the top of Undo; recovery was stopped", "ROLLBACK_FAILED")
            pymxs.run_undo()
            self.controllers,self.masks,self.layouts=old_controllers,old_masks,old_layouts
            for old in self.controllers.values():
                if rt.isValidNode(old):
                    old.setLayerTransfer(False)
            recovered=self.fingerprint() == before and all(not rt.isValidNode(n) for n in created)
            if not recovered:
                raise Fault("ROLLBACK_FAILED", "Generation failed and recovery could not be verified; stop and inspect locally", primary=str(failure))
            if isinstance(failure,Fault):
                raise Fault(failure.code,failure.message,rollback="verified")
            raise Fault("GENERATION_FAILED", str(failure)[:500], rollback="verified")
        # Preserve artist selection; no new controller is selected implicitly.
        if selected:
            rt.select(rt.Array(*(n for n in selected if rt.isValidNode(n))))
        else:
            rt.clearSelection()
        rt.redrawViews()
        return result

    def diagnostics(self):
        self.assert_main()
        result=[]
        for cid,obj in self.controllers.items():
            if rt.isValidNode(obj):
                for i,layer in enumerate(list(obj.layerObjects) or [obj]):
                    state=layer.cacheSnapshot()
                    result.append({"controller_id":cid,"layer":i,"builds":int(state[5]),"last_build_ms":float(state[6]),"requested_cached":int(state[7]),"generated":int(state[4]),"displayed":int(state[1]),"dirty":bool(state[2]),"error":str(state[3])})
        return result

    def viewport_id(self):
        self.assert_main()
        return "viewport_"+str(rt.viewport.activeViewport)

    def retained_diagnostics(self):
        self.assert_main()
        owners=[]
        process=None
        for cid,obj in self.controllers.items():
            owner=rt.CyrusPointOwner(obj) if rt.isValidNode(obj) else None
            if not owner or not rt.isValidNode(owner):
                owners.append({"controller_id":cid,"available":False,"reason":"No retained Point Cloud or Mesh owner; proxy preview uses its own path"})
                continue
            stats=rt.cyrusRetainedStats(owner)
            mesh=rt.cyrusRetainedMeshStats(owner)
            owners.append({"controller_id":cid,"available":True,"preview_entries":int(stats[0]),"groups":int(stats[1]),
                           "revision":int(stats[2]),"prepares":int(stats[3]),"node_updates":int(stats[4]),
                           "state":("preparing","ready","failed")[int(stats[11])],
                           "fingerprints_digest":hashlib.sha256(str(stats[12]).encode()).hexdigest(),
                           "mesh_faces_reported":int(mesh[0]),"mesh_instances":int(mesh[1]),"source_faces":int(mesh[2]),"mesh_reserved_bytes":int(mesh[3])})
            process={"uploads":int(stats[5]),"upload_bytes":int(stats[6]),"draw_callbacks":int(stats[7]),"failures":int(stats[8]),
                     "live_items":int(stats[9]),"reserved_bytes":int(stats[10]),"mesh_reserved_bytes":int(mesh[4])}
        return {"owners":owners,"process_totals":process,"semantics":"Owner counters and shared process totals; draw callbacks are not presented frames, reservations are not measured VRAM"}

    def capture(self):
        self.assert_main()
        require(not rt.isSceneRedrawDisabled(),"Max viewport redraw is suspended; a fresh capture is unavailable","HOST_BUSY")
        rt.completeRedraw()
        bitmap=rt.gw.getViewportDib()
        # Capture uses a plugin-owned temporary path; callers cannot choose a path.
        import tempfile
        with tempfile.TemporaryDirectory(prefix="cyrus-view-") as folder:
            path=Path(folder)/"viewport.png"
            try:
                bitmap.filename=str(path)
                rt.save(bitmap)
            finally:
                rt.close(bitmap)
            image=QtGui.QImage(str(path))
            require(not image.isNull(), "Viewport capture was unavailable", "HOST_ERROR")
            if max(image.width(),image.height())>1536:
                image=image.scaled(1536,1536,QtCore.Qt.KeepAspectRatio,QtCore.Qt.SmoothTransformation)
            while True:
                data=QtCore.QByteArray()
                buffer=QtCore.QBuffer(data)
                buffer.open(QtCore.QIODevice.WriteOnly)
                image.save(buffer,"PNG")
                raw=bytes(data)
                if len(base64.b64encode(raw))<=2*1024*1024:
                    break
                require(min(image.width(),image.height())>64,"Viewport image exceeds its encoded byte budget","BUDGET_EXCEEDED")
                image=image.scaled(int(image.width()*.8),int(image.height()*.8),QtCore.Qt.KeepAspectRatio,QtCore.Qt.SmoothTransformation)
        tm=rt.viewport.getTM()
        return {"image_base64":base64.b64encode(raw).decode(),"mime_type":"image/png","width":image.width(),"height":image.height(),"camera_world_to_view":max_to_column_matrix([point(tm[i]) for i in range(4)],self.metre),"view_type":str(rt.viewport.getType()),"fov_degrees":float(rt.getViewFOV()),"display":str(rt.viewport.getRenderLevel()),"color":"viewport display RGB; no radiometric comparison implied"}

    def undo(self, label):
        self.assert_main()
        names=list(rt.theHold.GetUndoNames())
        require(names and str(names[0]) == label, "A different edit is at the top of Max's Undo history", "STALE_CONTEXT")
        pymxs.run_undo()
        self.controllers,self.masks={},{}
        rt.redrawViews()
