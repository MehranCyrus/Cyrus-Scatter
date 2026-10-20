/* Cyrus Camera Exporter 0.1.1 -- standalone, 3ds Max 2027 only.
   Samples evaluated world transforms; never creates or modifies animation keys.
   Run through Scripting > Run Script. See README.md for projection limitations. */
global CyrusCameraExporterNoUI, CyrusCameraExporterDialog
global CyrusExportCameraAnimation

fn CyrusExportCameraAnimation camera outputPath startFrame endFrame samplesPerFrame:4 = (
    if (maxVersion())[1] < 29000 or (maxVersion())[1] >= 30000 do throw "Cyrus Camera Exporter requires 3ds Max 2027."
    if not isValidNode camera do throw "Choose a valid camera."
    local cameraType=classOf camera
    if findItem #(FreeCamera,TargetCamera,Physical) cameraType == 0 do throw "Supported cameras: native Free, Target and Physical. Bake third-party camera rigs to a supported camera first."
    if findItem #(1,2,4) samplesPerFrame == 0 do throw "Samples per frame must be 1, 2 or 4."
    local startTick=((startFrame as time) as integer), endTick=((endFrame as time) as integer)
    if endTick<=startTick or (endTick-startTick)>17280000 do throw "Choose a positive range of at most one hour."
    local stepTick=amax 1 ((ticksPerFrame as float)/samplesPerFrame as integer)
    local count=(ceil ((endTick-startTick) as double / stepTick) as integer)+1
    if count>20000 do throw "Camera animation exceeds 20,000 samples. Reduce the range or sampling rate."
    if outputPath==undefined or getFilenameType outputPath!=".json" do throw "Choose a .json output file."
    local aspect=(renderWidth as double)*renderPixelAspect/renderHeight
    if aspect<0.3 or aspect>4 do throw "Render aspect must be between 0.3 and 4."
    local metres=1.0/(units.decodeValue "1m")
    local culture=(dotNetClass "System.Globalization.CultureInfo").InvariantCulture
    fn cyrusNumber value culture = ((dotNetObject "System.Double" value).ToString "R" culture)
    fn quoted value = (
        local text=dotNetObject "System.Text.StringBuilder"
        text.Append "\""
        for i=1 to value.count do (
            local ch=value[i], code=bit.charAsInt value[i]
            case ch of (
                "\"": text.Append "\\\""
                "\\": text.Append "\\\\"
                default: if code<32 then text.Append ("\\u"+(formattedPrint code format:"04x")) else text.Append ch
            )
        )
        text.Append "\"";text.ToString()
    )
    fn axis v = [v.x,v.z,-v.y]
    fn cameraQuaternion tm = (
        local r=[tm.row1.x,tm.row1.z,-tm.row1.y],u=[tm.row2.x,tm.row2.z,-tm.row2.y],b=[tm.row3.x,tm.row3.z,-tm.row3.y]
        local lengths=[length r,length u,length b]
        if amin lengths.x lengths.y lengths.z < 1e-8 do throw "Degenerate camera rig transform."
        if abs(lengths.x-lengths.y)>1e-4*lengths.x or abs(lengths.x-lengths.z)>1e-4*lengths.x do throw "Nonuniform camera rig scale is unsupported. Reset the rig scale before exporting."
        r=normalize r;u=normalize u;b=normalize b
        if abs(dot r u)>1e-4 or abs(dot r b)>1e-4 or abs(dot u b)>1e-4 or dot r (cross u b)<0.999 do throw "Sheared or mirrored camera rig is unsupported."
        local trace=r.x+u.y+b.z, x,y,z,w,s
        if trace>0 then (
            s=sqrt(trace+1)*2;w=0.25*s;x=(u.z-b.y)/s;y=(b.x-r.z)/s;z=(r.y-u.x)/s
        ) else if r.x>u.y and r.x>b.z then (
            s=sqrt(1+r.x-u.y-b.z)*2;w=(u.z-b.y)/s;x=0.25*s;y=(u.x+r.y)/s;z=(b.x+r.z)/s
        ) else if u.y>b.z then (
            s=sqrt(1+u.y-r.x-b.z)*2;w=(b.x-r.z)/s;x=(u.x+r.y)/s;y=0.25*s;z=(b.y+u.z)/s
        ) else (
            s=sqrt(1+b.z-r.x-u.y)*2;w=(r.y-u.x)/s;x=(b.x+r.z)/s;y=(b.y+u.z)/s;z=0.25*s
        )
        local size=sqrt(x*x+y*y+z*z+w*w)
        #(x/size,y/size,z/size,w/size)
    )
    fn verticalFov camera cameraType aspect = (
        if cameraType==Physical then (
            for key in #(#horizontal_shift,#vertical_shift,#horizontal_tilt_correction,#vertical_tilt_correction) do if abs(getProperty camera key)>1e-6 do throw "Lens shift and tilt are unsupported. Export a centered perspective camera."
            if camera.auto_vertical_tilt_correction do throw "Automatic vertical tilt correction is unsupported."
            if camera.distortion_type!=0 do throw "Physical lens distortion is unsupported."
        ) else if camera.orthoProjection do throw "Orthographic cameras are unsupported."
        -- Native Physical .fov evaluates its focal length, zoom and focus breathing.
        local horizontal=camera.fov
        local vertical=2*atan((tan(horizontal/2))/aspect)
        if vertical<10 or vertical>110 do throw "Vertical camera FOV is outside the supported 10 to 110 degree range."
        vertical
    )
    local builder=dotNetObject "System.Text.StringBuilder"
    builder.Append ("{\"format\":\"cyrus-camera-animation\",\"version\":1,\"units\":\"metres\",\"up\":\"Y\",\"name\":"+(quoted (substring camera.name 1 (amin camera.name.count 200)))+",\"fps\":"+(cyrusNumber frameRate culture)+",\"aspect\":"+(cyrusNumber aspect culture)+",\"source\":{\"application\":\"3ds Max 2027\",\"exporterVersion\":\"0.1.1\",\"cameraType\":"+(quoted (if cameraType==FreeCamera then "FreeCamera" else if cameraType==TargetCamera then "TargetCamera" else "Physical"))+",\"startTick\":"+(startTick as string)+",\"endTick\":"+(endTick as string)+",\"ticksPerSecond\":4800,\"samplesPerFrame\":"+(samplesPerFrame as string)+"},\"samples\":[")
    for i=0 to count-1 do (
        local tick=amin endTick (startTick+i*stepTick), pose, rotation, fov
        at time (tick as time / ticksPerFrame) (
            local tm=camera.transform
            pose=(axis tm.row4)*metres;rotation=cameraQuaternion tm;fov=verticalFov camera cameraType aspect
        )
        if amin pose.x pose.y pose.z < -10000000 or amax pose.x pose.y pose.z > 10000000 do throw "Camera exceeds admitted world bounds."
        if i>0 do builder.Append ","
        builder.Append ("{\"time\":"+(cyrusNumber ((tick-startTick) as double/4800) culture)+",\"position\":["+(cyrusNumber pose.x culture)+","+(cyrusNumber pose.y culture)+","+(cyrusNumber pose.z culture)+"],\"quaternion\":["+(cyrusNumber rotation[1] culture)+","+(cyrusNumber rotation[2] culture)+","+(cyrusNumber rotation[3] culture)+","+(cyrusNumber rotation[4] culture)+"],\"fov\":"+(cyrusNumber fov culture)+"}")
    )
    builder.Append "]}"
    local encoding=dotNetObject "System.Text.UTF8Encoding" false, text=builder.ToString()
    if encoding.GetByteCount text>4194304 do throw "Camera animation exceeds the 4 MiB file limit."
    local io=dotNetClass "System.IO.File", guid=(dotNetClass "System.Guid").NewGuid()
    local temp=outputPath+"."+(guid.ToString "N")+".tmp"
    try (
        io.WriteAllText temp text encoding
        if io.Exists outputPath then (
            local backup=temp+".bak"
            io.Replace temp outputPath backup
            try(io.Delete backup)catch()
        ) else io.Move temp outputPath
    ) catch (
        if io.Exists temp do io.Delete temp
        throw()
    )
    #(outputPath,count,(endTick-startTick) as double/4800)
)

