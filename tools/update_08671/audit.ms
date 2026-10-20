(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned DPI host required"
 fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\update_08671\preview.ms"
 fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\update_08671\panel_acceptance.ms"
 execute "global PanelNode=VController,PanelRoot=VRoot"
 python.ExecuteFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\update_08671\layout_audit.py"
)
