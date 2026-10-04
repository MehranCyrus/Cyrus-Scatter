if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
-- The caller waits for classic-native-flow.json to complete before this recipe.
CSPWriteText (BLDir+"classic-campaign-stage.txt") "Native controls and passive caches"
fileIn (BLRoot+"tools/v1/classic_layout_acceptance.ms")
CSPWriteText (BLDir+"classic-campaign-stage.txt") "Layer Manager and selection lifecycle"
fileIn (BLRoot+"tools/v1/classic_manager_acceptance.ms")
CSPWriteText (BLDir+"classic-campaign-stage.txt") "Areas, Brush, Manual and live"
fileIn (BLRoot+"tools/v1/layers_features_fixture.ms")
CSPWriteText (BLDir+"classic-campaign-stage.txt") "Ownership, collision, copy/remove and Undo/Redo"
fileIn (BLRoot+"tools/v1/layers_first_qualification.ms")
CSPWriteText (BLDir+"classic-campaign-stage.txt") "PASS"
