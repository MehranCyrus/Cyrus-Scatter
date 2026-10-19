(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 global DNode,DRoot,DLayer,DTerrain
 CyrusClearMeshMaskPreview undefined
 DNode=Demo0862Node;DRoot=DNode.baseObject;DLayer=DRoot.layerObjects[4];DTerrain=(DLayer.validSurfaces())[1]
 select DNode;max modify mode;DRoot.selectLayer 4;DRoot.bindNativeUI()
)
