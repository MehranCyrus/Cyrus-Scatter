CYRebind()
-- MAXScript `as array` returns the same object for arrays. Never join into shared lists.
local beds=for i=1 to 8 collect getNodeByName ("INCLUDE | planting bed "+i as string)
local paths=for i=1 to 3 collect getNodeByName ("EXCLUDE + BANDS | path "+i as string)
local hards=for n in shapes where matchPattern n.name pattern:"EXCLUDE |*" collect n
local excludes=for n in paths collect n;for n in hards do append excludes n
for i in #(1,2,3,4,10) do (
 local nodes=for n in beds collect n,modes=for n in beds collect 1
 for n in excludes do (append nodes n;append modes 2)
 CYL[i].areaNodes=nodes;CYL[i].areaModes=modes
)
CYL[5].areaNodes=for n in excludes collect n;CYL[5].areaModes=for n in excludes collect 2
local lawnNodes=for n in beds collect n;for n in excludes do append lawnNodes n
CYL[6].areaNodes=lawnNodes;CYL[6].areaModes=for n in lawnNodes collect 2
for l in CYL do if l.areaNodes.count!=l.areaModes.count do throw "Mismatched area records"
CYMeasure "corrected-area-update"
saveMaxFile (CYOut+"Courtyard_075.max") quiet:true
CYLog "corrected-area-counts" #(#("areas",for l in CYL collect #(l.areaNodes.count,l.areaModes.count)),#("accepted",for l in CYL collect l.generatedCount))
