RSAssert()
(
    local s=stringStream ""
    for key in #(#surflist,#surfmode,#surfon,#manualupdate,#arnamelist,#artypelist,#arpaintlist,#cobjlist,#geomlist,#reserved7) do if isProperty VForest key do format "% %\n" key (getProperty VForest key) to:s
    RSWrite "forest-configuration.txt" (s as string);close s
    select VForest;max modify mode;modPanel.setCurrentObject VForest
)
