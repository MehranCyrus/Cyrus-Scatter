(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-orientation0830-*/" do throw "Owned orientation host required."
    OrientationRoot.mainUI.slots[9].open=true
    OrientationRoot.mainUI.slots[9].rolledUp false
    OrientationRoot.mainUI.editors[9].scrollPos=650
    redrawViews()
    local file=createFile (MCPFixtureDir+"scroll-position.txt")
    format "slot=% page=%\n" OrientationRoot.mainUI.slots[9].scrollPos OrientationRoot.mainUI.editors[9].scrollPos to:file
    close file
)
