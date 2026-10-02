try(fileIn (CVDir+"05-pilot.ms"))catch(CSPWriteText (CVDir+"pilot-error-2.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace())))
