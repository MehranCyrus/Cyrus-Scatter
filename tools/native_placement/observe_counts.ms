-- After the timed run: explicit live reachability at each equal final state.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativeobserve-*/" do throw "Owned N01 observation host required."
 local io=dotNetClass "System.IO.File",script="F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/native_placement/baseline.ms"
 for amount in #(200000,90000,50000,5000) do (
  io.WriteAllText (MCPFixtureDir+"native-baseline-command.txt") ("sample "+(amount as string)+" 11")
  fileIn script
  io.WriteAllText (MCPFixtureDir+"native-baseline-command.txt") "observe"
  fileIn script
 )
)
