::set idle delay to 15 min
SET IDLE_MIN=15
::convert idle delay to seconds
SET /A IDLE_SEC=%IDLE_MIN%*60
::set idle delay while on battery
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK %IDLE_SEC%
::set idle delay while on power
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK %IDLE_SEC%
eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Console lock delay timeout set to %IDLE_MIN% minutes" > nul