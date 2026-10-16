(
 local out=createFile (MCPFixtureDir+"bitmap-controller-probe-"+(timeStamp() as string)+".txt")
 local value=bitmaptexture filename:GalleryBitmapSourcePNG
 animate on (at time 0 value.coords.U_Offset=0;at time 10 value.coords.U_Offset=0.25)
 for target in #(value.coords,value.output,(standardMaterial())) do (
  format "TARGET % animated=% subs=% refs=%\n" (classof target) "probe" target.numSubs (refs.getNumRefs target) to:out
  for key in getPropNames target do try(local c=getPropertyController target key;if c!=undefined do format "PROPERTY % controller=% keys=%\n" key (classof c) (numKeys c) to:out)catch(format "PROPERTY % ERROR %\n" key (getCurrentException()) to:out)
  for i=1 to target.numSubs do format "SUB % % %\n" i (getSubAnimName target i) (getSubAnim target i) to:out
 )
 close out
)
