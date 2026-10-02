(
 local f=createFile (CVDir+"viewport-api.txt")
 showInterface (NitrousGraphicsManager.GetActiveViewportSetting()) to:f
 apropos "degrad" to:f
 apropos "statistics" to:f
 close f
)
