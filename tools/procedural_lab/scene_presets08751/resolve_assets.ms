global SPAssetResolve=""
for i=1 to AssetManager.GetNumAssets() do (
    local asset=AssetManager.GetAssetByIndex i
    if matchPattern (asset.GetFileName()) pattern:"*Outdoor_Plants_01_Opacity_005*" do SPAssetResolve+=(asset.GetFileName()+" | "+asset.GetFullFilePath()+" | "+(mapPaths.getFullFilePath (asset.GetFileName()))+"\n")
)
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"asset-resolution.txt") SPAssetResolve
