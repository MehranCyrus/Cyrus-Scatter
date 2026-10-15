(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*meshmask*/" do throw "Owned mask host required"
    local s=createFile (MCPFixtureDir+"mesh-interactions-operator-probe.txt"),dc=DataChannelModifier()
    format "curvature=% output=%\n" (dc.AddOperator 0x0e12bb44 0 0) (dc.AddOperator 0xabcdaa33 0 1) to:s
    format "operators=%\n" dc.operators to:s
    for i=0 to 3 do try(format "[%] %\n" i dc.operators[i] to:s)catch(format "[%] %\n" i (getCurrentException()) to:s)
    close s
)
