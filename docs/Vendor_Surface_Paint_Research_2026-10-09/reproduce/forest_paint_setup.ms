RSAssert()
(
    for n in objects where matchPattern n.name pattern:"VS_*" do hide n
    VForest.cobjlist[1]=getNodeByName "VF_Box" exact:true
    VForest.units_x=1000.;VForest.units_y=1000.;VForest.pixels_x=100;VForest.pixels_y=100
    select (getNodeByName "VF_R1" exact:true)
    viewport.setType #view_top
    max zoomext sel all
    select VForest;max modify mode;modPanel.setCurrentObject VForest
    local s=stringStream ""
    for key in #(#cobjlist,#geomlist,#surflist,#pf_aractivelist,#aridlist,#artypelist,#arpaintlist,#manualupdate) do format "% %\n" key (getProperty VForest key) to:s
    RSWrite "forest-paint-setup.txt" (s as string);close s
    RSWrite "stage.txt" "Forest explicit update"
    VForest.trees.update()
    RSWrite "forest-initial-count.txt" ((VForest.trees.count()) as string)
    RSWrite "stage.txt" "Forest explicit update returned"
)
