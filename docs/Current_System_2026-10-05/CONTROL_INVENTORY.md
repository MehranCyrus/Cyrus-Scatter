# Historical 5 October control inventory

For plain-language explanations of today's controls, use the [current artist reference](../Artist_Reference_0.73_2026-10-07/README.md) and its [complete control index](../Artist_Reference_0.73_2026-10-07/15_CONTROL_INDEX.md). This older listing is an inventory, not a current artist manual.

**0.73 superseding inventory:** the current [semantic source inventory](../../AminScatter/tools/ui/layers-control-inventory.json) has 240 controls. [CONTROL_PORT_RESULTS.csv](../Unified_System_0.73_2026-10-06/CONTROL_PORT_RESULTS.csv) maps every previous 0.72 control to its current location or explicit retirement. The [artist guide](../Unified_System_0.73_2026-10-06/ARTIST_GUIDE.md) covers native Modify, optional popup and selected-container editing. The 241-row listing/hash below remains frozen 5 October evidence; [current capability coverage](CAPABILITY_MATRIX.md) governs today's native/MCP boundary.

Generated from the existing authoritative inventory on 5 October 2026. No new controls or MCP tools are introduced. Capability IDs refer to [the coverage matrix](CAPABILITY_MATRIX.md). A family can contain both remotely supported and unavailable operations; family coverage is not per-button write authority. All **241** entries across **22** sections are listed. Repeated names in different sections are separate controls.

Source: `AminScatter/tools/ui/layers-control-inventory.json`; SHA-256 `ee693aa0f7a6ddaeb4fa62f47d9e70896c7cbd0db6349bda5134f898d08bf51e`.

The source inventory classifies five sections as set-related: `setsUI`, `sourceUI`, `brushUI`, `proceduralUI`, `sourceContainersUI`. Actual ownership still depends on the rule scope and shared layer defaults.

## general / host

Owner/context: **Controller**. Capability families: **C01**.

| Native control name | Kind |
| --- | --- |
| `enabledCheck` | checkbox |

## general / editor

Owner/context: **Editor context; action scope named in UI**. Capability families: **C24,C26,C27**.

| Native control name | Kind |
| --- | --- |
| `updateNow` | button |
| `layerList` | dropdownlist |
| `setList` | dropdownlist |
| `assetsTab` | checkbutton |
| `populationTab` | checkbutton |
| `paintTab` | checkbutton |
| `transformTab` | checkbutton |
| `spacingTab` | checkbutton |
| `statisticsTab` | checkbutton |
| `refreshButton` | button |

## general / updateUI

Owner/context: **Controller**. Capability families: **C24**.

| Native control name | Kind |
| --- | --- |
| `updateRadio` | radiobuttons |
| `updateNow` | button |

## general / previewUI

Owner/context: **Setup display/output**. Capability families: **C25,C28,C29**.

| Native control name | Kind |
| --- | --- |
| `previewCheck` | checkbox |
| `displayModeDrop` | dropdownlist |
| `proxyShapeDrop` | dropdownlist |
| `instancesLimitSpin` | spinner |
| `faceLimitSpin` | spinner |
| `pointColorRadio` | radiobuttons |
| `solidColorPicker` | colorpicker |
| `budgetSpin` | spinner |
| `pointsSpin` | spinner |
| `radiusLimitSpin` | spinner |
| `radiusAllCheck` | checkbox |
| `iconSpin` | spinner |
| `refreshButton` | button |
| `autoRenderCheck` | checkbox |
| `clearBakedButton` | button |

## general / surface

Owner/context: **Controller/global pool**. Capability families: **C02,C07**.

| Native control name | Kind |
| --- | --- |
| `sharedPick` | pickbutton |
| `surfacesButton` | button |
| `policyButton` | button |
| `containersToggle` | checkbutton |
| `globalContainers` | listbox |
| `createContainer` | button |
| `pickContainer` | pickbutton |
| `removeContainer` | button |

## general / manager

Owner/context: **Controller/layer**. Capability families: **C03**.

| Native control name | Kind |
| --- | --- |
| `layerList` | listbox |
| `editButton` | button |
| `addButton` | button |
| `copyButton` | button |
| `removeButton` | button |
| `nameEdit` | edittext |
| `visibleCheck` | checkbox |
| `enabledCheck` | checkbox |
| `upButton` | button |
| `downButton` | button |

## layer / sourceUI

Owner/context: **Paint-set source row**. Capability families: **C05,C06,C08**.

