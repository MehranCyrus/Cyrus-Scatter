MFState "probe"
format "LOGICAL % counts=% rows=% errors=% surfaces=%\n" MFRoot.layerObjects.count (for leaf in MFRoot.layerObjects collect leaf.amount) (for rows in MFRoot.groupSnapshotRows collect rows.count) (for leaf in MFRoot.layerObjects collect leaf.previewError) (for leaf in MFRoot.layerObjects collect leaf.validSurfaces()) to:MFLog
flush MFLog
