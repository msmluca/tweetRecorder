require(jsonlite)
require(ini)

Parse.INI <- function(INI.filename) 
{ 
  INI.list = read.ini(INI.filename)

  return(INI.list) 
} 

Save.INI <- function(configuration, INI.filename) 
{ 
  file.rename(INI.filename, paste0(INI.filename,".bkp"))
  write.ini(x = configuration, filepath = INI.filename)
} 
