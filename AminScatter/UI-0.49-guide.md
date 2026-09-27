# Cyrus Scatter 0.49

Source Object now immediately selects newly added rows and refreshes their controls after viewport picking, Add selected, or Select From Scene. The refresh helper is defined before its caller, avoiding MAXScript forward-binding errors. Duplicate adds retain the current selection.

On opening/reselecting a Cyrus Scatter controller, all layer rollouts start collapsed, as do their child sections and the top-level categories. Rebuilding the layer list while the controller remains open preserves existing open/closed choices.

Script-only update: native engine remains bin48. Restart Max to load the updated script.
