# Selection-only stall: Scatter 0.59 / Analyzer 0.14

Select.max reproduced the remaining issue in 0.58: entering Modify and changing sub-object level sent modelOtherEvent for Line002 although its shape was unchanged. Dependent scripted helper nodes also sent geometry/topology notifications for their own display. Treating both as source geometry edits caused expensive analysis and layer regeneration.

Changes:
- Remove the broad modelOtherEvent subscription from Scatter and Analyzer. Keep geometryChanged, topologyChanged, mappingChanged (Scatter), modelStructured, controller changes, link changes and deletion handling.
- Ignore Analyzer helper-node display/geometry notifications in the Scatter external-input listener. Its published analysis counter, not its icon invalidation, represents data changes.
- Poll Analyzer counters before layer dependency dirtiness propagation, ensuring an Analyzer-only parameter edit also refreshes layers whose collision depends on an Analyzer-driven layer.

Native binaries remain bin55 and bin05. Script class versions: Scatter 44, Analyzer 13. No original scene is saved or changed.

Regression scenario: select linked surface, enter Modify, enter Edge, select edge 1/2/none, switch to Vertex, select vertex, move vertex 1 and restore it, then change Analyzer point radius. Compare preview build counters and Analyzer run counter after each action. See work/v59/selection.txt (before), selection-fixed.txt and selection-final.txt (after).
