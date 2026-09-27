macroScript AminScatterOpen category:"Cyrus" tooltip:"Create Cyrus Scatter" buttonText:"Cyrus Scatter" (
    global AminScatterObject
    on execute do (
        if AminScatterObject == undefined then
            messageBox "Restart 3ds Max 2026 after installing Cyrus Scatter." title:"Cyrus Scatter"
        else
            startObjectCreation AminScatterObject
    )
)

