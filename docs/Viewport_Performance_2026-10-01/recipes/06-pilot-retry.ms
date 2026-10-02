try(fileIn (CVDir+"05-pilot.ms"))catch(CSPWriteText (CVDir+"pilot-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace())))
