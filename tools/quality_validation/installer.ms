(
 if not matchPattern MCPFixtureDir pattern:"*/build/refinement-08683-20261022/*" do throw "Owned installer profile required"
 python.ExecuteFile ((getFilenamePath(getSourceFileName()))+"installer.py")
 local result=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"installer-"+QRequestID+".json")
 if findString result "\"status\": \"passed\""==undefined do throw result
 QAssert true (QScenarioID+"-01") "Exact Analyzer installer, host guard, immutable pair, repeat, tamper, rollback and recovery passed"
)