if CyrusCameraExporterNoUI!=true do (
    try(destroyDialog CyrusCameraExporterDialog)catch()
    rollout CyrusCameraExporterDialog "Cyrus Camera Exporter 0.1.1" width:340 (
        local selectedCamera=undefined
        label intro "Export evaluated camera movement for Cyrus Studio." align:#left
        pickButton choose "Choose camera" width:310 autoDisplay:true
        spinner first "Start frame" range:[-1000000,1000000,0] type:#integer fieldWidth:90
        spinner last "End frame" range:[-1000000,1000000,100] type:#integer fieldWidth:90
        dropdownList sampling "Samples per frame" items:#("1","2","4") selection:3 width:310
        label note "Render aspect is preserved. Units become metres / Y up." align:#left
        label note2 "Use the same scene origin as the landscape GLB." align:#left
        button exportButton "Export camera animation…" width:310 height:32
        label result "" width:310 height:44
        on CyrusCameraExporterDialog open do (first.value=animationRange.start.frame;last.value=animationRange.end.frame)
        on choose picked obj do selectedCamera=obj
        on exportButton pressed do (
            try (
                local path=getSaveFileName caption:"Export Cyrus camera animation" types:"Cyrus camera animation (*.json)|*.json|"
                if path!=undefined do (
                    local receipt=CyrusExportCameraAnimation selectedCamera path first.value last.value samplesPerFrame:(sampling.selected as integer)
                    result.text=(receipt[2] as string)+" samples · "+(receipt[3] as string)+" seconds exported."
                )
            ) catch (messageBox (getCurrentException()) title:"Camera export could not complete")
        )
    )
    createDialog CyrusCameraExporterDialog
)
