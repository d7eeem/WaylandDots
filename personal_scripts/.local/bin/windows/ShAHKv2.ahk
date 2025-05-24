#Requires AutoHotkey v2.0



; Globle HotKeys
#Enter:: run "C:\Users\id7eeem\AppData\Local\Microsoft\WindowsApps\wt.exe"
;#S:: run "C:\Program Files\Everything\Everything.exe"
#w:: run 'firefox'
#+q::DllCall("LockWorkStation")
#+r:: run "explorer"


; Function HotKeys
#q::
{
Title := WinGetTitle("A")
   if (class != "Shell_TrayWnd, WorkerW")
       WinClose("A")
return
}


#m::
{
  MouseGetPos , , &id, &control
  WinGetClass "ahk_id " id
   ; disable for windows taskbar 
    if (class != "Shell_TrayWnd, WorkerW")
        WinMinimize "ahk_id " id
return
}
