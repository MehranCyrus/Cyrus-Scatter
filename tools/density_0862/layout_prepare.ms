(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local main=DRoot.mainUI
 for i=1 to main.editors.count do (
  main.slots[i].open=true;main.bindSection main.editors[i]
  local page=main.editors[i]
  if page.isDisplayed do (page.advancedToggle.checked=true;page.layout())
 )
)
