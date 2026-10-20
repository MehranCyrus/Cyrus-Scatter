# Native modifier and viewport control

This describes the qualified 0.3.1 presentation implementation. Actual host,
installer and example evidence belongs to [the release record](REAL_WORLD_0.3.1.md).

## Scene ownership

`CyrusArrange` is a public native C++ object-space modifier named **Cyrus
Arrange**. It passes furniture geometry through unchanged. `CyrusArrangeIcon`
is the native helper used for new arrangements. Its cyan wire diamond and C
identify a selectable arrangement control; it is nonrenderable. New icons have
the Cyrus Arrange modifier in their stack.

Neither class owns an additional arrangement document. The existing native
owner attribute on the setup node still owns the one Document, whose native
references bind furniture, source props, generated output and obstacles. Saved
document, library and registry formats remain 4, 2 and 1. The modifier and icon
do not compute placement during evaluation, viewport display or selection.

| Native class | Class ID | Purpose |
| --- | --- | --- |
| Document | `6a4387d1,4fa90372` | Existing native arrangement authority |
| Owner attribute | `6a4387d2,4fa90372` | Existing setup-to-Document ownership |
| Cyrus Arrange modifier | `6a4387d3,4fa90372` | Public Modify entry and pass-through evaluation |
| Cyrus Arrange Icon | `6a4387d4,4fa90372` | Selectable viewport setup control |

## MAXScript view lifetime

The native panel resolves the actual edited node through its modifier contexts,
then resolves a unique native setup. A selected object with several applicable
setups must be disambiguated by choosing an arrangement icon. Opening a view
does not silently create another arrangement or register furniture.

The view factory constructs a temporary, off-scene modifier containing a real
scripted custom attribute (presentation class ID `6a4387d5,4fa90372`). Its
class-defined MAXScript rollout is shared; each attribute instance keeps its
own temporary owner, context and session binding. It contains UI controls, rather
than a second set of authored arrangement parameters. The C++ panel retains
the temporary native objects and MAXScript values until it ends editing, and
dispatches through the actual attribute's BeginEditParams/EndEditParams methods.
The temporary view is never attached to a scene node or saved with the scene.
Its creation and cleanup suspend recording into the artist's Undo hold.

This uses Max's scripted attribute UI machinery to supply the correct plugin
and rollup context. See the official [scripted attribute guide](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/3ds-Max-Objects-and-Interfaces/Custom-Attributes/GUID-ADFD29E4-9751-4F55-98CC-F7C721C9AEE2.html)
and [MSCustAttrib API](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_m_s_cust_attrib.html).
These APIs document the components; isolated host tests must establish the
complete temporary-view integration and its cleanup behavior.

Rollout locals reset on every open. The open handler hydrates them from the
actual attribute instance, then commands carry that instance and its session
serial. The rollout's `owner` value is available inside its event context;
external reads returned undefined in the tested host, so external callers use
the captured active attribute. No authored state depends on this getter.

The rollout captures both setup identity and native Document GUID before
authored actions. Selection changes can close it while a Props operation runs;
commands retain the intended owner and refuse stale or replaced documents.
Each instance clears its own binding on close. Native generation guards prevent
an earlier edit session from releasing a reentrant successor's view. Scene
state changes still run through the existing native transactional commands.

## Hosting failure found during development

The original standalone-rollout attempt was rejected by actual normal-Max
testing. A first-chance native dump showed control initialization receiving a
null custom-button interface because its rollout page HWND was zero. Bounded
disassembly and compile-only SDK virtual-call probes then showed that
Rollout::add_page's no-plugin path explicitly selects Utilities mode (6) and
uses Interface's utility rollup operation. It was the wrong host for a native
Modify panel. Editing hidden flags or assigning the rollout's interface field
did not repair that route.

The successor uses a genuine temporary scripted attribute and its standard
virtual edit methods. It does not fabricate an MSPlugin context, patch rollout
flags or embed a floating window over the command panel. The development dump,
failed hosts and diagnostic tools are retained outside the shipped runtime.

## Viewport behavior and acceptance

At unit scale the icon's local envelope is 120 × 120 × 48 mm. Drawing and
hit-testing use the node transform, with graphics transform and render limits
restored afterward. Moving the icon does not change furniture or saved output
poses, including a later repeated-seed generation. The icon's transform affects
its own display and selection envelope.

Acceptance requires an actual Modify-mode page with a live HWND, usable control
bounds and the correct edited context. It also checks native class identity,
passive cache/placement invariance, temporary-view isolation, Props callbacks,
seed handling, Undo/Redo, clone/delete/load and stale Document rejection.
Separate native viewport tests call the real Display and HitTest methods and
inspect their captured glyphs. A Batch geometry pass alone proves neither
command-panel presentation nor viewport appearance.
