-- Invocation-only, private session with the acceptance helpers loaded.
(
    P07Case="Edit bindings and rollback"
    P07New count:30
    local root=P07Root,leaf=P07Layer,source=P07Source,surface=P07Surface
    root.newLayer();local later=root.selectedLayer()
    later.sources=#(source);later.amount=25;later.paintEnabled=false
    local edit=CyrusScatterEdit();addModifier P07Node edit;root.evaluateGroups()
    cyrusEditSelect edit #(1,2)
    cyrusEditCommand edit 4 (transMatrix [3,4,5])
    root.evaluateGroups();leaf.procSelectedRadius 1 7;root.evaluateGroups()
    local original=P07Fingerprint root,ids=(cyrusEditSelectedIDs #(edit) leaf.editLayerKey) as string
    local replacement=box width:3 length:3 height:10 pos:[1300,0,0]
    undo "Replace test source" on leaf.sources=#(replacement)
    local rejected=false
    try(root.evaluateGroups())catch(rejected=true)
    P07Assert rejected "Source replacement silently rebound edits"
    max undo
    P07Assert ((P07Fingerprint root) as string==original as string) "Source Undo lost original binding"
    local secondSurface=copy surface
    undo "Replace test receiver" on root.setLayerSurfaces leaf #(secondSurface)
    rejected=false;try(root.evaluateGroups())catch(rejected=true)
    P07Assert rejected "Receiver replacement silently rebound edits"
    max undo
    P07Assert ((P07Fingerprint root) as string==original as string) "Receiver Undo lost original binding"
    local epoch=(leaf.procStatistics())[5],cache=(leaf.cacheSnapshot())[1]
    leaf.amount=40;later.sourceRadii=#(-1.0)
    rejected=false;try(root.evaluateGroups())catch(rejected=true)
    P07Assert rejected "Later owner failure was ignored"
    P07Assert ((leaf.procStatistics())[5]==epoch and (leaf.cacheSnapshot())[1]==cache) "Partial generation was published"
    P07Assert ((cyrusEditSelectedIDs #(edit) leaf.editLayerKey) as string==ids) "Rollback lost Edit selection"
    later.sourceRadii=#(0.0);leaf.amount=30
    P07Assert ((P07Fingerprint root) as string==original as string) "Rollback lost authored Edit transforms"
    -- Native Edit reset cannot make old radius overrides valid for a new sampler.
    cyrusEditCommand edit 0 (matrix3 1)
    leaf.randomSeed+=1
    rejected=false;try(root.evaluateGroups())catch(rejected=true)
    P07Assert rejected "Stale radius overrides accepted a changed generator"
    leaf.procClearRadii();root.evaluateGroups()
    P07Assert (leaf.previewError=="") "Explicit clear did not recover"
    CSPWriteText (MCPFixtureDir+"bindings-acceptance.json") (CSPObject #(#("source_undo_restores_binding",true),#("receiver_undo_restores_binding",true),#("later_failure_atomic",true),#("selection_preserved",true),#("radius_binding_guard",true),#("explicit_clear_recovers",true)))
)
