-- Preserve the supplied Max 2027 file. Back-save only a disposable input copy.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/refine0791-layer0792-2027-*" do throw "Owned 2027 host required"
if not loadMaxFile (MCPFixtureDir+"artist-layering-input.max") quiet:true useFileUnits:true do throw "Could not load artist copy"
if not saveMaxFile (MCPFixtureDir+"artist-layering-for-max2026.max") saveAsVersion:2026 quiet:true do throw "Could not save private 2026 copy"
)
