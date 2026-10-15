(
 local b=CyrusRecipeBrowser,t=dotNetObject "System.Diagnostics.Stopwatch",s=stringStream ""
 for mode=1 to 3 do (
  t.Restart()
  for k=1 to 10 do (
   if mode==1 do local f=getFiles (pathConfig.appendPath b.directory "*.csrecipe.json")
   if mode==2 do for i=1 to 128 do (local f=dotNetObject "System.IO.FileInfo" b.files[i];local a=f.Length;local z=f.LastWriteTimeUtc.Ticks)
   if mode==3 do local f=(dotNetObject "System.IO.DirectoryInfo" b.directory).GetFiles "*.csrecipe.json"
  )
  format "%: % ms\n" mode (t.Elapsed.TotalMilliseconds/10.0) to:s
 )
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"recipe-profile.txt") (s as string)
)
