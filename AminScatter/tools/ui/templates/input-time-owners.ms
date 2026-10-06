-- Only registered Scatter nodes participate in timeline notifications. This
-- registry is rebuilt at scene boundaries, never by scanning every animation frame.
global AminScatterObject
global CyrusTimeOwners=#(),CyrusRegisterTimeOwner,CyrusResetTimeOwners,CyrusPruneTimeOwners
fn CyrusRegisterTimeOwner node = (
    if isValidNode node and classof node.baseObject==AminScatterObject do appendIfUnique CyrusTimeOwners node
)
fn CyrusPruneTimeOwners = (
    CyrusTimeOwners=for node in CyrusTimeOwners where isValidNode node and classof node.baseObject==AminScatterObject collect node
)
fn CyrusResetTimeOwners = (
    CyrusTimeOwners=for node in objects where classof node.baseObject==AminScatterObject collect node
)
