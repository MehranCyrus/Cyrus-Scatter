loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-dense-probe-20261024-06/" "CyrusDenseVegetationProbe.dlx"
(
    cvlStage "load owned pointer scene"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-dense-live-20261024-04/Dense_Lavender_Bent_Max2027.max" quiet:true useFileUnits:true
    local source=getNodeByName "CyrusModel_A084"
    global DVPOutput=getNodeByName "DVP_Dense_Lavender_Output",DVPSphere=getNodeByName "DVP_Moving_Sphere",DVPHandle=dvpPrepare source
    local bounds=nodeGetBoundingBox source (matrix3 1),height=bounds[2].z-bounds[1].z
    local origin=[(bounds[1].x+bounds[2].x)*.5,(bounds[1].y+bounds[2].y)*.5,bounds[1].z]
    DVPSphere.pos=origin+[height*.34,0,height*.65]
    (dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"original-geometry-intrusion.json") (dvpAudit DVPHandle DVPSphere)
    DVPSphere.pos=origin+[height*.7,0,height*.65]
    dvpUpdate DVPHandle DVPSphere DVPOutput (units.decodeValue "1mm")
    viewport.setLayout #layout_1;viewport.setType #view_front;viewport.setRenderLevel #smoothhighlights
    select #(DVPOutput,DVPSphere);max zoomext sel all
    select DVPSphere;max move
    saveMaxFile (CVLTestDir+"DVP_OWNED_POINTER_TEST_20261024.max") quiet:true
    dvpWatch DVPHandle DVPSphere DVPOutput (units.decodeValue "1mm")
    local io=dotNetClass "System.IO.File"
    io.WriteAllText (CVLTestDir+"pointer-ready.json") (dvpStats DVPHandle)
    cvlStage "ready for physical sphere drag"
    local deadline=timeStamp()+300000,nextLog=0
    while timeStamp()<deadline and not doesFileExist (CVLTestDir+"finish-pointer.txt") do
    (
        windows.processPostedMessages()
        if timeStamp()>nextLog do (io.WriteAllText (CVLTestDir+"pointer-progress.json") (dvpStats DVPHandle);nextLog=timeStamp()+250)
        sleep .015
    )
    dvpStop DVPHandle
    io.WriteAllText (CVLTestDir+"pointer-final.json") (dvpStats DVPHandle)
    saveMaxFile (CVLTestDir+"DVP_OWNED_POINTER_RESULT_20261024.max") quiet:true
    cvlStage "physical test finished"
)
