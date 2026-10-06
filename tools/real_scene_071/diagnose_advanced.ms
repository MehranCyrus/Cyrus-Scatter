(
 global RSAssert,RSRows,RSEqual,RSBind,RSReload,RSAdvancedRecord
 local f=createFile (MCPFixtureDir+"advanced-diagnostic.txt")
 for pair in #(#("assert",RSAssert),#("rows",RSRows),#("equal",RSEqual),#("bind",RSBind),#("reload",RSReload),#("record",RSAdvancedRecord),#("root",RSRoot)) do format "%\n" pair to:f
 try(RSBind();format "bound %\n" RSOwners.count to:f)catch(format "bind error %\n" (getCurrentException()) to:f)
 try(local r=RSRows();format "rows %\n" (for x in r collect x.count) to:f)catch(format "rows error %\n" (getCurrentException()) to:f)
 try(format "assert %\n" (RSAssert true "ok") to:f)catch(format "assert error %\n" (getCurrentException()) to:f)
 try(format "key %\n" (RSRoot.procInputKey()).count to:f)catch(format "key error %\n" (getCurrentException()) to:f)
 close f
)
