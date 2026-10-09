RSAssert()
(
    local f=createFile (RSDir+"defaults.txt")
    for name in #("Research_Forest_Lite","Research_ChaosScatter") do (
        local n=getNodeByName name
        format "OBJECT %\n" n to:f
        for property in getPropNames n do (
            local v=try(getProperty n property)catch(undefined),s=v as string
            if s.count>500 do s=substring s 1 500
            format "% = %\n" property s to:f
        )
    )
    close f
)
