P07New count:100
local r=P07Root,a=P07Layer,source=P07Source
source.radius1=25;source.height=85
source.material=CoronaPhysicalMtl baseColor:(color 35 130 50)
P07Surface.material=CoronaPhysicalMtl baseColor:(color 150 145 125)
local cam=targetCamera name:"Fix Render Camera" pos:[-800,-1200,1100] target:(targetObject pos:[0,0,0])
local sun=CoronaSun();sun.targeted=true;sun.target.pos=[0,0,0];sun.pos=[-1000,-1800,2800];sun.sizeMultiplier=4;sun.intensity=.7
local sky=CoronaSky();sky.selectedSun=sun;sky.sunSelectionMode=1;environmentMap=sky;useEnvironmentMap=true
renderers.current=Corona();renderers.current.system_numThreads=8;renderers.current.progressive_passLimit=1;renderers.current.progressive_timeLimit=0
r.autoRender=true;r.proxyShape=2;r.setGroupDisplay 2;r.refreshAll();F75Settle();r.refreshAll()
local before=P07Fingerprint r,epoch=r.procEpoch,clock=dotNetObject "System.Diagnostics.Stopwatch"
clock.Start();local b=render camera:cam outputwidth:320 outputheight:240 vfb:false;clock.Stop()
b.filename=MCPFixtureDir+"sphere-proxy-final-render.png";save b;close b
F75Check (CyrusPFLastError=="" and (P07Fingerprint r) as string==before as string and r.procEpoch==epoch) "Corona production render preserves the scatter publication in Sphere Proxy mode"
F75Check (not (CyrusPointOwner P07Node).renderable) "Proxy helper remains nonrenderable after production render"
CSPWriteText (MCPFixtureDir+"render-check.json") (CSPObject #(#("passed",true),#("ms",clock.Elapsed.TotalMilliseconds),#("renderer",CoronaRenderer.getVersionString()),#("count",a.generatedCount),#("error",CyrusPFLastError),#("epoch_preserved",r.procEpoch==epoch)))
r.autoRender=false;CyrusPFClear()