| Native control name | Kind |
| --- | --- |
| `plantList` | multiListBox |
| `selectFromScene` | button |
| `addPlant` | pickbutton |
| `addSelected` | button |
| `removePlant` | button |
| `selectPlant` | button |
| `addPoint` | button |
| `addEmpty` | button |
| `replacePoint` | pickbutton |
| `existingGroups` | dropdownlist |
| `groupColor` | colorpicker |
| `applyColor` | button |
| `weightSpin` | spinner |
| `sourceZSpin` | spinner |
| `sourceScaleSpin` | spinner |
| `radiusSourceSpin` | spinner |
| `followRadiusCheck` | checkbox |
| `showRadiusCheck` | checkbox |
| `forwardAxis` | dropdownlist |
| `detailsToggle` | checkbutton |

## layer / distributionUI

Owner/context: **Layer defaults**. Capability families: **C09,C11**.

| Native control name | Kind |
| --- | --- |
| `modeRadio` | radiobuttons |
| `populationRadio` | radiobuttons |
| `showCenterCheck` | checkbox |
| `countSpin` | spinner |
| `densitySpin` | spinner |
| `seedSpin` | spinner |
| `densityButton` | mapbutton |
| `invertCheck` | checkbox |

## layer / brushUI

Owner/context: **Paint-set coverage**. Capability families: **C14,C15**.

| Native control name | Kind |
| --- | --- |
| `coverageMode` | dropdownlist |
| `modeRadio` | radiobuttons |
| `radiusSpin` | spinner |
| `strengthSpin` | spinner |
| `softSpin` | spinner |
| `densitySpin` | spinner |
| `beginButton` | button |
| `stopButton` | button |
| `fillButton` | button |
| `emptyButton` | button |
| `overlayMode` | dropdownlist |
| `overlayColor` | colorpicker |
| `strokeList` | listbox |
| `strokeEnabled` | checkbox |
| `strokeErase` | checkbox |
| `strokeRadius` | spinner |
| `strokeStrength` | spinner |
| `strokeSoft` | spinner |
| `deleteStroke` | button |
| `resetTarget` | button |
| `detailsToggle` | checkbutton |

## layer / areaUI

Owner/context: **Layer Area/falloff**. Capability families: **C12,C13**.

| Native control name | Kind |
| --- | --- |
| `areaList` | multiListBox |
| `addAreaScene` | button |
| `pickArea` | pickbutton |
| `removeArea` | button |
| `areaMode` | radiobuttons |
| `refreshAreas` | button |
| `aaPick` | pickbutton |
| `aaRemove` | button |
| `aaLine` | checkbox |
| `aaWidth` | spinner |
| `aaCaps` | dropdownlist |
| `aaStreetOffset` | spinner |
| `aaPoints` | checkbox |
| `aaRadius` | spinner |
| `fallTarget` | dropdownlist |
| `fallPick` | pickbutton |
| `fallRemove` | button |
| `fallDeleteCheck` | checkbox |
| `fallDeleteSpin` | spinner |
| `fallScaleCheck` | checkbox |
| `fallScaleSpin` | spinner |
| `fallScaleEdit` | button |
| `fallDensityCheck` | checkbox |
| `fallDensitySpin` | spinner |
| `fallDensityEdit` | button |
| `detailsToggle` | checkbutton |

## layer / diversityUI

Owner/context: **Layer assignment**. Capability families: **C17,C18**.

| Native control name | Kind |
| --- | --- |
| `diversityRadio` | radiobuttons |
| `sizeSpin` | spinner |
| `divSeedSpin` | spinner |
| `roughSpin` | spinner |
| `blurSpin` | spinner |
| `noiseSpin` | spinner |
| `pathsDrop` | dropdownlist |
| `analyzerChannel` | dropdownlist |
| `pickAnalyzer` | pickbutton |
| `pickPath` | pickbutton |
| `removePath` | button |
| `strokesList` | listbox |
| `addOutside` | button |
| `addInside` | button |
| `removeStrokeButton` | button |
| `strokeWidth` | spinner |
| `strokeMode` | radiobuttons |
| `strokeChoices` | multiListBox |
| `strokeScaleMin` | spinner |
| `strokeScaleMax` | spinner |
| `refreshGroups` | button |
| `edgeOffsetSpin` | spinner |
| `edgeAlongSpin` | spinner |
| `edgeAcrossSpin` | spinner |
| `keepCornerCheck` | checkbox |
| `cornerAngleSpin` | spinner |
| `cornerCountSpin` | spinner |
| `edgeRotXSpin` | spinner |
| `edgeRotYSpin` | spinner |
| `edgeRotZSpin` | spinner |
| `streetStartSpin` | spinner |
| `streetEndSpin` | spinner |
| `centerStreetSpin` | spinner |
| `faceOutCheck` | checkbox |
| `cornerRadiusSpin` | spinner |
| `straightStreet` | checkbox |

## layer / randomUI

Owner/context: **Layer transforms**. Capability families: **C19**.

