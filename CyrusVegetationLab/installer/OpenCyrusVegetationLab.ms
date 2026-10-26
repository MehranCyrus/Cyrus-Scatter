(
    if (maxVersion())[1]!=29000 do throw "Cyrus Vegetation Lab requires Max 2027."
    if CVLOpen==undefined do throw "Install the Vegetation Lab MZP, save work, and restart Max 2027 before opening the lab."
    CVLOpen()
)
