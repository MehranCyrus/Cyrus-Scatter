# Scene presets

In **Layers > Recipes > Save**, choose:

| Save as | Use it for |
| --- | --- |
| **Scene preset** | The complete Max setup, including preparation, instance edits, controllers and collected files. |
| **Portable preset** | Supported static models and settings that can adapt to another terrain. |
| **Settings only** | Settings and Paint; pick the models when loading. |

Scene presets appear in **My recipes** with the other Library cards. **Load**
then **Merge** adds a separate setup in its saved arrangement. Max's standard
merge clears Undo history; the load dialog shows this notice. Existing scene
objects are retained. The portable import keeps its existing behavior.

Scene presets currently require **Max 2027**, matching system units and the
plug-ins used by their objects/materials. They collect the files Max declares;
missing files, nested external scenes and unresolved sequence patterns must be
resolved before saving. Renderer installations and licenses are not bundled.
Use the Library's export/import commands to transfer a library to another system.

**Update selected** replaces a card with a new complete revision. **Edit details**
changes its name, collection, tags or description while reusing its saved files.
The scene being saved is not repathed or updated by saving a preset.

The existing interaction limit still applies: plant interactions require one
Scatter Edit modifier per controller. Stacked edits can be saved and restored
with interactions off. Destination render/environment/colour settings follow
ordinary Max merge behavior.

See the [delivery report](DELIVERY_08751.md) for the installer and exact test scope.
