RSAssert()
(
    local f=Forest_Lite name:"RS_Version_Forest",c=ChaosScatter name:"RS_Version_Chaos"
    RSWrite "vendor-api-versions.txt" ("Forest API "+((f.ForestPack.version()) as string)+"\nChaos API "+c.StaticFpInterface.getVersionString()+"\nChaos number "+((c.StaticFpInterface.getVersionNumber()) as string))
    delete #(f,c)
)
