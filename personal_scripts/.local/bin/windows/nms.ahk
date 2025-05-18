#Warn
#NoEnv
#SingleInstance Force
SetBatchLines -1

title := "No Man's Sky"

While(true) {
    if (WinExist(title)) {
        if (!WinActive(title)) {
            Sleep, 50 ;Small delay while tabbing
            PostMessage 0x06, 1, 0, , %title%
        }
    }
    Sleep, 500
}
return



; crafting More
F8::
BreakLoop =  0
Loop,
    {
        if (BreakLoop = 1)
            break
Sleep 1000

Send, {e Down}
Sleep, 850
Send, {e Up}
Sleep, 850
    }

F7::
BreakLoop =  0
Loop,
    {
        if (BreakLoop = 1)
            break
Sleep 1000
Click, down
Sleep, 850
Click, up
    }


F11::
BreakLoop = 1
return