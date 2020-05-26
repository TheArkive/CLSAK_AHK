; AHK v1
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#INCLUDE %A_ScriptDir%
#INCLUDE TheArkive_CliSAK.ahk
#INCLUDE TheArkive_CliSAK_Example_Messages.ahk
#INCLUDE TheArkive_MsgBox2.ahk
; #INCLUDE TheArkive_Debug.ahk

Global ScriptPID
Process, Exist
ScriptPID := ErrorLevel

Global c, CmdOutputHwnd, CmdPromptHwnd, CmdInputHwnd, CmdOutput, CmdPrompt, CmdInput

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
	
	mb := new msgbox2(Example1msg,"Example #1","maxWidth:500,fontFace:Courier New")
	
	c := new cli("cmd /C dir"), output := c.stdout, c := ""
	AppendText(CmdOutputHwnd,output)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example2() { ; simple example, short delay
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	mb := new msgbox2(Example2msg,"Example #2","maxWidth:500,fontFace:Courier New")
	
	c:= new cli("cmd /C dir C:\Windows\System32"), output := c.stdout, c := ""
	AppendText(CmdOutputHwnd,output)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example3() { ; streaming example
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	mb := new msgbox2(Example3msg,"Example #3","maxWidth:500,fontFace:Courier New")
	
	c := new cli("cmd /C dir C:\windows\System32","mode:so|ID:Console")
}
; ============================================================================
; ============================================================================
; ============================================================================
Example4() { ; batch example, pass multi-line var for batch commands
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	mb := new msgbox2(Example4msg,"Example #4","maxWidth:550,fontFace:Courier New")
	
	; in batch mode, every line must be a command you can run in cmd window
	; you can concatenate commands with "&", "&&", "||"
	; check help for windows batch scripting
	batch := "cmd /Q /K ECHO. & dir C:\Windows\System32`r`n"
		   . "ECHO. & cd..`r`n" ; ECHO. addes a new blank line
		   . "ECHO. & dir`r`n"  ; before executing the command.
		   . "ECHO. & ping 127.0.0.1`r`n"
		   . "ECHO. & echo --== custom commands COMPLETE ==--"
	
	; remove mode "p" below to see the prompt in data
	c := new cli(batch,"mode:bop|ID:Console")
}
; ============================================================================
; ============================================================================
; ============================================================================
Example5() { ; CTRL+C and CTRL+Break examples ; if you need to copy, disable CTRL+C hotkey below
	If (IsObject(c))
		c.close(), c:=""
	GuiControl, , CmdOutput
	
	mb := new msgbox2(Example5msg,"Example #5","maxWidth:800,fontFace:Courier New")
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
	
	mb := new msgbox2(Example6msg,"Example #6","maxWidth:600,fontFace:Courier New")
	
	c := new cli("cmd /C dir poof","mode:x") ; <=== mode "w" implied, no other primary modes.
	
	; you can easily direct stdout / stderr to callback with modes "o" and "e"
	stdOut := "===========================`r`n"
			. "StdOut:`r`n"
			. c.stdout "`r`n"
			. "===========================`r`n"
	stdErr := "===========================`r`n"
			. "StdErr:`r`n"
			. c.stderr "`r`n"
			. "===========================`r`n"
	AppendText(CmdOutputHwnd,stdOut stdErr)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example7() { ; interactive session example
	If (IsObject(c))
		c.close(), c:="" ; delete object and clear previous instance
	GuiControl, , CmdOutput
	
	mb := new msgbox2(Example7msg,"Example #7","maxWidth:600,fontFace:Courier New")
	
	c := new cli("cmd","mode:sipf|ID:Console")
	; Mode "s" for streaming, but no "o" for stdout callback (not needed in this case)
	; Mode "p" prunes the prompt from StdOut.
	; Mode "i" uses callback function to capture prompt and signals "command complete, ready for next command".
	; Mode "f" filters control codes, such as when logged into an SSH server hosted on a linux machine.
}
; ============================================================================
; ============================================================================
; ============================================================================
Example8() { ; mode "m" example
	If (IsObject(c))
		c.close(), c:="" ; close previous instance first.
	
	mb := new msgbox2(Example8msg,"Example #8","maxWidth:700,fontFace:Courier New")
	
	; 1) download wget.exe from https://eternallybored.org/misc/wget/
	; 2) unzip it in the same folder as this script
	; 3) uncomment the 2 lines below, and comment out the other 2 lines
	; ========================================================================================
	; The file downloaded in this example is the Windows Android SDK (the small version).
	; Home Page:   https://developer.android.com/studio/releases/platform-tools
	;
	; In this wget.exe example, you can isolate the animated progress bar and incorporate it as 
	; part of your GUI.  See the GetLastLine() function below which makes it easy to isolate the
	; progress bar.
	; ========================================================================================
	
	; uncomment the next 2 lines
	; cmd := "cmd /C wget https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
	; options := "mode:m(100,3)o|ID:modeM"	; In this particular case, 3 lines work best.
											; With the GetLastLine() funciton, it doesn't really
											; matter how many lines you use, but capturing a
											; smaller console will always perform better.
	
	; ========================================================================================
	; Using 1 row may have unwanted side effects.  The last printed line may overwrite the
	; previous line. If the previous line is longer than the last line, then you may see
	; the remenants of the previous line.
	; ========================================================================================
	; ========================================================================================
	; ========================================================================================
	
	; comment out these 2 lines to use the wget.exe example
	cmd := "dir C:\Windows\System32`r`n"
	options := "mode:m(100,5,/Q /K)op|ID:modeM" ; console size = 100 columns / 5 rows
	
	c := new cli(cmd,options)
}

