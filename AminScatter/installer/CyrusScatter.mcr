macroScript CyrusScatterCreate category:"Cyrus" tooltip:"Create Cyrus Scatter" buttonText:"Cyrus Scatter" (
    global CyrusScatterObject
    on execute do (
        if CyrusScatterObject==undefined then messageBox "Restart 3ds Max after installing Cyrus Scatter __VERSION__." title:"Cyrus Scatter"
        else startObjectCreation CyrusScatterObject
    )
)
