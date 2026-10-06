(
 RSReload();RSRoot.cyrusEnabled=false
 local extra=AminScatterObject name:"OPTION LAB | legacy Line and Analyzer",root=extra.baseObject
 local flat=plane name:"OPTION LAB | flat Analyzer receiver" width:3000 length:2300 widthsegs:1 lengthsegs:1 pos:[0,90,0] material:RSSurface.material
 RSSurface.isHidden=true
 root.setLayerTransfer true;root.surfaceNodes=#(flat);root.autoRender=false;root.updateMode=1;root.newLayer()
 local leaf=root.selectedLayer()
 leaf.sources=#(RSOwners[3].sources[1]);leaf.sourceWeights=#(1.0);leaf.amount=1000;leaf.paintEnabled=false;leaf.relaxEnabled=false
 root.setLayerTransfer false
 local analyzer=CyrusSurfaceAnalyzer name:"OPTION LAB | analyzed flat garden" surface:flat
 analyzer.analysisMode=1;analyzer.runAnalysis()
 RSAssert (analyzer.boundaryVertices.count>0 and analyzer.totalArea>0) "Analyzer produced no boundary"
 leaf.areaAnalyzer=analyzer;leaf.areaUseLine=true;leaf.areaLineWidth=120;root.refreshAll()
 local areaRows=leaf.placements (leaf.outputSources())
 RSAssert (areaRows.count>0 and areaRows.count<1000) "Analyzer Area did not restrict actual surface"
 leaf.areaUseLine=false;leaf.diversityMode=4;leaf.analyzerNode=analyzer
 leaf.addStroke analyzer side:2;leaf.patternWidths[1]=130
 root.refreshAll();local analyzerRows=leaf.placements (leaf.outputSources())
 RSAssert (analyzerRows.count>0) "Legacy Analyzer band yielded no placements"
 select extra;max modify mode;modPanel.setCurrentObject root
 saveMaxFile (RSOut+"Variant_Analyzer_Boundary.max") quiet:true
 leaf.diversityMode=3;leaf.patternLines=#();leaf.patternWidths=#();leaf.patternGroups=#();leaf.strokeSides=#();leaf.strokeModes=#();leaf.strokeMin=#();leaf.strokeMax=#()
 local path=getNodeByName "EXCLUDE | entry walk"
 leaf.addStroke path;leaf.patternWidths[1]=120
 root.refreshAll();local lineRows=leaf.placements (leaf.outputSources())
 RSAssert (lineRows.count>0) "Legacy line band yielded no placements"
 saveMaxFile (RSOut+"Variant_Line_Pattern.max") quiet:true
 RSAdvancedRecord "Analyzer Area and legacy Analyzer/Line assignment" #(areaRows.count,analyzerRows.count,lineRows.count,"flat receiver and existing policy; curved Analyzer rejected explicitly")
 RSReload()
 CSPWriteText (MCPFixtureDir+"advanced-campaign.json") (CSPObject #(#("checks",RSAdvanced),#("complete",true)))
)
