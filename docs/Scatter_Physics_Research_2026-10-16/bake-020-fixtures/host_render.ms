fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
bNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-bake-020-installed-02/baked-stack.max" quiet:true useFileUnits:true) "Render stack scene failed to reopen"
(
 local lab=getNodeByName "Stack_Lab_020",ground=getNodeByName "Stack_Ground_020"
 hide lab;hide ground
 local target=targetObject name:"RenderTarget_020" pos:[0,0,.25]
 local camera=targetCamera name:"RenderCamera_020" pos:[1.8,-2.5,1.8] target:target
 renderers.current=Default_Scanline_Renderer()
 backgroundColor=color 70 70 70;ambientColor=color 20 20 20
 local light=omniLight name:"Key_020" pos:[2,-3,4] multiplier:1
 local bitmap=render camera:camera outputWidth:400 outputHeight:300 vfb:false progressBar:false
 bitmap.filename=CPLTestDir+"baked-material-render.png";save bitmap
 local colored=0,black=0
 for y=0 to 299 do
 (
  local pixels=getPixels bitmap [0,y] 400
  for pixel in pixels do
  (
   if (amax pixel.r (amax pixel.g pixel.b))-(amin pixel.r (amin pixel.g pixel.b))>25 do colored+=1
   if pixel.r<3 and pixel.g<3 and pixel.b<3 do black+=1
  )
 )
 close bitmap
 bNeed (colored>2000) "Baked material render has no visible colours"
 bNeed (black<1000) "Baked render contains black silhouettes"
 bWrite "render-counts.txt" ((colored as string)+" coloured pixels; "+(black as string)+" black pixels")
)