GetLastLine(sInput="") { ; use this in stdOutCallback()
	sInput := Trim(sInput,OmitChars:=" `r`n"), i := 0
	Loop, Parse, sInput, `r, `n
		i++
	Loop, Parse, sInput, `r, `n
	{
		If (A_Index = i)
			lastLine := A_LoopField
	}
	return lastLine
}
; ============================================================================
; Callback Functions
; ============================================================================
stdOutCallback(data,ID,cliObj) { ; stdout callback function --- default: stdOutCallback()
	If (ID = "Console") {
		AppendText(CmdOutputHwnd,data)
	} Else If (ID = "modeM") {
		lastLine := GetLastLine(data)
		
		; use only one of these, comment out the other...
		; ======================================================
		GuiControl, , %CmdOutputHwnd%, %lastLine%	; use the GetLastLine() function
	}
}

stdErrCallback(data,ID,cliObj) { ; stdErr callback function --- default: stdErrCallback()
	If (ID = "Console") { ; works just like stdout callback
		AppendText(CmdOutputHwnd,msg) ; handle StdErr differently
	}
}

cliPromptCallback(prompt,ID,cliObj) { ; cliPrompt callback function --- default: cliPromptCallback()
	Gui, Cmd:Default ; need to set GUI as default if NOT using control HWND...
	GuiControl, , CmdPrompt, ========> new prompt =======> %prompt% ; set Text control to custom prompt
	
	AppendText(CmdOutputHwnd,cliObj.stdout) ; handle full output of last command as one chunk of data
	cliObj.stdout := "" ; clear stdout since it's already been printed to the GUI window.
						; You don't have to clear cliObj.stdout here, but in this case it makes sense to do so.
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

; ================================================================================
; AppendText(hEdit, ptrText)
; example: AppendText(ctlHwnd, &varText)
; Posted by TheGood:
; https://autohotkey.com/board/topic/52441-append-text-to-an-edit-control/#entry328342
; ================================================================================
AppendText(hEdit, sInput, loc="bottom") {
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
^c::c.ctrlC()
^CtrlBreak::c.CtrlBreak()
^b::c.CtrlBreak()			; in case user doesn't have BREAK key
^x::c.close()				; closes active CLi instance if idle
