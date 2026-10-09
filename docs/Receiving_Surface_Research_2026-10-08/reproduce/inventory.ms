RSAssert()
(
local f=createFile (RSDir+"api-inventory.txt")
format "Max version: %\n" (maxVersion()) to:f
showClass "*Forest*" to:f
showClass "*Scatter*" to:f
for kind in #(Forest_Lite,ChaosScatter) do (
    try (
        local n=kind name:("Research_"+(kind as string))
        format "\nOBJECT %\n" n to:f
        showProperties n to:f
        showInterfaces n to:f
        showInterfaces n.baseObject to:f
    ) catch(format "ERROR: %\n" (getCurrentException()) to:f)
)
close f
)
