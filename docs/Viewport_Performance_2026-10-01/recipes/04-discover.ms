(
 local f=createFile (CVDir+"viewport-api-2.txt")
 try(showInterfaces (NitrousGraphicsManager.GetActiveViewportSetting()) to:f)catch(format "%\n" (getCurrentException()) to:f)
 try(apropos "degrad" to:f)catch()
 try(apropos "statistics" to:f)catch()
 close f
)
