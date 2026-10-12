# Shared dropdown design — 11 October 2026

All seven active native select fields now use `src/components/SelectField.tsx` and its scoped stylesheet: the control catalog's feature section, exact UI section, setting owner and capability family filters, plus the visual lessons' spacing relationship, update mode and display mode.

The design uses ivory fields, fine green borders, a rotating chevron, softly highlighted options and a selected checkmark. Long menus are wider, wrap their labels and scroll independently. A fixed portal positions each popup above or below its trigger according to available viewport space. Catalog labels and fields are grouped together; small screens use a single readable column. Existing values, URL filters and lesson state remain connected to the same owners.

The select-only combobox keeps focus on its trigger, exposes its label/value and active option, supports arrows, Home/End, Enter/Space, typeahead, Escape and Tab, and closes on outside interaction. Pointer exploration does not change the committed value. Touch movement does not invoke mouse hover scrolling. Reduced-motion preferences disable menu/chevron animation. No UI library or additional runtime dependency was added.

## Evidence

Strict TypeScript/Vite production build passed. **31 focused dropdown assertions and 45 existing interaction assertions passed** against the final production build (`index-75oxJK8Z.js`). Desktop 1440 × 1000 and mobile 390 × 844 screenshots were inspected; resizing an open popup to 360 × 640 was also checked.

The checks cover all seven values and their connections, keyboard exploration versus commitment, typeahead, pointer selection, focus retention, Escape/Tab/outside dismissal, long-list scrolling, filter URL changes, reset, mobile label pairing, viewport bounds and no browser exceptions. During verification, the initial long-list End handling was corrected to scroll only the options after popup positioning. These are browser checks; a dedicated screen-reader session and physical-device touch session were not performed.

Reproduce with `tools/check_dropdowns.py --browser <agent-browser executable> --url http://127.0.0.1:5180/ --output <fresh directory>/checks.json` and `tools/check_selected_interactions.py` with the same browser/URL/output arguments. Exact receipts, CLI logs and screenshots are preserved in ignored `build/dropdowns-20261011/accepted/`; the regression receipt is in its `regression/` directory. Earlier failed runs are retained separately.

This iteration changes only the website and its verification files. It does not resolve the existing public documentation-import manifest block, qualify Max runtime, install, commit, push or deploy. Concurrent plugin, licensing and documentation changes remain preserved.
