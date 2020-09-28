; AHK v1 
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#INCLUDE %A_ScriptDir%
#INCLUDE TheArkive_CliSAK.ahk

Global c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput
Global done := "__Batch Complete__"

CmdGui()

CmdGui() {
	Gui, Cmd:New, +LabelCmd +HwndCmdHwnd +Resize, Console
	Gui, Font, s8, Courier New
	Gui, Add, Button, gExample1, Ex #1
	Gui, Add, Button, gExample2 x+0, Ex #2
	Gui, Add, Button, gExample3 x+0, Ex #3
	Gui, Add, Button, gExample4 x+0, Ex #4
	Gui, Add, Button, gExample5 x+0, Ex #5
	Gui, Add, Button, gExample6 x+0, Ex #6
	Gui, Add, Button, gExample7 x+0, Ex #7
	Gui, Add, Button, gExample8 x+0, Ex #8
	
	Gui, Add, Button, gShowWindow x+20, Show Window
	Gui, Add, Button, gHideWindow x+0, Hide Window
	
	Gui, Add, Edit, vCmdOutput +HwndCmdOutputHwnd xm w800 h400 ReadOnly
	Gui, Add, Text, vCmdPrompt +HwndCmdPromptHwnd w800 y+0, Prompt>
	Gui, Add, Edit, vCmdInput +HwndCmdInputHwnd w800 y+0 r3
	Gui, Show
	
	GuiControl, Focus, CmdInput
}

ShowWindow() {
	WinShow, % "ahk_pid " c.pid
}

HideWindow() {
	WinHide, % "ahk_pid " c.pid
}

CmdSize(GuiHwnd, EventInfo, Width, Height) {
	h1 := Height - 10 - 103, w1 := Width - 20
	GuiControl, Move, CmdOutput, h%h1% w%w1%
	y2 := Height - 75, w2 := Width - 20
	GuiControl, Move, CmdPrompt, y%y2% w%w2%
	y3 := Height - 55, w3 := Width - 20
	GuiControl, Move, CmdInput, y%y3% w%w3%
}

