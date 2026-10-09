RSAssert()
global VReceivers,VModels,VForest
(
    VReceivers=#(plane name:"VF_R1" width:100 length:100,plane name:"VF_R2" width:100 length:200 pos:[400,0,0],plane name:"VF_R3" width:100 length:300 pos:[900,0,0])
    VModels=#(box name:"VF_Box" width:2 length:3 height:5 pos:[-1000,-1000,0],sphere name:"VF_Sphere" radius:2 segs:8 pos:[-1100,-1000,0])
    RSWrite "stage.txt" "Create Forest Lite"
    VForest=Forest_Lite name:"VF_Forest"
    RSWrite "stage.txt" "Forest manual update enabled"
    VForest.manualupdate=true
    RSWrite "stage.txt" "Forest one receiver assignment"
    VForest.surflist=#(VReceivers[1])
    RSWrite "stage.txt" "Forest one receiver assignment returned"
    RSWrite "forest-one-receiver.txt" (VForest.surflist as string)
)
