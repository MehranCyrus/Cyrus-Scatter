"""3ds Max adapter. Import and call exclusively on Max's UI thread."""
import base64
import math
import hashlib
from copy import deepcopy
import os
import threading
import ctypes
from ctypes import wintypes
from collections import Counter
from pathlib import Path
import pymxs
from pymxs import runtime as rt
from PySide6 import QtCore, QtGui, QtWidgets

from .contracts import Fault, decode, digest, require
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
        self.undo_checkpoint=None
        self.scene_nodes={}
        self.recipe_reader=None
        self.preset_reader=None
        self.preset_collection=[]
        self.preset_page=1
        self.preset_counts=None
        self.recipe_collection=[]
        self.recipe_page=1
        self.recipe_counts=None
        self.prepared_sources=None
        self.installed_source_links={}
        self.installed_source_index=None
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

    def source_asset_adapter(self):
        if self.prepared_sources is None:
            from .source_assets_host import PreparedSources
            self.prepared_sources=PreparedSources(self)
        return self.prepared_sources

    def begin_source_package(self,directory):return self.source_asset_adapter().begin(directory)
    def poll_source_package(self):return self.source_asset_adapter().poll()
    def use_source_assets(self,proposal):return self.source_asset_adapter().use(proposal)
    def release_source_package(self):
        if self.prepared_sources is not None:self.prepared_sources.release()

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
                "recipe_catalog_api":self.recipe_catalog_version(),
                "source_measurement_api":self.source_measurement_version(),
                "prepared_source_use_api":1 if self.source_asset_adapter().supported() else None,
                "prepared_source_cohort_api":1 if self.source_asset_adapter().cohort_supported() else None,
                "preset_catalog_api":self.preset_catalog_version(),
                "identity_semantics":"Module-file SHA-256 cached on first inspection; script payload fingerprint supplied by the loaded script (excluding its fingerprint line). Neither is a memory-image attestation."}

    def recipe_catalog_version(self):
        self.assert_main()
        probe=getattr(rt,"cyrusRecipeCatalogVersion",None)
        return int(probe()) if probe is not None else None

    def source_measurement_version(self):
        self.assert_main()
        probe=getattr(rt,"cyrusSourceMeasurementVersion",None)
        return int(probe()) if probe is not None else None

    def has_native_source(self,node):
        return str(rt.classOf(node.baseObject)).lower()=="editable_mesh" and self.source_measurement_version()==1

    def source_descriptor(self,node,faces_limit=2000000,vertices_limit=1000000):
        from .source_metadata import decode
        self.assert_main();self.assert_mesh_input(node)
        require(self.has_native_source(node),"Source measurements require a baked Editable Mesh and matching native source API 1","UNSUPPORTED_CAPABILITY")
        counts=rt.getPolygonCount(node)
        require(0<int(counts[0])<=faces_limit and 0<int(counts[1])<=vertices_limit,"Native source measurements exceed their aggregate geometry budget","BUDGET_EXCEEDED")
        try:
            raw=rt.cyrusSourceMeasurement(node,self.metre,faces_limit,vertices_limit)
            require(len(raw)==11,"Native source metadata shape differs","HOST_ERROR")
            values=[int(raw[0]),int(raw[1])]
            for index in range(2,6):
                require(len(raw[index])==3,"Native source bounds shape differs","HOST_ERROR")
                values.append([float(raw[index][j]) for j in range(3)])
            values.extend([float(raw[6]),float(raw[7]),str(raw[8]),str(raw[9]),str(raw[10])])
            return decode(values)
        except RuntimeError as exc:
            raise Fault("GEOMETRY_CONSTRAINT","Native baked-source inspection failed. Check finite geometry, indices and invertible transforms.") from exc

    def start_recipe_catalog(self,kind,root=None):
        self.assert_main()
        require(int(rt.maxVersion()[0])==29000 and self.recipe_catalog_version()==1,
                "Recipe discovery requires the matching Max 2027 native catalog API build","UNSUPPORTED_CAPABILITY")
        require(self.recipe_reader is None,"Revoke the previous recipe reader first","HOST_BUSY")
        require(kind in ("personal_recipes","custom_recipes"),"Unsupported recipe folder kind")
        if kind=="personal_recipes":root=str(rt.CyrusRecipeDirectory())
        require(type(root) is str and len(root)<=240 and Path(root).is_absolute() and not any(ord(c)<32 for c in root),
                "Choose a short absolute local recipe folder")
        kernel=ctypes.WinDLL("kernel32")
        kernel.GetDriveTypeW.argtypes=[wintypes.LPCWSTR];kernel.GetDriveTypeW.restype=wintypes.UINT
        require(kernel.GetDriveTypeW(Path(root).anchor) in (2,3),"Choose a fixed or removable local drive; network folders are not shared","UNSUPPORTED_CAPABILITY")
        try:self.recipe_reader=int(rt.cyrusRecipeCatalogOpen(root))
        except RuntimeError as exc:
            raise Fault("CATALOG_UNAVAILABLE","The recipe folder could not be opened, or readers are still stopping. Review the local folder and retry when idle.") from exc
        self.recipe_collection=[];self.recipe_page=1;self.recipe_counts=None

    def stop_recipe_catalog(self):
        self.assert_main()
        handle=self.recipe_reader;self.recipe_reader=None
        self.recipe_collection=[];self.recipe_page=1;self.recipe_counts=None
        if handle is not None:
            # Close revokes only this handle; running workers retire asynchronously.
            # Unknown/already-closed handles cannot address another owner.
            try:rt.cyrusRecipeCatalogClose(handle)
            except RuntimeError:pass

    def poll_recipe_catalog(self):
        from . import recipes
        self.assert_main()
        require(self.recipe_reader is not None,"No local recipe reader","UNKNOWN_REFERENCE")
        try:
            reader=rt.execute(recipes.HOST_READER)
            raw=reader(self.recipe_reader,self.recipe_page)
            require(len(raw)==8,"Native recipe metadata header differs","HOST_ERROR")
            result={"state":str(raw[0]),"scanned":int(raw[1]),"entry_count":int(raw[2]),"invalid":int(raw[3]),
                    "limited":bool(raw[4]),"has_error":bool(raw[5])}
            recipes.progress(result)
            if result["state"]!="complete" or result["has_error"]:return result
            counts={key:result[key] for key in ("scanned","entry_count","invalid","limited")}
            require(self.recipe_counts in (None,counts),"Recipe scan changed while freezing metadata","STALE_CONTEXT")
            self.recipe_counts=counts
            require(len(raw[7])<=128,"Native recipe page exceeds its bound","BUDGET_EXCEEDED")
            for i in range(len(raw[7])):
                row=raw[7][i]
                require(len(row)==18,"Native recipe row differs","HOST_ERROR")
                path=str(row[0]);require(len(path)<=1024,"Recipe path exceeds its private bound","BUDGET_EXCEEDED")
                data=dict(zip(recipes.ENTRY_FIELDS,[digest({"path":path,"sha256":str(row[11])}),str(row[1]),str(row[2]),str(row[3]),
                    [str(row[4][j]) for j in range(len(row[4]))],str(row[5]),int(row[6]),int(row[7]),int(row[8]),
                    [str(row[9][j]) for j in range(len(row[9]))],[str(row[10][j]) for j in range(len(row[10]))],str(row[11]),
                    bool(row[12]),bool(row[13]),int(row[14]),str(row[15]),str(row[16]),[str(row[17][j]) for j in range(len(row[17]))]]))
                self.recipe_collection.append(data)
            require(len(self.recipe_collection)<=256,"Recipe snapshot exceeds its entry bound","BUDGET_EXCEEDED")
            if self.recipe_page<int(raw[6]):
                self.recipe_page+=1
                # No partial entry references escape while freezing subsequent pages.
                return {**result,"state":"scanning"}
            return {**result,"entries":deepcopy(self.recipe_collection)}
        except RuntimeError as exc:
            raise Fault("CATALOG_UNAVAILABLE","The native recipe reader is unavailable. Review and refresh locally.") from exc

    def preset_catalog_version(self):
        try:return int(rt.cyrusPresetCatalogVersion())
        except (AttributeError,RuntimeError,TypeError,ValueError):return None

    def start_preset_catalog(self,kind,root=None):
        self.assert_main()
        require(int(rt.maxVersion()[0])==29000 and self.preset_catalog_version()==1,"Settings preset discovery requires the matching Max 2027 native catalog API","UNSUPPORTED_CAPABILITY")
        require(self.preset_reader is None,"Revoke the previous settings preset reader first","HOST_BUSY")
        require(kind in ("personal_presets","custom_presets"),"Unsupported settings preset folder kind")
        if kind=="personal_presets":root=str(rt.CyrusPresetDirectory())
        require(type(root) is str and len(root)<=240 and Path(root).is_absolute() and not any(ord(c)<32 for c in root),"Choose a short absolute local settings preset folder")
        kernel=ctypes.WinDLL("kernel32");kernel.GetDriveTypeW.argtypes=[wintypes.LPCWSTR];kernel.GetDriveTypeW.restype=wintypes.UINT
        require(kernel.GetDriveTypeW(Path(root).anchor) in (2,3),"Choose a fixed or removable local drive; network folders are not shared","UNSUPPORTED_CAPABILITY")
        try:self.preset_reader=int(rt.cyrusPresetCatalogOpen(root))
        except RuntimeError as exc:raise Fault("CATALOG_UNAVAILABLE","Settings preset folder is unavailable or readers are still stopping. Review locally and refresh.") from exc
        self.preset_collection=[];self.preset_page=1;self.preset_counts=None

    def stop_preset_catalog(self):
        self.assert_main();handle=self.preset_reader;self.preset_reader=None
        self.preset_collection=[];self.preset_page=1;self.preset_counts=None
        if handle is not None:
            try:rt.cyrusPresetCatalogClose(handle)
            except RuntimeError:pass

    def poll_preset_catalog(self):
        from . import presets
        self.assert_main();require(self.preset_reader is not None,"No settings preset reader","UNKNOWN_REFERENCE")
        try:result=decode(str(rt.cyrusPresetCatalogPage(self.preset_reader,self.preset_page)).encode(),128*1024)
        except RuntimeError as exc:raise Fault("CATALOG_UNAVAILABLE","Settings preset reader unavailable; refresh locally") from exc
        counts=presets.progress(result)
        if result["state"]!="complete" or result["has_error"]:return result
        require(self.preset_counts in (None,counts),"Settings preset scan changed while freezing","STALE_CONTEXT")
        self.preset_counts=counts;self.preset_collection.extend(result["entries"])
        require(len(self.preset_collection)<=512,"Settings preset snapshot exceeds its entry bound","BUDGET_EXCEEDED")
        if self.preset_page<result["pages"]:
            self.preset_page+=1;return {**result,"state":"scanning","entries":[]}
        return {**result,"entries":deepcopy(self.preset_collection)}

    def inspect_preset_entry(self,key):
        self.assert_main();require(self.preset_reader is not None,"Settings preset reader was revoked","STALE_CONTEXT")
        try:return decode(str(rt.cyrusPresetCatalogInspect(self.preset_reader,key)).encode(),160*1024)
        except RuntimeError as exc:raise Fault("STALE_CONTEXT","Settings preset snapshot unavailable; refresh locally") from exc

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
        require(str(obj.calculationModel())=="CyrusUnified2" and getattr(obj,"procPublicationInfo",None) is not None,
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

    def assert_mesh_input(self, node):
        require(rt.isValidNode(node), "An enrolled object was deleted", "STALE_CONTEXT")
        require(str(rt.classOf(node.baseObject)).lower() in {"editable_mesh","editable_poly","plane","box","cone","cylinder","sphere","geosphere","torus","teapot","pyramid","tube","chamferbox","chamfercyl","hedra"},
                "Use a baked Editable Mesh/Poly or a supported simple primitive; procedural/proxy sources require separate qualification","UNSUPPORTED_CAPABILITY")
        self.assert_static(node)

    def mesh(self, node, world=True):
        self.assert_mesh_input(node)
        counts = rt.getPolygonCount(node)
        require(int(counts[0]) <= 10000 and int(counts[1]) <= 12000, "Design inspection is limited to 10,000 faces / 12,000 vertices across its inputs", "BUDGET_EXCEEDED")
        mesh = rt.snapshotAsMesh(node)
        # snapshotAsMesh already contains the evaluated world-space transform.
        # Match native meshOf(false) by removing only the node transform, retaining
        # object offsets. Applying objectTransform again double-transforms assets.
        try:
            require(mesh.numfaces <= 10000 and 0 < mesh.numverts <= 12000 and mesh.numfaces > 0, "Unsupported evaluated mesh size", "BUDGET_EXCEEDED")
            tm = rt.matrix3(1) if world else rt.inverse(node.transform)
            vertices = [point(rt.getVert(mesh,i+1)*tm) for i in range(mesh.numverts)]
            faces = [tuple(int(v)-1 for v in point(rt.getFace(mesh,i+1))) for i in range(mesh.numfaces)]
        finally:
            rt.delete(mesh)
        require(all(math.isfinite(x) and abs(x)*self.metre<=1e6 for v in vertices for x in v), "Mesh has non-finite or unsupported coordinates", "GEOMETRY_CONSTRAINT")
        return vertices, faces

    def polygon(self, node):
        require(rt.isValidNode(node), "Region is missing", "STALE_CONTEXT")
        self.assert_static(node)
        require(rt.numSplines(node) == 1 and rt.isClosed(node,1), "Region must be one closed spline", "GEOMETRY_CONSTRAINT")
        count = rt.numKnots(node,1)
        require(3 <= count <= 64, "Region needs 3â€“64 knots", "GEOMETRY_CONSTRAINT")
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
        require(1 <= len(sources) <= 3 and len(regions) <= 3 and len(excluded) <= 3, "Enroll 1–3 sources and at most three planting/protected regions")
        all_nodes=[site,*sources,*regions,*excluded]
        require(all(rt.isValidNode(node) for node in all_nodes), "A design input is missing", "STALE_CONTEXT")
        handles=[int(rt.getHandleByAnim(n)) for n in all_nodes]
        require(len(handles) == len(set(handles)), "Site, sources and regions must be distinct objects")
        for node in [site,*sources]:self.assert_mesh_input(node)
        native_sources=[self.has_native_source(node) for node in sources]
        counts=[rt.getPolygonCount(n) for n in [site,*[node for node,native in zip(sources,native_sources) if not native]]]
        require(sum(int(c[0]) for c in counts)<=10000 and sum(int(c[1]) for c in counts)<=12000,
                "Design scope exceeds the aggregate 10,000-face / 12,000-vertex inspection budget","BUDGET_EXCEEDED")
        verts,faces=self.mesh(site)
        total_faces,total_vertices=len(faces),len(verts)
        site_poly,z=self.site_polygon(verts,faces)
        data={"site":{"label":self.node_label(site),"polygon_m":site_poly,"z_m":z,"area_m2":area(site_poly)},"sources":[],"regions":[],"excluded":[]}
        nodes={uid("site"):site}
        native_faces=native_vertices=0
        for source,native in zip(sources,native_sources):
            if native:
                metadata=self.source_descriptor(source,2000000-native_faces,1000000-native_vertices)
                native_faces+=metadata["triangles"];native_vertices+=metadata["vertices"]
                geometry=metadata["source_geometry"];sid=uid("source")
                require(geometry["radius_xy_from_pivot_m"]>0,"Source has no measurable footprint","GEOMETRY_CONSTRAINT")
                data["sources"].append({"source_id":sid,"label":self.node_label(source),"radius_m":geometry["radius_xy_from_pivot_m"],
                    "bounding_radius_m":geometry["radius_xyz_from_pivot_m"],"height_m":geometry["height_m"],"triangles":metadata["triangles"],
                    "measurement_method":"native_baked_mesh","source_geometry_sha256":geometry["source_geometry_sha256"],"geometry_fingerprint_schema":metadata["geometry_fingerprint_schema"]})
                nodes[sid]=source
                continue
            v,f=self.mesh(source,False)
            total_faces+=len(f);total_vertices+=len(v)
            require(total_faces<=10000 and total_vertices<=12000,"Evaluated design meshes exceed the aggregate inspection budget","BUDGET_EXCEEDED")
            sid=uid("source")
            radius=max(math.hypot(p[0],p[1]) for p in v)*self.metre
            require(math.isfinite(radius) and radius > 0, "Source has no measurable footprint", "GEOMETRY_CONSTRAINT")
            data["sources"].append({"source_id":sid,"label":self.node_label(source),"radius_m":radius,"bounding_radius_m":max(math.sqrt(sum(x*x for x in p)) for p in v)*self.metre,"height_m":(max(p[2] for p in v)-min(p[2] for p in v))*self.metre,"triangles":len(f)})
            nodes[sid]=source
        for name,sequence in (("regions",regions),("excluded",excluded)):
            for region in sequence:
                poly=self.polygon(region)
                require(all(contains(site_poly,p) for p in poly), "Region extends outside the site", "GEOMETRY_CONSTRAINT")
                rid=uid("region")
                data[name].append({"region_id":rid,"label":self.node_label(region),"polygon_m":poly,"area_m2":area(poly)})
                nodes[rid]=region
        if not regions:
            data["regions"].append({"region_id":uid("region"),"label":"Whole receiving surface",
                                    "polygon_m":site_poly,"area_m2":area(site_poly),"origin":"verified_receiver_polygon"})
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

    def installed_model_catalog(self):
        """Local-only metadata grant; reuse the shipped managed catalog validator.

        It checks every declared scene length and hashes bounded preview files.
        It never merges/evaluates models or exposes content paths to the client.
        """
        import time
        self.assert_main()
        require(int(rt.maxVersion()[0])==29000,"Catalog discovery requires Max 2027","UNSUPPORTED_CAPABILITY")
        started=time.perf_counter()
        self.installed_source_links={};self.installed_source_index=None
        reader=rt.execute(r'''(
            fn CyrusMCPInstalledModelMetadata = (
                if CyrusRecipeScriptDirectory==undefined or CyrusLibraryVersion==undefined do throw "Load the matching Cyrus gallery package first."
                local galleryPath=pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll"
                local assembly=dotNet.loadAssembly galleryPath
                if assembly==undefined do throw "Load the matching Cyrus gallery package first."
                local assemblyName=assembly.GetName()
                if assemblyName.Version.ToString()!=CyrusLibraryVersion() or toLower assembly.Location!=toLower galleryPath do throw "Restart Max with the matching Cyrus gallery package."
                local directory=CyrusRecipeBundledDirectory (CyrusLibraryVersion())
                local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
                catalog.Load directory (CyrusLibraryVersion()) 2027
                if catalog.Count<1 or catalog.Count>104 do throw "Installed catalog exceeds the metadata bound."
                local entries=for i=0 to catalog.Count-1 collect (
                    local entry=catalog.MatchingAt "" "" i
                    #(entry.Id,entry.Name,entry.Category,entry.SceneHash,entry.SceneBytes,entry.ThumbnailHash,entry.ThumbnailBytes)
                )
                #(directory,entries)
            )
            CyrusMCPInstalledModelMetadata
        )''')
        try:
            result=reader();require(len(result)==2,"Installed catalog root metadata differs","HOST_ERROR")
            directory=Path(str(result[0]));raw=result[1]
            require(1<=len(raw)<=104,"Installed catalog exceeds its metadata bound","BUDGET_EXCEEDED")
            rows=[]
            for i in range(len(raw)):
                row=raw[i]
                require(len(row)==7,"Installed catalog metadata differs","HOST_ERROR")
                rows.append(dict(entry_id=str(row[0]),name=str(row[1]),category=str(row[2]),scene_sha256=str(row[3]),
                                 scene_bytes=int(row[4]),thumbnail_sha256=str(row[5]),thumbnail_bytes=int(row[6])))
            from .installed_sources import load,descriptor,unlinked
            catalog=unlinked(directory/"model-catalog.json")
            with catalog.open("rb") as stream:catalog_bytes=stream.read(2*1024**2+1)
            document=decode(catalog_bytes,2*1024**2)
            declared={row["id"]:row for row in document["entries"]}
            require(len(declared)==len(rows) and all(row["entry_id"] in declared and
                    all(row[key]==declared[row["entry_id"]][key] for key in ("name","category","scene_sha256","scene_bytes")) for row in rows),
                    "Installed catalog changed during sharing","STALE_CONTEXT")
            index_sha,links=load(directory,hashlib.sha256(catalog_bytes).hexdigest(),rows)
            self.installed_source_links=links;self.installed_source_index=index_sha
            for row in rows:row["prepared_source"]=descriptor(links.get(row["entry_id"]),index_sha)
        except (RuntimeError,OSError,KeyError,TypeError,ValueError) as exc:
            # Native errors may include private content paths. Keep them local.
            raise Fault("CATALOG_UNAVAILABLE","The installed model catalog could not be validated. Check or repair it in the native Plant models browser.") from exc
        return {"entries":rows,"host_year":2027,"load_duration_ms":(time.perf_counter()-started)*1000}

    def begin_installed_sources(self,entries):
        selections=[]
        from .asset_use import preflight
        for entry in entries:
            link=self.installed_source_links.get(entry["entry_id"])
            require(link and link["status"]=="prepared" and link["scene_sha256"]==entry["scene_sha256"],"Installed source has no matching prepared derivative","UNSUPPORTED_CAPABILITY")
            require(preflight(link["_directory"])[1]==link["package_revision"],"Installed prepared revision changed","STALE_CONTEXT")
            selections.append(dict(directory=link["_directory"],source_node_id=link["source_node_id"],asset_ref=entry["asset_ref"],entry_id=entry["entry_id"]))
        self.source_asset_adapter().begin_many(selections)

    def inspect_scene(self, selected):
        from .scene import MAX_OBJECTS
        self.assert_main()
        require(not self.busy(), "Max is busy; connect scene inspection when idle", "HOST_BUSY")
        require(int(rt.maxVersion()[0])==29000, "Scene inspection supports Max 2027 only", "UNSUPPORTED_CAPABILITY")
        require(type(selected) is list and 1 <= len(selected) <= MAX_OBJECTS,
                "Share 1–32 selected objects", "BUDGET_EXCEEDED")
        require(all(rt.isValidNode(node) for node in selected), "A selected object is missing", "STALE_CONTEXT")
        handles=[int(rt.getHandleByAnim(node)) for node in selected]
        require(len(set(handles))==len(handles), "Duplicate scene objects")
        previous=self.scene_nodes
        self.scene_nodes={uid("object"):node for node in selected}
        try:
            snapshot=self.scene_snapshot()
        except Exception:
            self.scene_nodes=previous
            raise
        self.nodes,self.controllers,self.masks,self.layouts={},{},{},{}
        return snapshot

    def scene_snapshot(self):
        self.assert_main()
        from .scene import HOST_METADATA, MAX_OBJECTS
        require(1 <= len(self.scene_nodes) <= MAX_OBJECTS, "No bounded scene selection", "UNKNOWN_REFERENCE")
        if getattr(self,"_scene_metadata",None) is None:
            self._scene_metadata=rt.execute(HOST_METADATA)
        parents={int(rt.getHandleByAnim(node)):oid for oid,node in self.scene_nodes.items() if rt.isValidNode(node)}
        cards=[]
        for oid,node in self.scene_nodes.items():
            if not rt.isValidNode(node):
                cards.append({"object_id":oid,"status":"missing","geometry":"unmeasured"})
                continue
            value=self._scene_metadata(node)
            parent=int(value[6])
            cards.append({"object_id":oid,"status":"available","label":str(value[0]),"label_truncated":bool(value[1]),
                          "object_type":str(value[2]),"superclass":str(value[3]),"hidden":bool(value[4]),"frozen":bool(value[5]),
                          "parent_object_id":parents.get(parent),"parent_outside_scope":bool(parent and parent not in parents),
                          "geometry":"unmeasured"})
        metre=1.0/float(rt.units.decodeValue("1m"))
        require(math.isfinite(metre) and metre>0, "Invalid scene units", "GEOMETRY_CONSTRAINT")
        result={"objects":cards,"metres_per_system_unit":metre,
                "inspection":"Selected object metadata only; no geometry evaluation or scene traversal.",
                "omissions":["Unselected objects and neighbors", "Geometry, bounds, materials and asset dependencies", "Semantic role inference"],
                "geometry_validity":"unmeasured; a matching metadata revision does not prove unchanged geometry"}
        from .contracts import canonical
        require(len(canonical(result).encode())<=32768, "Scene metadata exceeds its byte budget", "BUDGET_EXCEEDED")
        return result

    def node_label(self, node):
        from .scene import HOST_METADATA
        if getattr(self,"_scene_metadata",None) is None:self._scene_metadata=rt.execute(HOST_METADATA)
        return str(self._scene_metadata(node)[0])

    def scene_selection_ids(self, selected):
        self.assert_main()
        from .scene import MAX_OBJECTS
        require(type(selected) is list and 1 <= len(selected) <= MAX_OBJECTS, "Select 1–32 shared objects", "BUDGET_EXCEEDED")
        result=[]
        for node in selected:
            oid=next((key for key,known in self.scene_nodes.items() if rt.isValidNode(known) and known==node),None)
            require(oid is not None, "Selection contains an object outside this shared task", "UNKNOWN_REFERENCE")
            require(oid not in result, "Duplicate selection")
            result.append(oid)
        return result

    def clear_scene_selection(self):
        self.scene_nodes.clear()

    def extend_scene(self, selected):
        from .scene import MAX_OBJECTS
        self.assert_main()
        require(not self.busy(), "Max is busy; share objects when idle", "HOST_BUSY")
        require(type(selected) is list and 1<=len(selected)<=MAX_OBJECTS, "Select 1–32 objects", "BUDGET_EXCEEDED")
        require(all(rt.isValidNode(node) for node in selected), "A selected object is missing", "STALE_CONTEXT")
        require(len({int(rt.getHandleByAnim(node)) for node in selected})==len(selected), "Duplicate scene objects")
        before=self.scene_nodes
        updated=dict(before)
        for node in selected:
            if not any(rt.isValidNode(known) and known==node for known in updated.values()):
                require(len(updated)<MAX_OBJECTS, "This task already shares 32 references, including missing slots", "BUDGET_EXCEEDED")
                updated[uid("object")]=node
        self.scene_nodes=updated
        try:return self.scene_snapshot()
        except Exception:
            self.scene_nodes=before
            raise

    def connect_task_inputs(self, bindings):
        """Local grant only; roles are resolved to the same live references."""
        self.assert_main()
        require(not self.busy(), "Max is busy; input enrollment was not started", "HOST_BUSY")
        ids=[*bindings["receiver"],*bindings["source"],*bindings["boundary"],*bindings["exclusion"]]
        require(len(ids)==len(set(ids)), "Receiver, sources, boundaries and exclusions require distinct objects", "UNSUPPORTED_CAPABILITY")
        require(all(oid in self.scene_nodes and rt.isValidNode(self.scene_nodes[oid]) for oid in ids), "A task input is missing", "STALE_CONTEXT")
        before={key:getattr(self,key,None) for key in ("nodes","site","site_z","controllers","masks","layouts","metre","read_only")}
        try:
            snapshot=self.enroll(self.scene_nodes[bindings["receiver"][0]],
                                 [self.scene_nodes[oid] for oid in bindings["source"]],
                                 [self.scene_nodes[oid] for oid in bindings["boundary"]],
                                 [self.scene_nodes[oid] for oid in bindings["exclusion"]])
            for kind,field in (("source","sources"),("boundary","regions"),("exclusion","excluded")):
                for oid,item in zip(bindings[kind],snapshot[field]):item["task_object_id"]=oid
            snapshot["site"]["task_object_id"]=bindings["receiver"][0]
            snapshot["task_bindings"]=bindings
            snapshot["_fingerprint"]=self.fingerprint()
            return snapshot
        except Exception:
            for key,value in before.items():setattr(self,key,value)
            raise

    def highlight_scene(self, object_ids):
        self.assert_main()
        from .scene import references
        references(object_ids)
        nodes=[self.scene_nodes.get(oid) for oid in object_ids]
        require(all(node is not None and rt.isValidNode(node) for node in nodes), "A shared object is missing", "STALE_CONTEXT")
        require(not self.busy(), "Max is busy; selection was not changed", "HOST_BUSY")
        rt.select(rt.Array(*nodes))

    def measure_scene(self, object_ids):
        self.assert_main()
        from .scene import references, source_geometry
        references(object_ids,3)
        require(not self.busy(), "Max is busy; measurements were not started", "HOST_BUSY")
        nodes=[self.scene_nodes.get(oid) for oid in object_ids]
        require(all(node is not None and rt.isValidNode(node) for node in nodes), "A shared object is missing", "UNKNOWN_REFERENCE")
        metre=1.0/float(rt.units.decodeValue("1m"))
        require(math.isfinite(metre) and metre>0, "Invalid scene units", "GEOMETRY_CONSTRAINT")
        self.metre=metre
        # Admission precedes snapshotAsMesh. mesh() independently verifies the
        # supported static class/graph and evaluated limits, then releases it.
        for node in nodes:
            self.assert_mesh_input(node)
        counts=[rt.getPolygonCount(node) for node in nodes]
        require(sum(int(c[0]) for c in counts)<=10000 and sum(int(c[1]) for c in counts)<=12000,
                "Measurements exceed 10,000 faces / 12,000 vertices", "BUDGET_EXCEEDED")
        measured=[];face_count=vertex_count=0
        for oid,node in zip(object_ids,nodes):
            vertices,faces=self.mesh(node)
            face_count+=len(faces);vertex_count+=len(vertices)
            require(face_count<=10000 and vertex_count<=12000, "Evaluated measurements exceed the aggregate mesh budget", "BUDGET_EXCEEDED")
            world=[[x*metre for x in row] for row in vertices]
            low=[min(p[i] for p in world) for i in range(3)]
            high=[max(p[i] for p in world) for i in range(3)]
            identity=digest({"geometry_world":world,"triangles":faces,"metres_per_system_unit":metre})
            try:
                inverse=rt.inverse(node.transform)
                source=source_geometry(vertices,[point(inverse[i]) for i in range(4)],metre)
            except RuntimeError:
                source={"available":False,"reason":"Node transform could not be inverted; source-local geometry is unverified"}
            try:
                polygon,z=self.site_polygon(vertices,faces)
                receiver={"eligible":True,"method":"Verified upward horizontal convex single manifold boundary", "polygon_m":polygon,
                          "area_m2":area(polygon),"z_m":z}
            except Fault as exc:
                receiver={"eligible":False,"code":exc.code,"reason":exc.message}
            measured.append({"object_id":oid,"measurement_id":"measurement_"+digest([identity,source,receiver])[:32],
                             "geometry_world_sha256":identity,"triangles":len(faces),"vertices":len(world),
                             "world_aabb_m":{"minimum":low,"maximum":high,"size":[high[i]-low[i] for i in range(3)]},
                             "method":"Axis-aligned bounds of every evaluated world-space mesh vertex; not a planting area or canopy clearance.",
                             "source_geometry":source,"receiver_geometry":receiver,
                             "validity":"snapshot_only; remeasure after relevant changes; metadata does not certify geometry"})
        return {"measurements":measured,"metres_per_system_unit":metre,"geometry_mutated":False,
                "limits":{"objects":3,"triangles":10000,"vertices":12000},
                "retention":"No geometry or measurement cache retained; roles and brief remain unchanged."}

    def measure_sources(self,object_ids):
        from .source_metadata import MAX_FACES,MAX_VERTICES
        from .scene import references
        self.assert_main();references(object_ids,3)
        require(not self.busy(),"Max is busy; source inspection was not started","HOST_BUSY")
        self.metre=1.0/float(rt.units.decodeValue("1m"))
        nodes=[self.scene_nodes.get(oid) for oid in object_ids]
        require(all(node is not None and rt.isValidNode(node) for node in nodes),"A shared source is missing","UNKNOWN_REFERENCE")
        for node in nodes:self.assert_mesh_input(node);require(self.has_native_source(node),"Source purpose requires baked Editable Mesh and native source API 1","UNSUPPORTED_CAPABILITY")
        counts=[rt.getPolygonCount(node) for node in nodes]
        require(sum(int(c[0]) for c in counts)<=MAX_FACES and sum(int(c[1]) for c in counts)<=MAX_VERTICES,"Source measurements exceed aggregate native admission","BUDGET_EXCEEDED")
        results=[];faces=vertices=0
        for oid,node in zip(object_ids,nodes):
            value=self.source_descriptor(node,MAX_FACES-faces,MAX_VERTICES-vertices)
            faces+=value["triangles"];vertices+=value["vertices"]
            results.append({"object_id":oid,"measurement_id":"measurement_"+digest(value)[:32],**value,
                "method":"Native streaming bounds and pivot radii of every baked mesh vertex; no copied Python vertex/face arrays. Not canopy clearance.",
                "receiver_geometry":{"eligible":False,"reason":"Source-only inspection; receiving topology/area not evaluated"},
                "validity":"snapshot_only; remeasure after relevant changes; material/dependency and asset-unit provenance unchecked"})
        return {"measurements":results,"metres_per_system_unit":self.metre,"geometry_mutated":False,
                "limits":{"objects":3,"triangles":MAX_FACES,"vertices":MAX_VERTICES},"retention":"Scalar metadata only; no geometry cache or renderer/dependency verdict"}

    def controller_state(self, obj):
        from .procedural import read_vector_paint
        keys = list(rt.AminScatterLayerFields)
        def params(layer):
            result={str(k):frozen(rt.getProperty(layer,k)) for k in keys}
            result["layer_id"]=str(layer.layerID)
            result["edit_layer_key"]=int(layer.editLayerKey)
            result["surface_nodes"]=frozen(layer.surfaceNodes)
            result["vector_paint"]=read_vector_paint(layer,rt.cyrusBrushStats,frozen)
            if layer.paintDocument is not None:
                stats=rt.cyrusBrushStats(layer.paintDocument)
                result["paint_revision"]=[int(stats[0]),int(stats[3])]
            return result
        shared={key:frozen(rt.getProperty(obj,rt.Name(key))) for key in ("groupCenters","viewportMode","proxyShape","viewportInstances","viewportFaces","radiusDisplayLimit","radiusDisplayAll")}
        if hasattr(obj,"procRuleScope"):
            from .procedural import RULE_FIELDS
            shared.update({key:frozen(rt.getProperty(obj,rt.Name(key))) for key in RULE_FIELDS})
        return {"root":params(obj),"shared":shared,"surfaceNodes":frozen(obj.surfaceNodes),"names":list(obj.layerNames),"enabled":list(obj.layerEnabled),"visible":list(obj.layerVisible),"layers":[params(layer) for layer in obj.layerObjects],"transform":frozen(obj.transform),"modifiers":[str(rt.classOf(m)) for m in obj.modifiers],"enabled_root":bool(obj.cyrusEnabled),"edit_revision":int(rt.cyrusEditRevision()) if len(obj.modifiers) else 0}

    def configuration(self,cid):
        self.assert_main()
        from .procedural import read_vector_paint
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
            layers.append({"layer_id":str(leaf.layerID),
                           "name":str(obj.layerNames[i]),"count":int(parent.amount),"seed":int(parent.randomSeed),"settings":settings,"assets":assets,
                           "base_variation":{"advanced_axes":bool(parent.advancedAxes),"compact_uniform_scale":[float(parent.scaleMinimum),float(parent.scaleMaximum)],"compact_yaw_degrees":[float(parent.yawMinimum),float(parent.yawMaximum)],"whole_scale":[float(parent.wholeScaleMin),float(parent.wholeScaleMax)],"rotation_z_degrees":[float(parent.rotZMin),float(parent.rotZMax)]},
                           "allocation":{"parent_candidate_budget":int(parent.amount),"count_mode_candidates":int(obj.populationAllocation(leaf)[0]),"population_mode":int(parent.populationMode),"plants_per_m2":float(parent.plantsPerM2)},
                           "paint":read_vector_paint(leaf,rt.cyrusBrushStats,frozen)})
        display=read_settings(obj,DISPLAY_SETTINGS)
        display.update(mode="centres" if obj.groupCenters else {1:"point_cloud",2:"proxy",3:"mesh"}[int(obj.viewportMode)],proxy_shape={1:"box",2:"sphere",3:"pyramid"}[int(obj.proxyShape)],update_mode="manual" if obj.updateMode==1 else "real_time")
        from .procedural import read_procedural
        return {"configuration_schema":"cyrus.configuration/2.0","controller_id":cid,"layers":layers,"display":display,"calculation_model":str(obj.calculationModel()),
                "procedural":read_procedural(obj,self.metre),
                "freshness":"current parameter values only; no generation or geometry certification"}

    def settings_targets(self,controller_id):
        from .destination_settings import TARGET_READER,targets
        self.assert_main();require(not self.busy(),"Read settings targets when Max is idle","HOST_BUSY")
        node=self.controllers.get(controller_id)
        require(node is not None and rt.isValidNode(node),"Scoped controller is unavailable","STALE_CONTEXT")
        try:return targets(frozen(rt.execute(TARGET_READER)(node)),controller_id)
        except RuntimeError as exc:raise Fault("UNSUPPORTED_CAPABILITY","Settings target metadata is unavailable; inspect the current owner graph locally") from exc

    def destination_settings(self,controller_id,layer_id,categories):
        from .destination_settings import HOST_READER,snapshot,request_categories
        self.assert_main();request_categories(categories)
        require(not self.busy(),"Read destination settings when Max is idle","HOST_BUSY")
        node=self.controllers.get(controller_id)
        require(node is not None and rt.isValidNode(node),"Scoped controller is unavailable","STALE_CONTEXT")
        require(int(rt.maxVersion()[0])==29000 and int(rt.cyrusPresetVersion())==3,"Destination settings require the matching Max 2027 native preset schema","UNSUPPORTED_CAPABILITY")
        try:
            reader=rt.execute(HOST_READER)
            return snapshot(frozen(reader(node,layer_id,rt.Array(*categories))),controller_id,layer_id,categories)
        except RuntimeError as exc:
            if "identity is missing or duplicated" in str(exc):
                raise Fault("STALE_CONTEXT","Destination layer identity is missing or duplicated; inspect the current controller") from exc
            raise Fault("UNSUPPORTED_CAPABILITY","Destination settings could not be read within their owner/schema/budget contract; inspect the target locally") from exc

    def fingerprint(self):
        self.assert_main()
        state={"units":float(rt.units.decodeValue("1m")),"nodes":{},"controllers":{},"masks":{}}
        # Design enrollment admits static inputs only. Inspection remains
        # conservatively time-sensitive until its dependencies are qualified.
        if self.read_only:
            state["time"] = str(rt.sliderTime)
        source_nodes=[node for key,node in self.nodes.items() if key.startswith("source_") and rt.isValidNode(node) and self.has_native_source(node)]
        source_counts=[rt.getPolygonCount(node) for node in source_nodes]
        require(sum(int(c[0]) for c in source_counts)<=2000000 and sum(int(c[1]) for c in source_counts)<=1000000,
                "Current sources exceed aggregate native geometry admission","BUDGET_EXCEEDED")
        for key,node in self.nodes.items():
            require(rt.isValidNode(node), "An enrolled object was deleted", "STALE_CONTEXT")
            if key.startswith("source_") and self.has_native_source(node):
                descriptor=self.source_descriptor(node)
                geometry={"native_source_sha256":descriptor["source_geometry"]["source_geometry_sha256"],"fingerprint_schema":descriptor["geometry_fingerprint_schema"]}
            else:geometry=self.polygon(node) if key.startswith("region_") else self.mesh(node,not key.startswith("source_"))
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

    def placement_rows(self, rows):
        """Materialize at most one 500-row native page within the admitted plan budget."""
        self.assert_main()
        count = len(rows)
        require(count <= 2000, "Placement readback exceeds the enrolled candidate budget", "BUDGET_EXCEEDED")
        native = bool(rt.cyrusPlacementIsNative(rows))
        token = rt.cyrusPlacementToken(rows) if native else None
        if not native:
            require(str(rt.classOf(rows)) in ("Array", "ArrayParameter"), "Unsupported placement representation", "UNSUPPORTED_CAPABILITY")
        for offset in range(0, count, 500):
            size = min(500, count-offset)
            page = rt.cyrusPlacementPage(rows, token, offset, size) if native else [rows[i] for i in range(offset, offset+size)]
            require(len(page) == size, "Native placement readback was incomplete", "GENERATION_FAILED")
            # Native placement values have a count but are not pymxs iterable.
            # Even the materialized page is indexed explicitly to avoid silent skips.
            for index in range(size):
                yield offset+index, page[index]

    def recovery_snapshot(self, record, selected):
        """Local review of cached state only; never solves, restores or adopts an owner."""
        self.assert_main()
        require(not self.busy(), "Max is busy; review recovery when it is idle", "HOST_BUSY")
        require(type(selected) is list and len(selected) <= 1, "Select at most one Scatter setup for recovery review")
        evidence = {"scope": "record and optional selected controller only; not a whole-scene audit",
                    "scene_file_sha256": digest([str(rt.maxFilePath), str(rt.maxFileName)]),
                    "metres_per_unit": 1.0 / float(rt.units.decodeValue("1m")),
                    "selected_controller": None,
                    "limitation": "Local retirement preserves the scene. It does not prove absence of other effects, rollback, or source appearance."}
        if not selected:
            evidence["comparison"] = "No controller selected; operation target and its absence are not verified."
            return evidence
        node = selected[0]
        require(rt.isValidNode(node) and str(getattr(node, "calculationModel", lambda: "")()) == "CyrusUnified2",
                "Select one supported Cyrus Scatter controller", "UNSUPPORTED_CAPABILITY")
        require(len(node.layerObjects) <= 32, "Recovery inspection supports at most 32 layers", "BUDGET_EXCEEDED")
        require(len(node.sources)+sum(len(layer.sources) for layer in node.layerObjects) <= 1024,
                "Recovery inspection exceeds its 1,024 source-row budget", "BUDGET_EXCEEDED")
        read = self.recovery_reader()
        expected = record.get("commit_identity") or record.get("result") or record.get("target_identity", {})
        owner, generation, configuration = [str(read(node, key, 2) or "") for key in
                                            ("CyrusAutomationOwner", "CyrusAutomationGeneration", "CyrusAutomationConfiguration")]
        require(all(len(value) <= 96 for value in (owner, generation, configuration)),
                "Recovery identity exceeds its metadata budget", "BUDGET_EXCEEDED")
        if expected.get("controller_id"):
            require(owner == expected["controller_id"], "Selected setup is not this operation's recorded owner", "UNKNOWN_REFERENCE")
        current = {"node_handle": int(rt.getHandleByAnim(node)), "owner_id": owner, "generation_id": generation,
                   "recorded_identity_basis": "commit" if record.get("commit_identity") or record.get("result") else
                                              "approved_base_before_execution" if record.get("target_identity") else "unrecorded",
                   "configuration_id": configuration,
                   "authored_state_sha256": digest(self.recovery_state(node, read)),
                   "transform_sha256": digest(read(node, "transform")),
                   "recorded_generation_matches": bool(expected.get("generation_id")) and generation == expected["generation_id"],
                   "recorded_configuration_matches": (configuration == expected["configuration_id"]) if expected.get("configuration_id") else None}
        from .publication import manifest
        try:
            published = manifest(read(node, "publication", 3))
            current.update(publication_id=published["publication_id"], accepted_count=published["count"],
                           script_payload_sha256=published["script_payload_sha256"],
                           published_input_sha256=published["input_key_sha256"],
                           cached_pending_flags=[bool(layer.cacheSnapshot()[2]) for layer in node.layerObjects])
            current["recorded_count_matches"] = record.get("result", {}).get("emitted") == published["count"]
        except RuntimeError:
            current["publication_status"] = "unavailable; cached population could not be inspected"
        evidence["selected_controller"] = current
        evidence["comparison"] = "Cached identity/count comparison only; transforms, constraints and source appearance are not recertified."
        return evidence

    def recovery_reader(self):
        """One shared admission budget for this complete local evidence snapshot."""
        self.assert_main()
        from .recovery import HOST_READER, MAX_CELLS, MAX_TEXT_UNITS
        if getattr(self, "_recovery_reader", None) is None:
            self._recovery_reader = rt.execute(HOST_READER)
        budget = rt.Array(MAX_CELLS, MAX_TEXT_UNITS)
        def read(owner, key, mode=1):
            try:
                return frozen(self._recovery_reader(owner, rt.Name(key), budget, mode))
            except RuntimeError as exc:
                if "Cyrus recovery budget" in str(exc):
                    raise Fault("BUDGET_EXCEEDED", "Selected recovery metadata exceeds its aggregate cell/text/depth budget") from exc
                raise
        return read

    def recovery_state(self, obj, read):
        """Bound authored parameters/references without inspecting their geometry."""
        keys = rt.AminScatterLayerFields
        require(len(keys) <= 512, "Recovery field registry exceeds its budget", "BUDGET_EXCEEDED")
        def params(owner):
            state = {str(key): read(owner, key) for key in keys}
            state.update(layer_id=read(owner, "layerID"), edit_layer_key=read(owner, "editLayerKey"),
                         surface_nodes=read(owner, "surfaceNodes"))
            read(owner, "paintAreas")  # Admit the reference array before iterating it.
            areas = owner.paintAreas
            require(len(areas) <= 128, "Recovery Paint Areas exceed the read budget", "BUDGET_EXCEEDED")
            state["paint_areas"] = [{key: read(area, key) for key in
                                      ("layerID", "paintSetName", "areaTarget", "paintSetEnabled", "paintDensity", "paintDocument")}
                                     for area in areas]
            state["paint_revisions"] = [frozen(rt.cyrusBrushStats(area.paintDocument)) if area.paintDocument is not None else None for area in areas]
            return state
        shared = ["groupCenters", "viewportMode", "proxyShape", "viewportInstances", "viewportFaces",
                  "radiusDisplayLimit", "radiusDisplayAll", "transform", "modifiers", "cyrusEnabled",
                  "layerNames", "layerEnabled", "layerVisible"]
        from .procedural import RULE_FIELDS
        shared.extend(RULE_FIELDS)
        return {"root": params(obj), "shared": {key: read(obj, key) for key in shared},
                "layers": [params(layer) for layer in obj.layerObjects]}

    def generate(self, plan, compiled):
        try:
            self.assert_main()
            # Deny before clearing recipes, creating nodes, or opening the Undo hold.
            license_check=getattr(rt,'cyrusLicenseAllows',None)
            require(license_check is not None and bool(license_check()),
                    "Cyrus authoring requires an active team license; existing scenes remain renderable",
                    "LICENSE_REQUIRED")
            require(not self.busy(), "Host is busy", "HOST_BUSY")
            require(not rt.isSceneRedrawDisabled(),"Max viewport redraw is suspended; restore it locally before generating","HOST_BUSY")
            before=self.fingerprint()
            old_controllers,old_masks,old_layouts=dict(self.controllers),dict(self.masks),dict(self.layouts)
            created=[]
            selected=list(rt.selection)
            cid=plan.get("controller_id",uid("controller"))
            from .procedural import require_unified_mutation
            require_unified_mutation(self.controllers.get(cid))
            require(all(getattr(rt, name, None) is not None for name in
                        ("cyrusPresetTrackPublication", "cyrusRecipeTrackCreated")),
                    "Generation requires the matching native publication Undo helpers", "UNSUPPORTED_CAPABILITY")
            require(all(len(owner.layerObjects) <= 10 for owner in old_controllers.values()),
                    "Publication Undo supports at most ten child owners", "BUDGET_EXCEEDED")
            publication_before = {key: self.publication_identity(owner) for key, owner in old_controllers.items()}
        except Fault as exc:
            raise Fault(exc.code, exc.message, **{**exc.details, "effects": "none"}) from exc
        except Exception as exc:
            raise Fault("HOST_ERROR", "Generation preflight failed before mutation", effects="none") from exc
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
                    rt.cyrusRecipeTrackCreated(obj.baseObject)
                    # Native dependency callbacks may otherwise assign this ID
                    # later and invalidate an unchanged approved scope.
                    obj.layerID=rt.CyrusNewLayerID()
                else:
                    require(len(obj.modifiers) == 0, "Controllers with modifiers cannot be refined", "UNSUPPORTED_CAPABILITY")
                    rt.cyrusPresetTrackPublication(rt.Array(obj.baseObject, *list(obj.layerObjects)))
                self.checkpoint("controller")
                obj.setLayerTransfer(True)
                # One evaluator; versioned plans cannot select retired policies.
                obj.cyrusEnabled=True
                for field in ("procRuleScope","procRuleA","procRuleB","procRuleEnabled","procRuleGapWU","procRuleMultiplier","procRulePlanar"):
                    rt.setProperty(obj,rt.Name(field),rt.Array())
                obj.updateMode=1
                obj.surfaceNodes=rt.Array(self.site)
                obj.viewportMode=2
                obj.proxyShape=1
                obj.viewportInstances=2000
                obj.previewBudget=20000
                from .settings import LAYER_SETTINGS, SOURCE_SETTINGS, DISPLAY_SETTINGS
                for key,(_,_,_,prop) in DISPLAY_SETTINGS.items():
                    if prop:rt.setProperty(obj,rt.Name(prop),plan["display"][key])
                mode=plan["display"]["mode"]
                obj.viewportMode={"point_cloud":1,"proxy":2,"mesh":3,"centres":1}[mode]
                obj.groupCenters=mode=="centres"
                obj.proxyShape={"box":1,"sphere":2,"pyramid":3}[plan["display"]["proxy_shape"]]
                layers,new_masks=[],[]
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
                    rt.cyrusRecipeTrackCreated(layer)
                    layer.setLayerTransfer(True)
                    layer.layerID=rt.CyrusNewLayerID()
                    layer.editLayerKey=len(layers)+1

                    layer.procOrder=len(layers)+1
                    layer.procSetOrder=1
                    layer.procSamplingSalt=len(layers)+1
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
                    for field,default in (("sourceZOffsetsWU",0.0),("sourceScales",1.0),("sourceRadiiWU",0.0),("sourceFollowScale",False),("sourceShowRadius",False),("sourcePoint",False),("sourceEmpty",False),("sourceForwardAxes",1)):
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
                    obj.procSetPair(2,layers[rule["a"]],layers[rule["b"]],rule.get("enabled",True),rule["radius_factor"],rule["gap_m"]/self.metre,rule["planar"])
                # Validate and report the same attached, final population that
                # viewport/output consume, after the complete graph exists.
                obj.refreshAll()
                result,layout=self.read_generated(obj,plan,compiled,cid,gid,undo_label)
                self.checkpoint("preview")
                for old in self.masks.get(cid,[]):
                    require(rt.isValidNode(old), "Owned mask changed", "STALE_CONTEXT")
                    rt.delete(old)
                self.checkpoint("replace")
                rt.setUserProp(obj,"CyrusAutomationOwner",cid)
                rt.setUserProp(obj,"CyrusAutomationGeneration",gid)
                rt.setUserProp(obj,"CyrusAutomationConfiguration",gid)
                self.controllers[cid]=obj
                self.masks[cid]=new_masks
                obj.updateMode=1 if plan["display"]["update_mode"]=="manual" else 2
                self.layouts[cid]=layout
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
            recovered=self.rollback_matches(before, publication_before, created)
            if not recovered:
                raise Fault("ROLLBACK_FAILED", "Generation failed and recovery could not be verified; stop and inspect locally", primary=str(failure))
            if isinstance(failure,Fault):
                raise Fault(failure.code,failure.message,rollback="verified")
            raise Fault("GENERATION_FAILED", str(failure)[:500], rollback="verified")
        self.undo_checkpoint = dict(label=undo_label, fingerprint=before, controllers=old_controllers,
                                    masks=old_masks, publications=publication_before, created=created)
        try:
            # Preserve artist selection; no new controller is selected implicitly.
            if selected:
                rt.select(rt.Array(*(n for n in selected if rt.isValidNode(n))))
            else:
                rt.clearSelection()
            rt.redrawViews()
        except Exception as exc:
            raise Fault("POST_COMMIT_FAILED", "Native generation committed but presentation finalization failed",
                        effects="committed", result=result) from exc
        return result

    def read_generated(self, obj, plan, compiled, cid, gid, undo_label):
        metrics, transform_rows, layout_instances = [], [], []
        for layer,spec,mask in zip(obj.layerObjects,plan["layers"],compiled):
            rows=layer.placements(layer.validSources())
            expected=spec["count"] if spec.get("settings",{}).get("enabled",True) else 0
            require(spec["underfill"] == "allow" or len(rows) == expected, "Layer underfilled and policy is reject", "GEOMETRY_CONSTRAINT")
            for ordinal,row in self.placement_rows(rows):
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
        result={"controller_id":cid,"generation_id":gid,"layers":metrics,"emitted":sum(m["emitted"] for m in metrics),"requested":sum(m["requested"] for m in metrics),"transform_digest":digest(transform_rows),"display_mode":"proxy_boxes","calculation_model":str(obj.calculationModel()),"ui_version":str(obj.uiVersion()),"plan_schema":plan["schema_version"],"undo_label":undo_label,"constraint_check":"all emitted footprint circles inside approved regions"}
        result["display_mode"]=plan["display"]["mode"]
        layout={"layout_schema":"cyrus.layout/1.0","controller_id":cid,"generation_id":gid,"transform_digest":result["transform_digest"],"identity_scope":"this generation; refinement creates new population IDs","instances":layout_instances}
        result.update(configuration_id=gid, publication_pending=False)
        return result, layout

    def publication_identity(self, obj):
        """Identity of an immutable cached native frame; never calculate placements."""
        from .publication import manifest
        return digest({"publication": manifest(frozen(obj.procPublicationInfo())),
                       "owner": frozen(rt.getUserProp(obj, "CyrusAutomationOwner")),
                       "generation": frozen(rt.getUserProp(obj, "CyrusAutomationGeneration")),
                       "configuration": frozen(rt.getUserProp(obj, "CyrusAutomationConfiguration"))})

    def change(self, change, plan, compiled, previous):
        """Patch stable owned layers and optionally calculate in one authored hold."""
        try:
            self.assert_main()
            require(getattr(rt, "cyrusLicenseAllows", None) is not None and bool(rt.cyrusLicenseAllows()),
                    "Cyrus authoring requires an active team license", "LICENSE_REQUIRED")
            require(not self.busy() and not rt.isSceneRedrawDisabled(), "Host is busy", "HOST_BUSY")
            cid = change["controller_id"]
            obj = self.controllers.get(cid)
            require(obj is not None and rt.isValidNode(obj), "Owned controller unavailable", "STALE_CONTEXT")
            from .procedural import require_unified_mutation
            require_unified_mutation(obj)
            require(len(obj.modifiers) == 0 and 1 <= len(obj.layerObjects) <= 3,
                    "Only the current bounded owned graph supports changes", "UNSUPPORTED_CAPABILITY")
            layers = list(obj.layerObjects)
            require([str(layer.layerID) for layer in layers] == [layer["layer_id"] for layer in previous["layers"]],
                    "Owned layer correspondence changed", "STALE_CONTEXT")
            require(str(rt.getUserProp(obj, "CyrusAutomationOwner")) == cid
                    and str(rt.getUserProp(obj, "CyrusAutomationGeneration")) == change["generation_id"]
                    and str(rt.getUserProp(obj, "CyrusAutomationConfiguration")) == change["configuration_id"],
                    "Owned configuration or generation changed", "STALE_CONTEXT")
            require(getattr(rt, "cyrusPresetTrackPublication", None) is not None,
                    "Matching native publication Undo helper required", "UNSUPPORTED_CAPABILITY")
            mode = change["mode"]
            if mode == "configure":
                require(all(int(owner.updateMode) == 1 for owner in [obj, *layers]),
                        "Configure-only requires Manual mode", "UNSUPPORTED_CAPABILITY")
            before = self.fingerprint()
            published_before = {key: self.publication_identity(owner) for key, owner in self.controllers.items()}
            undo_checkpoint = dict(fingerprint=before, controllers=dict(self.controllers), masks=dict(self.masks),
                                   publications=published_before, created=[])
            old_layouts = dict(self.layouts)
        except Fault as exc:
            raise Fault(exc.code, exc.message, **{**exc.details, "effects": "none"}) from exc
        except Exception as exc:
            raise Fault("HOST_ERROR", "Change preflight failed before mutation", effects="none") from exc
        gid = previous["generation_id"] if mode == "configure" else uid("generation")
        config_id = previous["configuration_id"] if mode == "update" else uid("configuration")
        label = "Cyrus Automation " + uid("change")[-8:]
        failure, result = None, None
        with pymxs.undo(True, label), pymxs.redraw(False), pymxs.animate(False):
            try:
                rt.cyrusPresetTrackPublication(rt.Array(obj.baseObject, *layers))
                obj.setLayerTransfer(True)
                for layer in layers:
                    layer.setLayerTransfer(True)
                by_id = {str(layer.layerID): layer for layer in layers}
                for patch in change["layers"]:
                    target = by_id[patch["layer_id"]]
                    if "count" in patch:
                        target.amount = patch["count"]
                    if "seed" in patch:
                        target.randomSeed = patch["seed"]
                self.checkpoint("change_settings")
                for layer in layers:
                    layer.setLayerTransfer(False)
                obj.setLayerTransfer(False)
                if mode == "configure":
                    require(self.publication_identity(obj) == published_before[cid],
                            "Configure-only changed the publication", "GENERATION_FAILED")
                    result = deepcopy(previous)
                    result.update(undo_label=label, publication_pending=True,
                                  authored_requested=sum(layer["count"] for layer in plan["layers"]))
                else:
                    obj.refreshAll()
                    result, layout = self.read_generated(obj, plan, compiled, cid, gid, label)
                    layout["identity_scope"] = "Stable layer/candidate identities; unchanged identity does not promise unchanged accepted placement."
                    self.layouts[cid] = layout
                    self.checkpoint("change_preview")
                rt.setUserProp(obj, "CyrusAutomationGeneration", gid)
                rt.setUserProp(obj, "CyrusAutomationConfiguration", config_id)
                result.update(configuration_id=config_id, operation_kind=mode)
                self.checkpoint("change_publish")
            except Exception as exc:
                failure = exc
        try:
            for owner in [obj, *layers]:
                owner.setLayerTransfer(False)
        except Exception as exc:
            if failure:
                raise Fault("ROLLBACK_FAILED", "Could not release failed change owners for recovery") from exc
            raise Fault("POST_COMMIT_FAILED", "Change committed but owner finalization failed", effects="committed", result=result) from exc
        if failure:
            names = list(rt.theHold.GetUndoNames())
            require(names and str(names[0]) == label, "Failed change is not at the top of Undo", "ROLLBACK_FAILED")
            pymxs.run_undo()
            self.layouts = old_layouts
            require(self.rollback_matches(before, published_before, []),
                    "Failed change could not restore the previous complete state", "ROLLBACK_FAILED")
            if isinstance(failure, Fault):
                raise Fault(failure.code, failure.message, rollback="verified")
            raise Fault("GENERATION_FAILED", str(failure)[:500], rollback="verified")
        self.undo_checkpoint = dict(undo_checkpoint, label=label)
        try:
            rt.redrawViews()
        except Exception as exc:
            raise Fault("POST_COMMIT_FAILED", "Change committed but presentation failed", effects="committed", result=result) from exc
        return result

    def rollback_matches(self, before, publications, created):
        # Authored parameters alone cannot prove restoration of native caches.
        return (self.fingerprint() == before
                and all(not rt.isValidNode(node) for node in created)
                and all(key in self.controllers and self.publication_identity(self.controllers[key]) == identity
                        for key, identity in publications.items()))

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
        try:
            self.assert_main()
            require(not self.busy(), "Max is busy; Undo was not started", "HOST_BUSY")
            witness=self.undo_checkpoint
            current_ids=list(self.controllers)
            require(witness and witness["label"]==label, "No current owned Undo witness; inspect Max's history locally", "STALE_CONTEXT")
            names=list(rt.theHold.GetUndoNames())
            require(names and str(names[0])==label, "A different edit is at the top of Max's Undo history", "STALE_CONTEXT")
        except Fault as exc:
            raise Fault(exc.code,exc.message,effects="none") from exc
        except Exception as exc:
            raise Fault("HOST_ERROR","Undo preflight failed before mutation",effects="none") from exc
        # After entry, an exception or mismatched publication is uncertain. Do
        # not replay Undo or call it a rollback merely because it raised.
        if witness.get("kind")=="source_assets":return self.source_asset_adapter().undo(witness)
        pymxs.run_undo()
        self.checkpoint("undo_after_native")
        self.controllers,self.masks=witness["controllers"],witness["masks"]
        require(self.rollback_matches(witness["fingerprint"],witness["publications"],witness["created"]),
                "Native Undo returned but its restored state could not be verified", "UNDO_UNVERIFIED")
        result={"native_undo_verified":True,"undo_label":label,
                "restored_controllers":[{"controller_id":cid,
                    "generation_id":str(rt.getUserProp(node,"CyrusAutomationGeneration")),
                    "configuration_id":str(rt.getUserProp(node,"CyrusAutomationConfiguration"))}
                    for cid,node in self.controllers.items()],
                "removed_created_nodes":len(witness["created"])}
        if result["restored_controllers"]:
            result.update(result["restored_controllers"][0])
        elif len(current_ids)==1:
            result.update(controller_id=current_ids[0],controller_removed=True)
        self.controllers,self.masks,self.layouts={},{},{}
        self.undo_checkpoint=None
        try:
            self.checkpoint("undo_presentation")
            rt.redrawViews()
        except Exception as exc:
            raise Fault("POST_COMMIT_FAILED","Native Undo verified but presentation failed",effects="committed",result=result) from exc
        return result

    def clear_undo_witness(self):
        self.undo_checkpoint=None
