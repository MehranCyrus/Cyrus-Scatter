-- Private fixture protocol. Never included in product packages or public MCP.
global QAssertions,QAssert,QExecute,QQuote
fn QQuote value = (
    local text=value as string
    text=substituteString text "\\" "\\\\";text=substituteString text "\"" "\\\""
    text=substituteString text "\r" "\\r";text=substituteString text "\n" "\\n";text=substituteString text "\t" "\\t"
    "\""+text+"\""
)
fn QAssert value id detail = (
    append QAssertions #(id,value,detail)
    if not value do throw (id+": "+detail)
    true
)
fn QExecute fixture destination = (
    if not matchPattern MCPFixtureDir pattern:"*/build/*" do throw "Owned fixture profile required"
    QAssertions=#();local error="",stream=stringStream ""
    try(fileIn fixture)catch(error=getCurrentException()+"\nSOURCE: "+(getErrorSourceFileName() as string)+" LINE: "+(getErrorSourceFileLine() as string)+"\n"+getCurrentExceptionStackTrace())
    format "{\"schema\":\"cyrus.max-scenario/1\",\"run_id\":%,\"request_id\":%,\"scenario_id\":%,\"artifact_id\":%,\"terminal\":\"complete\",\"status\":%,\"error\":%,\"assertions\":[" (QQuote QRunID) (QQuote QRequestID) (QQuote QScenarioID) (QQuote QArtifactID) (QQuote (if error=="" and QAssertions.count>0 then "pass" else "fail")) (QQuote error) to:stream
    for i=1 to QAssertions.count do (
        local row=QAssertions[i]
        format "%{\"id\":%,\"status\":%,\"detail\":%}" (if i>1 then "," else "") (QQuote row[1]) (QQuote (if row[2] then "pass" else "fail")) (QQuote row[3]) to:stream
    )
    format "]}" to:stream
    local io=dotNetClass "System.IO.File",temporary=destination+".tmp"
    io.WriteAllText temporary (stream as string);io.Move temporary destination
)
