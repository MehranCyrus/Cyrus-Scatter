-- Destructive fixture, restricted to a disposable profile created by launch.py.
if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
resetMaxFile #noPrompt
fileIn (BLRoot+"tools/v1/planting_groups_fixture.ms")
fileIn (BLRoot+"tools/v1/planting_output_fixture.ms")
fileIn (BLRoot+"tools/v1/planting_advanced_fixture.ms")
