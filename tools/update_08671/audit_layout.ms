if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" then throw "Owned layout host required"
else python.ExecuteFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\update_08671\layout_audit.py"
