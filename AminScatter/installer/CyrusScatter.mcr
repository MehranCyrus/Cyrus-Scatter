macroScript CyrusScatterCreate category:"Cyrus" tooltip:"Create Cyrus Scatter" buttonText:"Cyrus Scatter" (
    global CyrusScatterObject
    on execute do (
        if CyrusScatterObject==undefined then messageBox "Restart 3ds Max after installing Cyrus Scatter __VERSION__." title:"Cyrus Scatter"
        else startObjectCreation CyrusScatterObject
    )
)
macroScript CyrusScatterLibrary
category:"Cyrus"
toolTip:"Cyrus Library - load onto selected terrain"
buttonText:"Cyrus Library"
(
    global CyrusOpenRecipeLibrary
    on execute do try (
        if CyrusOpenRecipeLibrary==undefined do throw "Restart Max after installing Cyrus Scatter."
        CyrusOpenRecipeLibrary undefined
    )catch(messageBox (getCurrentException()) title:"Cyrus Library")
)
