"""Private native-reader qualification. No recipe import or public MCP grant."""
from pathlib import Path
import json
import time
import traceback

from pymxs import runtime as rt
from PySide6 import QtCore
from cyrus_mcp.max_host import frozen
from cyrus_mcp.contracts import digest

RUN=None


class Run(QtCore.QObject):
    def __init__(self,panel,folder,roots,state):
        super().__init__(panel)
        self.folder=Path(folder);self.roots={key:Path(value) for key,value in roots.items()}
        self.state=state;self.before=state();self.started=time.monotonic();self.handles=set();self.heartbeats=0
        self.result={"status":"running","qualification":"Native API only; internal matched Max 2027 prototype, not a model-callable recipe workflow.","cases":[]}
        assert int(rt.cyrusRecipeCatalogVersion())==1 and int(rt.maxVersion()[0])==29000
        self.gallery=int(rt.cyrusRecipeLibraryStart(rt.Array(str(self.roots["large"]))))
        self.large=self.open(self.roots["large"]);self.small=self.open(self.roots["small"])
        self.rejected(lambda:self.open(self.roots["small"]))
        self.phase="initial"
        self.timer=QtCore.QTimer(self);self.timer.setInterval(30);self.timer.timeout.connect(self.tick);self.timer.start()
        self.save()

    def save(self):
        (self.folder/"recipe-native-result.json").write_text(json.dumps(self.result,indent=2)+"\n",encoding="utf-8")

    def rejected(self,callback):
        try:callback()
        except RuntimeError:return
        raise AssertionError("Native catalog admitted an invalid handle/path/owner")

    def open(self,path):
        handle=int(rt.cyrusRecipeCatalogOpen(str(path)));self.handles.add(handle);return handle

    def close(self,handle):
        rt.cyrusRecipeCatalogClose(handle);self.handles.remove(handle)

    def page(self,handle,query="",number=1):return frozen(rt.cyrusRecipeCatalogPage(handle,query,"",number))

    def gallery_page(self):return frozen(rt.cyrusRecipeLibraryPage(self.gallery,"","",1))

    def stop(self):
        self.timer.stop()
        for handle in list(self.handles):
            try:self.close(handle)
            except Exception:pass
        rt.cyrusRecipeLibraryCancel(self.gallery)

    def tick(self):
        self.heartbeats+=1
        try:
            assert time.monotonic()-self.started<45,"Native reader observation deadline exceeded"
            if self.phase=="initial":
                large=self.page(self.large);small=self.page(self.small);gallery=self.gallery_page()
                if any(page[0]=="scanning" for page in (large,small,gallery)):return
                assert large[1:5]==[256,256,0,True] and len(large[9])==128,large[:9]
                assert len(self.page(self.large,number=2)[9])==128
                assert small[1:5]==[2,1,1,False] and len(small[9])==1,small[:9]
                assert self.page(self.small,query="MEADOW")[6]==1
                assert gallery[1:5]==[301,301,0,False],gallery[:9]
                self.gallery_digest=digest(gallery);small_digest=digest(small)
                self.close(self.large)
                self.rejected(lambda:self.page(self.large));self.rejected(lambda:rt.cyrusRecipeCatalogClose(self.large))
                assert digest(self.page(self.small))==small_digest and digest(self.gallery_page())==self.gallery_digest
                self.close(self.small)
                self.result["cases"].append({"case":"independent_readers_and_gallery","status":"passed","large_count":256,"gallery_count":301,
                                              "invalid_count":1,"entry_limit_reported":True,"gallery_page_sha256":self.gallery_digest})
                self.replacement=self.open(self.roots["small"])
                assert self.replacement>self.small
                self.rejected(lambda:self.page(self.small))
                self.phase="replacement"
            elif self.phase=="replacement":
                page=self.page(self.replacement)
                if page[0]=="scanning":return
                assert page[2]==1
                self.close(self.replacement)
                self.rejected(lambda:self.open(Path("relative")))
                self.rejected(lambda:self.open(self.roots["linked"]))
                self.result["cases"].append({"case":"stale_handles_and_linked_root","status":"passed"})
                self.absent=self.open(self.roots["absent"]);self.phase="absent"
            elif self.phase=="absent":
                page=self.page(self.absent)
                if page[0]=="scanning":return
                assert page[2]==0 and page[5]
                self.close(self.absent)
                handle=self.open(self.roots["large"]);self.close(handle)
                self.rejected(lambda:self.page(handle))
                assert digest(self.gallery_page())==self.gallery_digest
                after=self.state();assert after==self.before,(self.before,after)
                assert not after["save_required"]
                self.result["cases"].append({"case":"missing_folder_cancel_and_clean_native_state","status":"passed",
                                              "before":self.before,"after":after,"qt_timer_callbacks":self.heartbeats})
                self.stop();self.result["status"]="passed";self.result["seconds"]=time.monotonic()-self.started;self.save()
        except Exception:
            self.result["status"]="failed";self.result["error"]=traceback.format_exc()
            try:self.stop()
            finally:self.save()


def start(panel,folder,roots,state):
    global RUN
    assert RUN is None or RUN.result["status"]!="running"
    RUN=Run(panel,folder,roots,state)
    return {"status":RUN.result["status"]}
