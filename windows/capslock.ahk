#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

; A standalone tap shorter than this sends Escape on release.
; Control is pressed immediately, so fast Ctrl combinations have no delay.
TapTimeout := 200
CapsCtrlDown := false
InstallKeybdHook()
InstallMouseHook()
SetCapsLockState "AlwaysOff"
OnExit ReleaseCapsCtrl

*CapsLock::
{
    global CapsCtrlDown
    started := A_TickCount
    CapsCtrlDown := true
    Send "{Blind}{LCtrl downR}"

    ; Waiting in this hotkey also suppresses CapsLock auto-repeat.
    KeyWait "CapsLock"
    tapped := A_PriorKey = "CapsLock" && A_TickCount - started < TapTimeout
    ReleaseCapsCtrl()
    if tapped
        Send "{Blind}{Esc}"
}

; Keep CapsLock's Control held if the physical left Control is released first.
~*LCtrl Up::
{
    if CapsCtrlDown && GetKeyState("CapsLock", "P")
        Send "{Blind}{LCtrl downR}"
}

ReleaseCapsCtrl(*)
{
    global CapsCtrlDown
    if CapsCtrlDown
    {
        CapsCtrlDown := false
        ; Do not release a Control key the user is still physically holding.
        if !GetKeyState("LCtrl", "P")
            Send "{Blind}{LCtrl up}"
    }
}
