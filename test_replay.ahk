; AutoHotkey Battle Replay Script - Equivalent to replay.py
; This script continuously searches for an "add" button image and clicks it
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
global ImagePath := A_ScriptDir . "\images\add.png"

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
    SetTimer, RemoveToolTip, 2000
} else {
    IsReplayActive := true
    SetTimer, ReplayLoop, 5000  ; Check every 5 seconds like Python version
    GuiControl,, StatusText, Replay Active - Searching...
    GuiControl,, LastActionText, Last Action: Started replay loop
    ToolTip, Replay Started - Searching for add button
    SetTimer, RemoveToolTip, 2000
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
if (!IsReplayActive and A_ThisLabel != "F8") {
    return
}

; Check if image file exists
IfNotExist, %ImagePath%
{
    GuiControl,, LastActionText, Last Action: Image file not found!
    ToolTip, Image file not found: %ImagePath%
    SetTimer, RemoveToolTip, 3000
    return
}

; Search for the image with high confidence
ImageSearch, FoundX, FoundY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *50 %ImagePath%

if (ErrorLevel = 0) {
    ; Image found - calculate center coordinates
    ; Note: ImageSearch returns top-left corner, we need to add half the image size
    ; For now, we'll use the found coordinates directly
    CenterX := FoundX
    CenterY := FoundY
    
    ; Increment iteration counter
    IterationCount++
    GuiControl,, IterationText, Iterations: %IterationCount%
    GuiControl,, LastActionText, Last Action: Found button at %CenterX%`, %CenterY%
    
    ; Display found coordinates
    ToolTip, Battle replayed %IterationCount% times. Add button found at: %CenterX%`, %CenterY%
    SetTimer, RemoveToolTip, 3000
    
    ; Move cursor and click using ultra brutal methods
    UltraBrutalDirectClick(CenterX, CenterY)
    
    ; Small delay to ensure cursor is positioned
    Sleep, 100
    
    ; Send F3 key using multiple methods
    UltraBrutalF3()
    
} else {
    GuiControl,, LastActionText, Last Action: Add button not found
    if (A_ThisLabel = "F8") {
        ToolTip, Add button not found on screen
        SetTimer, RemoveToolTip, 3000
    }
}
return

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
    
    ; Method 1: Block input and send direct window messages (most brutal)
    BlockInput, On
    
    ; Send WM_LBUTTONDOWN (0x201)
    SendMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 50
    
    ; Send WM_LBUTTONUP (0x202) 
    SendMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 100
    
    ; Method 2: ControlClick as backup
    ControlClick, x%relX% y%relY%, ahk_id %ActiveWindow%, , LEFT, 1, NA
    
    BlockInput, Off
    
    ; Method 3: Additional window message methods
    ; Send WM_MOUSEMOVE first
    SendMessage, 0x200, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 10
    
    ; Try PostMessage versions (sometimes more effective)
    PostMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %ActiveWindow%
    Sleep, 50
    PostMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
    
    ; Method 4: Multiple rapid attempts
    Loop, 3 {
        SendMessage, 0x201, 0x0001, (relY << 16) | relX, , ahk_id %ActiveWindow%
        Sleep, 20
        SendMessage, 0x202, 0x0000, (relY << 16) | relX, , ahk_id %ActiveWindow%
        Sleep, 30
    }
    
    GuiControl,, LastActionText, Direct click sent to window (multiple methods)
}

; Ultra brutal F3 key press
UltraBrutalF3() {
    ; Method 1: Standard AutoHotkey Send
    Send, {F3}
    Sleep, 50
    
    ; Method 2: SendInput
    Send, {F3}
    Sleep, 50
    
    ; Method 3: Direct keybd_event DLL calls
    VK_F3 := 0x72
    DllCall("keybd_event", "UChar", VK_F3, "UChar", 0, "UInt", 0, "Ptr", 0)  ; Key down
    Sleep, 50
    DllCall("keybd_event", "UChar", VK_F3, "UChar", 0, "UInt", 2, "Ptr", 0)  ; Key up (2 = KEYEVENTF_KEYUP)
    
    ; Method 4: SendMessage to active window
    WinGet, ActiveHwnd, ID, A
    PostMessage, 0x100, %VK_F3%, 0, , ahk_id %ActiveHwnd%  ; WM_KEYDOWN
    Sleep, 50
    PostMessage, 0x101, %VK_F3%, 0, , ahk_id %ActiveHwnd%  ; WM_KEYUP
    
    GuiControl,, LastActionText, F3 key pressed (multiple methods)
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

; F7 - Test direct click at current mouse position
F7::
MouseGetPos, TestX, TestY
ToolTip, Testing ultra brutal direct click at: %TestX%`, %TestY%
SetTimer, RemoveToolTip, 3000
UltraBrutalDirectClick(TestX, TestY)
return

; F6 - Test F3 keypress
F6::
ToolTip, Testing ultra brutal F3 keypress
SetTimer, RemoveToolTip, 2000
UltraBrutalF3()
return

; F5 - Show current status
F5::
if (IsReplayActive) {
    Status := "ACTIVE"
} else {
    Status := "STOPPED"
}
ToolTip, Replay Status: %Status% | Iterations: %IterationCount%
SetTimer, RemoveToolTip, 3000
return