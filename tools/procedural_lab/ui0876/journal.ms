-- Each action, Undo, Redo and observation runs in a separate owned host callback.
-- The fixture is created by campaign.py; this script never clears history or repairs holds.
global UIJournalBefore,UIJournalAfter
(
    local failure="",values=""
    try (
        if theHold.Holding() or theHold.IsSuspended() do throw "Unexpected active hold"
        if CVProfileCase=="point-action" then (
            UIJournalBefore=UILayer.sourceRowIDs as array
            UIRoot.modelsUI.sourceUI_addPoint.pressed()
        ) else if CVProfileCase=="point-record" then (
            UIJournalAfter=UILayer.sourceRowIDs as array
            if UIJournalAfter.count!=UIJournalBefore.count+1 or not UILayer.sourcePoint[UIJournalAfter.count] do throw "Point add failed"
        ) else if CVProfileCase=="point-undo-check" then (
            if (UILayer.sourceRowIDs as array) as string!=UIJournalBefore as string do throw "Point Undo identity mismatch"
        ) else if CVProfileCase=="point-redo-check" then (
            if (UILayer.sourceRowIDs as array) as string!=UIJournalAfter as string or not UILayer.sourcePoint[UIJournalAfter.count] do throw "Point Redo identity mismatch"
        ) else throw "Unexpected phase"
        UIRoot.refreshAll()
        if UILayer.previewError!="" do throw UILayer.previewError
        if CVProfileCase!="point-action" do (
            if UIRoot.modelsUI.sourceUI_plantList.items.count!=UILayer.sources.count or UIRoot.interactionsUI.interactionsUI_modelList.items.count!=UILayer.sources.count do throw "Source views differ"
        )
        values="\"source_count\":"+(UILayer.sources.count as string)+",\"placements\":"+(UILayer.generatedCount as string)
    ) catch (failure=getCurrentException())
    local text="{\"case\":\""+CVProfileCase+"\",\"status\":\""+(if failure=="" then "pass" else "failed")+"\",\"error\":\""+(substituteString (substituteString failure "\\" "\\\\") "\"" "\\\"")+"\""+(if values=="" then "" else ","+values)+"}"
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+CVProfileCase+".json") text
)