CmdClose() {
    c.CtrlBreak()
	c.close()
	ExitApp
}
; ============================================================================
; ============================================================================
; ============================================================================
Example1() { ; simple example
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
    
    output := CliData("cmd /C dir") ; CliData() easy wrapper, no fuss, no muss
	AppendText(CmdOutputHwnd,output)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example2() { ; simple example, short delay
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
    output := CliData("cmd /C dir C:\Windows\System32") ; CliData() easy wrapper, no fuss, no muss
	AppendText(CmdOutputHwnd,output)
    MsgBox % "There was a delay because there was lots of data, but now it's done."
}
; ============================================================================
; ============================================================================
; ============================================================================
Example3() { ; streaming example, with QuitString
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
    cmd := "cmd /K dir C:\windows\System32`r`n"
         . "ECHO " done ; "done" is set as global above
    
    ; The "done" var in this case is used as a user-defined "signal".  The "QuitString" will
    ; quit the CLI session automatically when the QuitString is encountered in StdOut.
	c := new cli(cmd,"mode:so|ID:Console|QuitString:" done)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example4() { ; batch example, pass multi-line var for batch commands, and QuitString
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	; In batch mode, every line must be a command you can run in cmd window.
	; You can concatenate commands on a single line with "&", "&&", "||",
    ; depending on what shell you are using.
	; Check the help docs for the shell you are using.
	batch := "cmd /Q /K ECHO. & dir C:\Windows\System32`r`n"
		   . "ECHO. & cd..`r`n" ; ECHO. addes a new blank line before executing the command.
		   . "ECHO. & dir`r`n"
		   . "ECHO. & ping 127.0.0.1`r`n"
		   . "ECHO. & echo " done ; "done" is set as global above
	
	; remove mode "r" below to see the prompt in data
	c := new cli(batch,"mode:sor|ID:Console|QuitString:" done)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example5() { ; CTRL+C and CTRL+Break examples ; if you need to copy, disable CTRL+C hotkey below
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
    MsgBox % "User CTRL+B for CTRL+Break.  Also press CTRL+C during this batch."
    
	cmd := "cmd /K ping 127.0.0.1 & ping 127.0.0.1" ; mode "o" uses the StdOut callback function
	c := new cli(cmd,"mode:so|ID:Console")          ; mode "s" is streaming, so constant data collection
}
; ============================================================================
; ============================================================================
; ============================================================================
Example6() { ; stderr example
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	c := new cli("cmd /C dir poof","mode:x") ; <=== mode "w" implied, no other primary modes.
    
	; You can easily direct stdout / stderr to callback with modes "o" and "e".
    ; Separating StdErr with a single command is manageable.
	stdOut := "===========================`r`n"
			. "StdOut:`r`n"
			. c.stdout "`r`n"
			. "===========================`r`n"
	stdErr := "===========================`r`n"
			. "StdErr:`r`n"
			. c.stderr "`r`n"
			. "===========================`r`n"
	AppendText(CmdOutputHwnd,stdOut stdErr)
    
    ; NOTE:  If you try to separate StdErr while streaming output, be careful.
    ; The error messages won't be inline with the rest of the data, and it can
    ; be difficult to know which errors pertain to parts of your command batch.
    ; You will need to keep track of which command was last run and organize
    ; the error messages yourself.  Use .lastCmd and .cmdHistory properties
    ; in the callback functions to know which command was run that generated
    ; the errors.
}
; ============================================================================
; ============================================================================
; ============================================================================
Example7() { ; interactive session example
	If (IsObject(c))
		c.close(), c:="" ; delete object and clear previous instance
	GuiControl, , CmdOutput
	
	c := new cli("cmd /K ECHO This is an interactive CLI session. & ECHO. & ECHO Type dir and press ENTER.","mode:sopfr|ID:Console")
    
	; Mode "s" for streaming.
    ; MOde "o" to use StdOutCallback function.
	; Mode "r" removes the prompt from StdOut.
	; Mode "p" uses callback function to capture prompt and signals "command complete, executing next command".
	; Mode "f" filters control codes, such as when logged into an SSH server hosted on a linux machine.
    ;          Use mode "f" with plink (from the pUTTY suite) in this example if you can.
    ;              Putty: https://putty.org/
    ;          This example also works well with Android Debug Bridge (ADB - for android phones).
    ;              ADB SDK: https://developer.android.com/studio/#command-tools
    ;              Platform-Tools only (extra small): https://developer.android.com/studio/releases/platform-tools
    
    Gui, Cmd:default
    GuiControl, Focus, CmdInput
}
; ============================================================================
; ============================================================================
; ============================================================================
Example8() { ; mode "m" example
	If (IsObject(c))
		c.close(), c:="" ; close previous instance first.
	
    ; ========================================================================================
    ; Optional wget.exe example:
    ; ========================================================================================
	; 1) download wget.exe from https://eternallybored.org/misc/wget/
	; 2) unzip it in the same folder as this script
	; 3) Comment lines 229-233 below.
    ; 4) Uncomment lines 210+211 or 213+214, and uncomment options at line 215.
	; ========================================================================================
	; The file downloaded in this example is the Windows Android SDK (the small version).
	; Home Page:   https://developer.android.com/studio/releases/platform-tools
	;
	; In this wget.exe example, you can isolate the animated progress bar and incorporate the
    ; text animation as part of your GUI.  See the obj.GetLastLine() method which makes it easy
    ; to isolate the progress bar.  Use the StdOut callback function to put the progress bar
    ; or incrementing percent in a text box, status bar, title bar, etc.
	; ========================================================================================
	
	; Uncomment one of the cmd vars below (don't forget the 2nd line).  And uncomment options line 215.
    ; cmd := "cmd /K wget https://dl.google.com/android/repository/commandlinetools-win-6609375_latest.zip`r`n" ; big version
         ; . "ECHO " done
    
	; cmd := "cmd /K wget https://dl.google.com/android/repository/platform-tools-latest-windows.zip`r`n" ; small version
         ; . "ECHO " done
	; options := "mode:m(100,10)o|ID:modeM|QuitString:" done ; In this case, 10 or less lines work best.
											; With the obj.GetLastLine() funciton, it doesn't really
											; matter how many lines you use, but capturing a
											; smaller console will always perform better.
	
	; ========================================================================================
	; Using 1 row may have unwanted side effects.  The last printed line may overwrite the
	; previous line. If the previous line is longer than the last line, then you may see
	; the remenants of the previous line.
	; ========================================================================================
	; ========================================================================================
	; ========================================================================================
	
	; comment out the below "cmd" and "options" vars to use the wget.exe example.
	cmd := "cmd /K dir C:\Windows\System32`r`n"
         . "ping 127.0.0.1`r`n"
         . "ping 127.0.0.1`r`n"
         . "echo " done ; "done" is set as global above
	options := "mode:m(100,20)orp|ID:modeM|showWindow:1|QuitString:" done ; console size = 100 columns / 5 rows
	
	c := new cli(cmd,options)
}

