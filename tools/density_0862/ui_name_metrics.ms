(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    local page=DRoot.mainUI.editors[1],field=page.flow_layersUI_nameEdit
    local f=createFile (MCPFixtureDir+"name-metrics.txt")
    format "page_width=% text=% class=% enabled=% logical_pos=% width=% is_width=%\n" page.width field.text (classof field) field.enabled field.pos field.width (isProperty field #width) to:f
    for h in field.hwnd do format "% data=% rect=%\n" h (windows.getHWNDData h) (windows.getWindowPos h removeUIScaling:false) to:f
    format "FOCUS=%\n" (windows.getHWNDData (windows.getFocus())) to:f
    close f
)
