; Globle HotKeys
#Enter:: run "C:\Users\id7eeem\AppData\Local\Microsoft\WindowsApps\wt.exe"
;#S:: run "C:\Program Files\Everything\Everything.exe"
#w:: run firefox
#+q::DllCall("LockWorkStation")
#r:: run "explorer.exe"


; Function HotKeys
#q::
WinGetTitle, Title, A
   If class not in Shell_TrayWnd, WorkerW
       WinClose, %Title%
return



#m::
;WinGetTitle, Title, A
;WinMinimize, %Title%
   MouseGetPos, , , id,
   WinGetClass, class, ahk_id %id%

   ; disable for windows taskbar 
   If class not in Shell_TrayWnd, WorkerW
        WinMinimize, ahk_id %id%
return
