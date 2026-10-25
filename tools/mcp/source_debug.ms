global MCPSourceDebugRun
fn MCPSourceDebugRun scenario = (
    local nodes=for node in objects where node.name=="Owned baked high-detail source" collect node
    if nodes.count!=1 do throw "Owned debug source is ambiguous"
    local error="",result=undefined
    try(result=cyrusSourceMeasurement nodes[1] 1.0 2000000 1000000)catch(error=getCurrentException())
    local file=createFile (MCPFixtureDir+"source-debug-"+QRequestID+".txt")
    try(format "error=%\nclass=%\nresult=%\n" error (classof nodes[1].baseObject) result to:file)catch(close file;throw)
    close file
    QAssert true "raw_native_observed" "Raw native result/error recorded without changing source geometry"
)
