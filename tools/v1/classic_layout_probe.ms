if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
(
    local rows=#()
    for r in #(CFRoot.mainUI,CFRoot.layerPanels[1],CFRoot.layerPanels[2],CFRoot.layerPanels[1].editors[3]) do append rows #(r.title,r.open,r.height,(windows.getWindowPos r.hwnd) as string,(windows.getWindowPos (windows.getParentHWND r.hwnd)) as string)
    CSPWriteText (BLDir+"classic-settled-bounds.json") (CSPObject #(#("rows",rows),#("containers",#(CFRoot.mainUI.panels.height,CFRoot.layerPanels[1].sections.height,CFRoot.layerPanels[2].sections.height)),#("scroll",#(CFRoot.mainUI.scrollPos,CFRoot.layerPanels[1].scrollPos,CFRoot.layerPanels[1].editors[1].scrollPos))))
)
