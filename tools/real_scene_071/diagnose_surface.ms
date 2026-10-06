(
 RSBind()
 local expected=#(),m=snapshotAsMesh RSSurface,differences=#(),maximum=0.0,faceDifferences=0
 for j=0 to 46 do for i=0 to 60 do (
  local x=-1500+i*50.0,y=-1060+j*50.0,z=80.0*exp(-(((x-1080)/365.0)^2+((y-400)/470.0)^2)*2)
  append expected [x,y,z]
 )
 for i=1 to expected.count do (
  local v=getVert m i,d=distance v expected[i]
  if v!=expected[i] do (if differences.count<30 do append differences #(i,v as string,expected[i] as string,d,(formattedPrint v.z format:".9e"),(formattedPrint expected[i].z format:".9e"));maximum=amax maximum d)
 )
 local fi=1
 for j=0 to 45 do for i=0 to 59 do (
  local a=j*61+i+1,b=a+1,c=a+61,d=c+1
  if getFace m fi!=[a,b,d] do faceDifferences+=1
  fi+=1
  if getFace m fi!=[a,d,c] do faceDifferences+=1
  fi+=1
 )
 CSPWriteText (MCPFixtureDir+"surface-diagnostic.json") (CSPObject #(#("verts",m.numverts),#("faces",m.numfaces),#("transform",RSSurface.objectTransform as string),#("maximum_difference",maximum),#("differences",differences),#("face_differences",faceDifferences)))
)