; ============================================================================
; Callback Functions
; ============================================================================
QuitCallback(quitStr,ID,cliObj) { ; stream until user-defined QuitString is encountered (optional).
    If (ID = "ModeM")
        GuiControl, , %CmdOutputHwnd%, Download Complete.
    MsgBox % "QuitString encountered:`r`n`t" quitStr "`r`n`r`nWhatever you choose to do in this callback functions will be done."
}

StdOutCallback(data,ID,cliObj) { ; Handle StdOut data as it streams (optional)
	If (ID = "Console")
		AppendText(CmdOutputHwnd,data) ; append data to edit box
	Else If (ID = "modeM") {
        lastLine := cliObj.GetLastLine(data) ; capture last line containing progress bar and percent.
        prompt := cliObj.getPrompt(data)
        a := StrSplit(lastLine,"["), p1 := a[1], a := StrSplit(p1," "), p2 := a[a.Length()]
        msg := "========================================================`r`n"
             . "This is the captured console grid.`r`n"
             . "========================================================`r`n"
             . data "`r`n`r`n"
             . "========================================================`r`n"
             . "wget.exe example:  (Check Ex #7 comments)`r`n"
             . "========================================================`r`n"
             . "Percent Complete: " p2
        
		GuiControl, , %CmdOutputHwnd%, %msg% ; write / overwrite data to edit box
    }
}

StdErrCallback(data,ID,cliObj) { ; Handle StdErr data as it streams (optional).
	If (ID = "Console")
		AppendText(CmdOutputHwnd,data)
}

PromptCallback(prompt,ID,cliObj) { ; cliPrompt callback function --- default: cliPromptCallback()
	Gui, Cmd:Default ; need to set GUI as default if NOT using control HWND...
	GuiControl, , CmdPrompt, ========> new prompt =======> %prompt% ; set Text control to custom prompt
}
; ============================================================================
; send command to CLI instance when user presses ENTER
; ============================================================================

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN
WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; wParam = keycode in decimal | 13 = Enter | 32 = space
    CtrlHwnd := "0x" Format("{:x}",hwnd) ; control hwnd formatted to match +HwndVarName
    If (CtrlHwnd = CmdInputHwnd And wParam = 13) ; ENTER in App List Filter
		SetTimer, SendCmd, -10 ; this ensures cmd is sent and control is cleared
}

SendCmd() { ; timer label from WM_KEYDOWN
	Gui, Cmd:Default ; give GUI the focus / required by timer(s) unless using hwnd in GuiControlGet / GuiControl commands
	GuiControlGet, CmdInput ; get cmd
	c.write(CmdInput) ; send cmd
	Gui, Cmd:Default
	GuiControl, , CmdInput ; clear control
	GuiControl, Focus, CmdInput ; put focus on control again
}

; ================================================================================
; ================================================================================
; support functions
; ================================================================================
; ================================================================================

AppendText(hEdit, sInput, loc="bottom") {
    ; ================================================================================
    ; AppendText(hEdit, ptrText)
    ; example: AppendText(ctlHwnd, &varText)
    ; Posted by TheGood:
    ; https://autohotkey.com/board/topic/52441-append-text-to-an-edit-control/#entry328342
    ; ================================================================================
    SendMessage, 0x000E, 0, 0,, ahk_id %hEdit%						;WM_GETTEXTLENGTH
	If (loc = "bottom")
		SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit%	;EM_SETSEL
	Else If (loc = "top")
		SendMessage, 0x00B1, 0, 0,, ahk_id %hEdit%
    SendMessage, 0x00C2, False, &sInput,, ahk_id %hEdit%			;EM_REPLACESEL
}

; ================================================================================
; hotkeys
; ================================================================================

#IfWinActive, ahk_class AutoHotkeyGUI
^c::c.KeySequence("^c")
^CtrlBreak::c.CtrlBreak()
^b::c.CtrlBreak()			; in case user doesn't have BREAK key
^x::c.close()				; closes active CLi instance if idle
^d::c.KeySequence("^d")