| Native control name | Kind |
| --- | --- |
| `rotXMinSpin` | spinner |
| `rotXMaxSpin` | spinner |
| `rotYMinSpin` | spinner |
| `rotYMaxSpin` | spinner |
| `rotZMinSpin` | spinner |
| `rotZMaxSpin` | spinner |
| `sclXMinSpin` | spinner |
| `sclXMaxSpin` | spinner |
| `sclYMinSpin` | spinner |
| `sclYMaxSpin` | spinner |
| `sclZMinSpin` | spinner |
| `sclZMaxSpin` | spinner |
| `wholeMinSpin` | spinner |
| `wholeMaxSpin` | spinner |
| `movXMinSpin` | spinner |
| `movXMaxSpin` | spinner |
| `movYMinSpin` | spinner |
| `movYMaxSpin` | spinner |
| `movZMinSpin` | spinner |
| `movZMaxSpin` | spinner |
| `projectCheck` | checkbox |
| `alignCheck` | checkbox |
| `resetRotation` | button |
| `resetScale` | button |
| `resetWholeScale` | button |
| `resetMovement` | button |

## layer / spacingUI

Owner/context: **Self-spacing inheritance or legacy layer**. Capability families: **C20,C23**.

| Native control name | Kind |
| --- | --- |
| `collisionCheck` | checkbox |
| `radiusSpin` | spinner |
| `relaxCheck` | checkbox |
| `spacingSpin` | spinner |
| `iterationsSpin` | spinner |
| `strengthSpin` | spinner |

## layer / separationUI

Owner/context: **Legacy pairs/layer union cleanup**. Capability families: **C20,C22,C23**.

| Native control name | Kind |
| --- | --- |
| `prioritySpin` | spinner |
| `peerList` | listbox |
| `blockerList` | multiListBox |
| `overlapCheck` | checkbox |
| `radiusMode` | dropdownlist |
| `gapSpin` | spinner |
| `radiusSpin` | spinner |
| `planarCheck` | checkbox |
| `statsButton` | button |
| `cleanCheck` | checkbox |
| `neighborSpin` | spinner |
| `minNeighborSpin` | spinner |
| `minIslandSpin` | spinner |
| `boundaryRelaxCheck` | checkbox |
| `finalStrengthSpin` | spinner |
| `finalIterSpin` | spinner |
| `finalMoveSpin` | spinner |

## layer / proceduralUI

Owner/context: **Selected self/sibling/layer rule scope**. Capability families: **C20**.

| Native control name | Kind |
| --- | --- |
| `scopeList` | dropdownlist |
| `peerList` | dropdownlist |
| `enabledCheck` | checkbox |
| `multiplierSpin` | spinner |
| `gapSpin` | spinner |
| `planarCheck` | checkbox |
| `resetRule` | button |

## layer / populationPolicyUI

Owner/context: **Layer work limits**. Capability families: **C10**.

| Native control name | Kind |
| --- | --- |
| `populationList` | dropdownlist |
| `attemptSpin` | spinner |
| `roundSpin` | spinner |
| `repairCheck` | checkbox |

## layer / backgroundUI

Owner/context: **Paint set and earlier siblings**. Capability families: **C16**.

| Native control name | Kind |
| --- | --- |
| `backgroundList` | dropdownlist |
| `referenceList` | multiListBox |
| `applyBackground` | button |

## layer / instanceRadiusUI

Owner/context: **Set/published instance binding**. Capability families: **C21**.

| Native control name | Kind |
| --- | --- |
| `radiusMode` | dropdownlist |
| `radiusSpin` | spinner |
| `applyRadius` | button |
| `resetRadius` | button |
| `clearRadius` | button |

## layer / workflowUI

Owner/context: **Presentation/help**. Capability families: **C26**.

| Native control name | Kind |
| --- | --- |
| No named interactive controls | Presentation/help |

## layer / sourceContainersUI

Owner/context: **Set/layer/global pool selection**. Capability families: **C07**.

| Native control name | Kind |
| --- | --- |
| `modeList` | dropdownlist |
| `containersList` | listbox |
| `createContainer` | button |
| `pickContainer` | pickbutton |
| `removeContainer` | button |

## layer / setsUI

Owner/context: **Layer/set administration**. Capability families: **C04**.

| Native control name | Kind |
| --- | --- |
| `setList` | dropdownlist |
| `addButton` | button |
| `removeButton` | button |
| `nameEdit` | edittext |
| `weightSpin` | spinner |
| `enabledCheck` | checkbox |
| `visibleCheck` | checkbox |
| `upButton` | button |
| `downButton` | button |

## layer / detailsUI

Owner/context: **Cached statistics/help**. Capability families: **C27**.

| Native control name | Kind |
| --- | --- |
| `refreshButton` | button |
| `helpButton` | button |
