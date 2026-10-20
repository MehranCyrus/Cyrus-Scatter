global CA_STARTUP_OK, CA_STARTUP_ERROR, caFocusArrange
macroScript CyrusArrangeStyling category:"Cyrus" toolTip:"Cyrus Arrange — create or edit in Modify" buttonText:"Cyrus Arrange"
(
    on execute do
    (
        if CA_STARTUP_OK == true and caFocusArrange != undefined then caFocusArrange()
        else messageBox (if CA_STARTUP_ERROR == undefined or CA_STARTUP_ERROR == "" then "Restart Max 2027 after installing Cyrus Arrange." else CA_STARTUP_ERROR) title:"Cyrus Arrange"
    )
)
macroScript CreateCyrusArrange category:"Cyrus" toolTip:"Create Cyrus Arrange" buttonText:"Create Cyrus Arrange"
(
    on execute do (if CA_STARTUP_OK == true and caFocusArrange != undefined do caFocusArrange createNew:true)
)
macroScript CyrusArrangeInspector category:"Cyrus" toolTip:"Cyrus Arrange parameters in Modify" buttonText:"Arrange Parameters"
(
    on execute do (if CA_STARTUP_OK == true and caFocusArrange != undefined do caFocusArrange())
)
