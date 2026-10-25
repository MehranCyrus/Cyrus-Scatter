global TOwner,TEdit,TRocks,PSettle
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();PSettle 900
