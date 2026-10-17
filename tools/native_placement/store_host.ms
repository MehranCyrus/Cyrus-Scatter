-- N02 lifetime/precision boundary tests, not a shipped placement fallback.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-memory0854-nativestore-*/" do throw "Owned N02 host required."
 local io=dotNetClass "System.IO.File",phase=io.ReadAllText(MCPFixtureDir+"native-store-phase.txt")
 global NSBaseline,NSRaw,NSRawRows,NSEdited,NSEditedRows,NSSelected,NSCompact,NSRetained,NSOwner,NSToken,NSBadToken
 local log=createFile (MCPFixtureDir+"native-store-"+phase+".txt")
 fn check yes text log=(format "%: %\n" (if yes then "PASS" else "FAIL") text to:log;flush log;if not yes do throw text)
 fn rejected action=(local failed=false;try(action())catch(failed=true);failed)
 fn sameRows a b=(if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  case phase of (
   "construct": (
    check (cyrusPlacementNativeVersion()==1) "Matched native placement capability" log
    gc light:true;NSBaseline=cyrusPlacementMemoryStats();NSOwner=cyrusPlacementOwner()
    NSRawRows=#(#(matrix3 1,1,9007199254740993L,1,[0.2,0.3,0.5],9223372036854775807L,false,2),#(transMatrix [10,-3,2],2,42L,2,[1,0,0],0L,false,2),#(transMatrix [-7,0,4],1,99L,3,[0,1,0],13L,false,2))
    NSRaw=cyrusPlacementCapture NSOwner 1 2 127 NSRawRows;NSToken=cyrusPlacementToken NSRaw
    check (NSRaw.count==3 and sameRows NSRawRows (cyrusPlacementPage NSRaw NSToken 0 3)) "Every raw field, high 64-bit key, Band and Float32 transform round-trips" log
    local page=cyrusPlacementPage NSRaw NSToken 0 3;page[1][1]=transMatrix [100,200,300]
    check (sameRows NSRawRows (cyrusPlacementPage NSRaw NSToken 0 3)) "Detached page mutation cannot change native placements" log
    NSBadToken=deepCopy NSToken;NSBadToken[1]+=1
    fn wrongToken=(cyrusPlacementPage NSRaw NSBadToken 0 1)
    check (rejected wrongToken) "Foreign owner token rejected" log
    fn tooLarge=(cyrusPlacementPage NSRaw NSToken 0 501)
    check (rejected tooLarge) "Readback bounded at 500" log
    fn negativePage=(cyrusPlacementPage NSRaw NSToken -1 1)
    check (rejected negativePage) "Negative offset rejected" log
    fn wrongKind=(cyrusPlacementPage #() NSToken 0 0)
    check (rejected wrongKind) "Wrong native type rejected" log
    NSSelected=cyrusPlacementSelect NSRaw NSToken #(2,0)
    local selectedToken=cyrusPlacementToken NSSelected
    check (sameRows #(NSRawRows[3],NSRawRows[1]) (cyrusPlacementPage NSSelected selectedToken 0 2)) "Flat selection retains exact key and requested order" log
    fn staleSelection=(cyrusPlacementPage NSSelected NSToken 0 1)
    check (rejected staleSelection) "Base token cannot read a different selection" log
    fn duplicateSelection=(cyrusPlacementSelect NSRaw NSToken #(0,0))
    check (rejected duplicateSelection) "Duplicate native selection rejected" log
    NSCompact=cyrusPlacementCompact NSSelected selectedToken
    check (sameRows #(NSRawRows[3],NSRawRows[1]) (cyrusPlacementPage NSCompact (cyrusPlacementToken NSCompact) 0 2)) "Compaction retains every semantic field" log
    NSEditedRows=deepCopy NSRawRows;NSEditedRows[1][3]="c:9007199254740993";NSEditedRows[2][3]="copy:exact-0001";NSEditedRows[2][7]=true;NSEditedRows[3][3]="c:00001";NSEditedRows[3][7]=true
    NSEdited=cyrusPlacementCapture NSOwner 2 2 127 NSEditedRows
    check (sameRows NSEditedRows (cyrusPlacementPage NSEdited (cyrusPlacementToken NSEdited) 0 3)) "Generated and exact authored text/protection round-trip without guessing" log
    local empty=cyrusPlacementCapture NSOwner 1 0 0 #()
    check (empty.count==0) "Typed empty generation permits no sources" log
    local info=cyrusBrushPlacementInfo NSCompact
    check (info[1]==1 and info[2]==96 and info[6]==2 and info[7]==NSRawRows[1][1].row4) "Brush reads the owning DLL's versioned POD lease without a second store" log
    fn wrongBrush=(cyrusBrushPlacementInfo #())
    check (rejected wrongBrush) "Brush rejects a wrong-kind native handle" log
    NSRetained=deepCopy NSCompact
   )
   "retain": (
    NSRaw=undefined;NSEdited=undefined;NSSelected=undefined;NSCompact=undefined;NSRawRows=undefined;NSEditedRows=undefined
    gc light:true
    check (NSRetained.count==2) "Immutable copy retains native data after other wrappers collect" log
    local rows=cyrusPlacementPage NSRetained (cyrusPlacementToken NSRetained) 0 2
    check (rows[1][3]==99L and rows[2][3]==9007199254740993L) "Native identity survives original wrapper GC" log
    local info=cyrusBrushPlacementInfo NSRetained
    check (info[6]==2 and info[7]==[0,0,0]) "Independent Brush lease remains valid after original wrapper GC" log
    local memory=cyrusPlacementMemoryStats()
    check (memory[1]==192 and memory[6]==NSBaseline[6]+1 and memory[7]==NSBaseline[7]) "Only compact 192-byte generation remains; rejected bases/selections released" log
   )
   "release": (
    NSRetained=undefined;gc light:true
    local memory=cyrusPlacementMemoryStats()
    check (memory[1]==NSBaseline[1] and memory[5]==NSBaseline[5] and memory[6]==NSBaseline[6] and memory[7]==NSBaseline[7]) "Last GC owner releases all native store and selection allocations" log
   )
   default: throw "Unknown N02 phase"
  )
  format "PASS: complete\n" to:log;close log
 )catch(format "FAIL: %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
)
