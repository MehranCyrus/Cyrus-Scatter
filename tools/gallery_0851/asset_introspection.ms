(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local out=createFile (MCPFixtureDir+"asset-properties.txt")
    for object in #(standardMaterial(),bitmaptexture(),(bitmaptexture()).coords) do (
        format "CLASS %\n" (classof object) to:out
        for key in getPropNames object do try(format "% | % | %\n" key (classof (getProperty object key)) (getProperty object key) to:out)catch(format "% | ERROR\n" key to:out)
    )
    close out
)
