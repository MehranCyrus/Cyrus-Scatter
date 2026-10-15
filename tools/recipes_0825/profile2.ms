(
 local b=CyrusRecipeBrowser,t=dotNetObject "System.Diagnostics.Stopwatch",s=stringStream "",hits=0,misses=0
 t.Start()
 for i=1 to 128 do (
  local p=b.files[i],info=dotNetObject "System.IO.FileInfo" p,size=info.Length,stamp=info.LastWriteTimeUtc.Ticks
  local j=if b.metadataIndex.ContainsKey p then b.metadataIndex.Item[p] else 0
  if j==0 then misses+=1 else if b.metadataCache[j][2]!=size or b.metadataCache[j][3]!=stamp then misses+=1 else hits+=1
 )
 format "metadata=% hits=% misses=% cache=%\n" t.Elapsed.TotalMilliseconds hits misses b.metadataCache.count to:s
 t.Restart();for k=1 to 10 do b.refresh();format "refresh=%\n" (t.Elapsed.TotalMilliseconds/10.0) to:s
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-profile2.txt") (s as string)
)
