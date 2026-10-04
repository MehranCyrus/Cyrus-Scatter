if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
resetMaxFile #noPrompt
fileIn (BLRoot+"AminScatter/scripts/AminScatterObject.ms")
fileIn (BLRoot+"tools/v1/layers_first_load.ms")
