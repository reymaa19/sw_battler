; AutoHotkey Battle Replay Script
; This script continuously searches for an "result" image to perform a sequence of clicks
; Press F9 to start/stop the replay loop
; Press ESC to exit completely

#NoEnv
#SingleInstance Force
#Persistent
#NoTrayIcon

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

; Set most aggressive input modes for games
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
SetBatchLines, -1
SetKeyDelay, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0

; Global variables
global IsReplayActive := false
global IterationCount := 0
global ImagePath:= A_ScriptDir . "\images\result.png"

; Create GUI for status display
Gui, Add, Text, x10 y10 w300 h20 vStatusText, Battle Replay Script Ready
Gui, Add, Text, x10 y35 w300 h20 vIterationText, Iterations: 0
Gui, Add, Text, x10 y60 w300 h20 vInstructionText, F9: Start/Stop | ESC: Exit
Gui, Add, Text, x10 y85 w300 h20 vLastActionText, Last Action: Waiting...
Gui, Show, w320 h120, Battle Replay Status
return

; F9 to toggle replay loop
F9::
if (IsReplayActive) {
    IsReplayActive := false
    SetTimer, ReplayLoop, Off
    GuiControl,, StatusText, Replay Stopped
    GuiControl,, LastActionText, Last Action: Stopped by user
    ToolTip, Replay Stopped
    SetTimer, RemoveToolTip, 1000
} else {
    IsReplayActive := true
    SetTimer, ReplayLoop, 1000 ; Check every 1 second if done
    GuiControl,, StatusText, Replay Active - Searching...
    GuiControl,, LastActionText, Last Action: Started replay loop
    ToolTip, Replay Started - Waiting for completion
    SetTimer, RemoveToolTip, 1000
}
return

; ESC to exit
Esc::
IsReplayActive := false
SetTimer, ReplayLoop, Off
ToolTip, Exiting Battle Replay Script...
SetTimer, RemoveToolTip, 1000
Sleep, 1000
ExitApp

; Main replay loop function
ReplayLoop:
if (!IsReplayActive) {
    return
}

; Search for end result
ImageSearch, FoundX, FoundY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *50 %ImagePath%
if (ErrorLevel = 0) {
    ReplayClicks()
}

return

ReplayClicks() {
    IterationCount++
    GuiControl,, IterationText, Iterations: %IterationCount%

    replayCoords := [{x: 2168, y: 1271}, {x: 1787, y: 1268}, {x: 1280, y: 720}, {x: 1105, y: 836}, {x: 1276, y: 1233}, {x: 2215, y: 1087}]

    for index, coords in replayCoords {
        Sleep, 3000
        UltraBrutalDirectClick(coords.x, coords.y)
    }

    Sleep, 2000
}

; Ultra brutal direct click function - Now uses direct window message clicking
UltraBrutalDirectClick(x, y) {
    ; Don't even try to move the cursor - games can block that
    ; Instead, get the active window and send direct click messages
    WinGet, ActiveWindow, ID, A
    WinGetPos, winX, winY, , , ahk_id %ActiveWindow%
    
    ; Calculate relative coordinates to the window
    relX := x - winX
    relY := y - winY
    
    GuiControl,, LastActionText, Clicking at screen: %x%`, %y% relative: %relX%`, %relY%
    
    ; Send WM_MOUSEMOVE first
    SendMessage, 0x200, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 10
    
    ; Try PostMessage versions (sometimes more effective)
    PostMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 50
    PostMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%

    ;BlockInput, On ; Blocks user input (FROZE WHEN DEBUGGING)
    
    ; Send WM_LBUTTONDOWN (0x201)
    SendMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 100
    
    ; Send WM_LBUTTONUP (0x202) 
    SendMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 500
    
    GuiControl,, LastActionText, Direct click sent to window (multiple methods)
}

; Function to remove tooltip
RemoveToolTip:
ToolTip
SetTimer, RemoveToolTip, Off
return

; GUI close handler
GuiClose:
ExitApp

; Additional hotkeys for testing