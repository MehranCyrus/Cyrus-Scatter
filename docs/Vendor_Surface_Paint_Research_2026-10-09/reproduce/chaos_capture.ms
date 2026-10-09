RSAssert()
global VCapture,VLabel="baseline",VCaptures=#(),VGetTargets
(
    fn VGetTargets = (for name in #("VS_R1","VS_R2","VS_R3") collect getNodeByName name exact:true)
    fn VCapture label force:true normalRedraw:false = (
        if normalRedraw do (select VChaos;max modify mode;modPanel.setCurrentObject VChaos;redrawViews())
        RSWrite "stage.txt" (label+": update")
        local start=timestamp(),result=undefined,updateMs=0
        if force do (result=VChaos.FpInterface.update (interval 0 0) 0;updateMs=timestamp()-start)
        RSWrite "stage.txt" (label+": count")
        local count=VChaos.FpInterface.getInstanceCount(),original=objects as array
        RSWrite "stage.txt" (label+": convert")
        start=timestamp()
        local converted=VChaos.FpInterface.convertInstancesToGeometry currentTime,convertMs=timestamp()-start
        local created=for node in objects where findItem original node==0 collect node,rows=#(),s=stringStream ""
        format "instances % updateResult % updateMs % converted % convertMs % nodes % density % targets % factors %\n" count result updateMs converted convertMs created.count VChaos.surfaceRandomUseDensity VChaos.targetNodes VChaos.targetFactors to:s
        for node in created do (
            local model=0
            for i=1 to VModels.count do if node.baseObject==VModels[i].baseObject do model=i
            if model==0 do (if classof node.baseObject==Box do model=1;if classof node.baseObject==Sphere do model=2)
            append rows #(node.transform,model,(classof node.baseObject as string))
            format "%\t%\t%\n" model (classof node.baseObject) node.transform to:s
        )
        RSWrite (label+".tsv") (s as string);close s
        append VCaptures #(label,rows)
        delete created
        RSWrite "stage.txt" (label+": captured")
        rows
    )
    if VLabel!="definitions_only" do VCapture VLabel
)
