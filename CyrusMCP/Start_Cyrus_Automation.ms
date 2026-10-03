-- Run once from Scripting > Run Script. No automatic scene enrollment.
(
    local root=getFilenamePath (getSourceFileName())
    if AminScatterObject==undefined then messageBox "Load the Cyrus Scatter plugin before opening Automation."
    else (
        python.Execute ("import sys\nfrom pathlib import Path\np=Path("+(python.Import "json").dumps root+")\nif str(p) not in sys.path: sys.path.insert(0,str(p))\nfrom cyrus_mcp.panel import start\nstart()")
    )
)
