; Check if running as administrator (required for games)
if not A_IsAdmin
{
    MsgBox, 4,, This script needs administrator privileges to work with games. Run as administrator?
    IfMsgBox Yes
    {
        Run *RunAs "%A_ScriptFullPath%"
        ExitApp
    }
}

; Add direct click test (F3) - clicks at current mouse position using game methods
F3::
MouseGetPos, mouseX, mouseY
WinGet, SWWindow, ID, A
WinGetPos, winX, winY, , , ahk_id %SWWindow%
relX := mouseX - winX
relY := mouseY - winY

; Try the most aggressive method
BlockInput, On
; Method 1: SendMessage
SendMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %SWWindow%
Sleep, 50
SendMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %SWWindow%
Sleep, 100

; Method 2: ControlClick
ControlClick, x%relX% y%relY%, ahk_id %SWWindow%, , LEFT, 1, NA
BlockInput, Off
return

return