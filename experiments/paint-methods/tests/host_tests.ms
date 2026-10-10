-- Invocation-only qualification in the owned profile created by tools/host.py.
(
 local log=createFile (PaintLabRun+"checks.tsv"), timing=createFile (PaintLabRun+"timings.csv"), checks=0
 fn require cond message stream = (if not cond do throw message;format "PASS\t%\n" message to:stream;flush stream)
 fn anchorAt receiver p = (
  local m=snapshotAsMesh receiver, localPoint=p
  for face=1 to m.numfaces do (
   local indices=getFace m face
   local a=getVert m indices.x, b=getVert m indices.y, c=getVert m indices.z
   local e=b-a, f=c-a, q=localPoint-a
   local d00=dot e e,d01=dot e f,d11=dot f f,d20=dot q e,d21=dot q f
   local denominator=d00*d11-d01*d01
   if abs denominator>0.000001 do (
    local u=(d11*d20-d01*d21)/denominator, v=(d00*d21-d01*d20)/denominator
    if u>=-0.00001 and v>=-0.00001 and u+v<=1.00001 do return #(face,[1-u-v,u,v])
   )
  )
  throw "Fixture could not locate point on mesh"
 )

 fn put api id receiver p radius erase:false strength:1.0 softness:0.0 = (
  local h=anchorAt receiver p
  api "begin" #(id,erase,strength,softness)
  api "dab" #(id,h[1],h[2],radius,false)
  api "commit" #(id)
 )
 fn weight api id receiver p = (local h=anchorAt receiver p;api "query" #(id,h[1],h[2]))
 format "method,phase,elapsed_ms,items,state_bytes,history_logical_bytes,lines,fill_faces,samples\n" to:timing
 try (
  require (paintLabA!=undefined and paintLabB!=undefined and paintLabC!=undefined and paintLabD!=undefined) "Four native APIs loaded" log
  for method=1 to 4 do (
   local api=(#(paintLabA,paintLabB,paintLabC,paintLabD))[method]
   local receiver=plane name:("Lab_Surface_"+method as string) length:1000 width:1000 lengthsegs:1 widthsegs:1
   local id=api "create" #(receiver,2.0)
   put api id receiver [0,0,0] 100
   require ((weight api id receiver [0,0,0])>0.5 and (weight api id receiver [200,0,0])==0) ("M"+method as string+" hard disk") log
   put api id receiver [0,0,0] 30 erase:true
   require ((weight api id receiver [0,0,0])==0) ("M"+method as string+" erase hole") log
   api "undo" #(id)
   require ((weight api id receiver [0,0,0])>0.5) ("M"+method as string+" Undo") log
   api "redo" #(id)
   require ((weight api id receiver [0,0,0])==0) ("M"+method as string+" Redo") log
   api "begin" #(id,false,1.0,0.0)
   local h=anchorAt receiver [250,250,0]
   api "dab" #(id,h[1],h[2],40.0,false)
   api "cancel" #(id)
   require ((weight api id receiver [250,250,0])==0) ("M"+method as string+" Cancel") log
   local file=PaintLabRun+"method-"+method as string+".plab"
   api "save" #(id,file)
   api "clear" #(id)
   require ((weight api id receiver [60,0,0])==0) ("M"+method as string+" Clear") log
   api "load" #(id,file)
   require ((weight api id receiver [60,0,0])>0.5) ("M"+method as string+" external save/load") log
   local sw=dotNetObject "System.Diagnostics.Stopwatch"
   sw.Start()
   for i=0 to 23 do put api id receiver [-400+(mod i 6)*150,-400+(floor(i/6))*230,0] 20
   sw.Stop()
   for i=0 to 23 do require ((weight api id receiver [-400+(mod i 6)*150,-400+(floor(i/6))*230,0])>0.5) ("M"+method as string+" growing island "+i as string) log
   local s=api "stats" #(id)
   format "%,growing_24,%,%,%,%,%,%,%\n" method sw.Elapsed.TotalMilliseconds s[2] s[3] s[4] s[9] s[10] s[11] to:timing
   sw.Restart();api "refresh" #(id,25.0,true,true);sw.Stop();s=api "stats" #(id)
   require (s[9]>0 and s[10]>0 and s[11]>0) ("M"+method as string+" complete boundary/fill/samples") log
   format "%,preview,%,%,%,%,%,%,%\n" method sw.Elapsed.TotalMilliseconds s[2] s[3] s[4] s[9] s[10] s[11] to:timing
   local previousBuild=s[5]
   for i=1 to 5 do redrawViews()
   s=api "stats" #(id)
   require (s[5]==previousBuild) ("M"+method as string+" redraw consumes cache") log
   local refused=false
   try(api "refresh" #(id,0.001,true,true))catch(refused=true)
   require (refused and (weight api id receiver [-400,-400,0])>0.5) ("M"+method as string+" display limit retains paint") log
   api "refresh" #(id,25.0,true,false)
   select receiver
   viewport.setType #view_top
   max zoomext sel all
   api "start" #(id,80.0,false,1.0,0.0)
   require (abs ((api "painterRadius" #(id))-80.0)<0.001) ("M"+method as string+" Painter SDK radius calibration") log
   api "replayScreen" #(id,#([-200,180,0],[0,180,0],[200,180,0]))
   require ((weight api id receiver [0,180,0])>0.5) ("M"+method as string+" screen ray callback path") log
   require ((weight api id receiver [0,240,0])>0.5 and (weight api id receiver [0,280,0])==0) ("M"+method as string+" callback uses configured radius") log
   api "stop" #(id)
   local times=api "eventTimes" #(id)
   local samples=createFile (PaintLabRun+"callbacks-"+method as string+".csv")
   for t in times do format "%\n" t to:samples
   close samples
   require true ("M"+method as string+" Painter Start/Stop") log
   if method!=1 do (
    local softid=api "create" #(receiver,2.0)
    put api softid receiver [50,0,0] 80 strength:0.5 softness:0.5
    require ((weight api softid receiver [50,0,0])>0.45) ("M"+method as string+" soft density") log
   )
   delete receiver
   local inactive=false
   try(weight api id receiver [0,0,0])catch(inactive=true)
   require inactive ("M"+method as string+" deleted receiver inactive") log
   api "shutdown" #()
  )
  -- Compile and create each real UI, then close it without using pointer automation.
  local lab=PaintLabSource
  for pair in #(#("01-vector-regions","PL_A"),#("02-tiled-mask","PL_B"),#("03-surface-volumes","PL_C"),#("04-surface-field","PL_D")) do (
   fileIn (lab+"/methods/"+pair[1]+"/scripts/Launch.ms")
   local window=execute pair[2]
   local receiver=plane name:("UI_"+pair[2]) length:1000 width:1000 lengthsegs:1 widthsegs:1
   window.addReceiver receiver
   require (window.region()>0) (pair[2]+" UI receiver binding") log
   window.beginPainting()
   window.endPainting()
   execute ("destroyDialog "+pair[2])
   (execute ("paintLab"+substring pair[2] 4 1)) "shutdown" #()
   require true (pair[2]+" UI compiled and opened") log
  )
  for method=1 to 4 do (
   local api=(#(paintLabA,paintLabB,paintLabC,paintLabD))[method]
   local sphereNode=sphere name:"Curved_Receiver" radius:150 segs:24
   if method<3 then (
    local rejected=false
    try(api "create" #(sphereNode,3.0))catch(rejected=true)
    require rejected ("M"+method as string+" sphere domain rejected explicitly") log
   ) else (
    local id=api "create" #(sphereNode,3.0)
    api "begin" #(id,false,1.0,0.0)
    api "dab" #(id,1,[0.33333333,0.33333333,0.33333333],30.0,false)
    api "commit" #(id)
    require ((api "query" #(id,1,[0.33333333,0.33333333,0.33333333]))>0.5) ("M"+method as string+" sphere paint") log
    api "begin" #(id,true,1.0,0.0)
    api "dab" #(id,1,[0.33333333,0.33333333,0.33333333],10.0,false)
    api "commit" #(id)
    require ((api "query" #(id,1,[0.33333333,0.33333333,0.33333333]))==0) ("M"+method as string+" sphere erase") log
   )
   delete sphereNode
   api "shutdown" #()
   local receivers=#(),ids=#()
   for i=1 to 21 do (
    local node=plane name:("Owned_"+method as string+"_"+i as string) length:1000 width:1000 lengthsegs:1 widthsegs:1 pos:[i*2000,0,0]
    append receivers node
    append ids (api "create" #(node,5.0))
   )
   put api ids[1] receivers[1] [2000,0,0] 40
   require ((weight api ids[1] receivers[1] [2000,0,0])>0.5 and (weight api ids[21] receivers[21] [42000,0,0])==0) ("M"+method as string+" 21 independent receivers") log
   api "shutdown" #()
   for node in receivers do delete node
   local receiver=plane name:"LargeCoverage" length:1000 width:1000 lengthsegs:1 widthsegs:1
   local id=api "create" #(receiver,2.0)
   put api id receiver [0,0,0] 400
   local sw=dotNetObject "System.Diagnostics.Stopwatch"
   sw.Start();api "refresh" #(id,4.0,false,true);sw.Stop()
   local s=api "stats" #(id)
   require (s[10]>32768) ("M"+method as string+" complete tint exceeds old 32768 limit") log
   format "%,large_coverage,%,%,%,%,%,%,%\n" method sw.Elapsed.TotalMilliseconds s[2] s[3] s[4] s[9] s[10] s[11] to:timing
   put api id receiver [450,450,0] 25
   api "refresh" #(id,4.0,false,true)
   require ((weight api id receiver [0,0,0])>0.5 and (weight api id receiver [450,450,0])>0.5) ("M"+method as string+" large tint retains both regions") log
   api "shutdown" #()
   delete receiver
  )

 )catch(close log;close timing;throw())
 close log;close timing
)
