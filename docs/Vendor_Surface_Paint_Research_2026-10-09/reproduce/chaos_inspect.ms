RSAssert()
(
    local s=stringStream ""
    for key in #(#modelNodes,#modelFrequencies,#targetNodes,#targetFactors,#scatteringSelection,#surfaceMode,#surfaceRandomInstanceCount,#surfaceRandomUseDensity,#seed,#automaticUpdates,#disabled,#enabled) do if isProperty VChaos key do format "% %\n" key (getProperty VChaos key) to:s
    RSWrite "chaos-configuration.txt" (s as string);close s
    select VChaos;max modify mode;modPanel.setCurrentObject VChaos
)
