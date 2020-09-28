; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; #INCLUDE %A_ScriptDir%
#INCLUDE TheArkive_CliSAK.ahk

Global oGui, c:="", CmdOutput, CmdPrompt, CmdInput
Global done := "__Batch Complete__"

CmdGui()

CmdGui() {
	oGui := Gui.New("+Resize","Console")
	oGui.OnEvent("Close","CmdClose")
	oGui.SetFont("s8","Courier New")
	
	oGui.Add("button","","Ex #1").OnEvent("Click","Example1")
	oGui.Add("button","x+0","Ex #2").OnEvent("Click","Example2")
	oGui.Add("button","x+0","Ex #3").OnEvent("Click","Example3")
	oGui.Add("button","x+0","Ex #4").OnEvent("Click","Example4")
	oGui.Add("button","x+0","Ex #5").OnEvent("Click","Example5")
	oGui.Add("button","x+0","Ex #6").OnEvent("Click","Example6")
	oGui.Add("button","x+0","Ex #7").OnEvent("Click","Example7")
	oGui.Add("button","x+0","Ex #8").OnEvent("Click","Example8")
	
	oGui.Add("Button","x+20","Show Window").OnEvent("Click","ShowWindow")
	oGui.Add("Button","x+0","Hide Window").OnEvent("Click","HideWindow")
	
	ctl := oGui.Add("Edit","vCmdOutput xm w800 h400 ReadOnly")
	ctl := oGui.Add("Text","vCmdPrompt w800 y+0","Prompt>")
	ctl := oGui.Add("Edit","vCmdInput w800 y+0 r3")
		
	oGui.Show()
	oGui["CmdInput"].Focus()
}

ShowWindow(oCtl,Info) {
	WinShow "ahk_pid " c.pid
}

HideWindow(oCtl,Info) {
	WinHide "ahk_pid " c.pid
}

CmdSize(o, MinMax, Width, Height) {
	h1 := Height - 10 - 103, w1 := Width - 20
	o["CmdOutput"].Opt("h" h1 " w" w1)
	
	y2 := Height - 75, w2 := Width - 20
	o["CmdPrompt"].Opt("y" y2 " w" w2)
	
	y3 := Height - 55, w3 := Width - 20
	o["CmdInput"].Opt("y" y3 " w" w3)
}

CmdClose(o) {
	If (IsObject(c))
		c.close()
	ExitApp
}
; ============================================================================
; ============================================================================
; ============================================================================
Example1(oCtl,Info) { ; simple example
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	output := CliData("cmd /C dir") ; CliData() easy wrapper, no fuss, no muss
	AppendText(oGui["CmdOutput"].hwnd,output)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example2(oCtl,Info) { ; simple example, short delay
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	output := CliData("cmd /C dir C:\Windows\System32") ; CliData() easy wrapper, no fuss, no muss
	AppendText(oGui["CmdOutput"].hwnd,output)
    MsgBox "There was a delay because there was lots of data, but now it's done."
}
; ============================================================================
; ============================================================================
; ============================================================================
Example3(oCtl,Info) { ; streaming example, with QuitString
	If (IsObject(c))
		c.close(), c := ""
	oGui["CmdOutput"].Value := ""
	
	cmd := "cmd /K dir C:\windows\System32`r`n"
         . "ECHO " done ; "done" is set as global above
    
    ; The "done" var in this case is used as a user-defined "signal".  The "QuitString" will
    ; quit the CLI session automatically when the QuitString is encountered in StdOut.
	c := cli.New(cmd,"mode:so|ID:Console|QuitString:" done)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example4(oCtl,Info) { ; batch example, pass multi-line var for batch commands, and QuitString
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
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
	c := cli.New(batch,"mode:sor|ID:Console|QuitString:" done)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example5(oCtl,Info) { ; CTRL+C and CTRL+Break examples ; if you need to copy, disable CTRL+C hotkey below
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	MsgBox "User CTRL+B for CTRL+Break.  Also press CTRL+C during this batch."
    
	cmd := "cmd /K ping 127.0.0.1 & ping 127.0.0.1" ; mode "o" uses the StdOut callback function
	c := cli.New(cmd,"mode:so|ID:Console")          ; mode "s" is streaming, so constant data collection
}
; ============================================================================
; ============================================================================
; ============================================================================
Example6(oCtl,Info) { ; stderr example
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	c := cli.New("cmd /C dir poof","mode:x") ; <=== mode "w" implied, no other primary modes.
    
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
	AppendText(oGui["CmdOutput"].hwnd,stdOut stdErr)
    
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
Example7(oCtl,Info) {
	If (IsObject(c))
		c.close(), c:="" ; delete object and clear previous instance
	oGui["CmdOutput"].Value := ""
	
	c := cli.New("cmd /K ECHO This is an interactive CLI session. & ECHO. & ECHO Type dir and press ENTER.","mode:sopfr|ID:Console")
    
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
    
    oGui["CmdInput"].Focus()
}
; ============================================================================
; ============================================================================
; ============================================================================
Example8(oCtl,Info) { ; mode "m" example
	If (IsObject(c))
		c.close(), c:="" ; close previous instance first.
	
	; ========================================================================================
    ; Optional wget.exe example:
    ; ========================================================================================
	; 1) download wget.exe from https://eternallybored.org/misc/wget/
	; 2) unzip it in the same folder as this script
	; 3) Comment lines 231-235 below.
    ; 4) Uncomment lines 212+213 or 215+216, and uncomment options at line 217.
	; ========================================================================================
	; The file downloaded in this example is the Windows Android SDK (the small version).
	; Home Page:   https://developer.android.com/studio/releases/platform-tools
	;
	; In this wget.exe example, you can isolate the incrementing percent and incorporate the
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
	options := "mode:m(100,20)orp|ID:modeM|QuitString:" done ; console size = 100 columns / 5 rows
	
	c := cli.New(cmd,options)
}

; ============================================================================
; Callback Functions
; ============================================================================
QuitCallback(quitStr,ID,cliObj) { ; stream until user-defined QuitString is encountered (optional).
    If (ID = "ModeM")
        oGui["CmdOutput"].Value := "Download Complete"
    MsgBox "QuitString encountered:`r`n`t" quitStr "`r`n`r`nWhatever you choose to do in this callback functions will be done."
}

StdOutCallback(data,ID,cliObj) { ; Handle StdOut data as it streams (optional)
	If (ID = "Console")
		AppendText(oGui["CmdOutput"].hwnd,data) ; append data to edit box
	Else If (ID = "modeM") {
        lastLine := cliObj.GetLastLine(data) ; capture last line containing progress bar and percent.
        prompt := cliObj.getPrompt(data)
        a := StrSplit(lastLine,"["), p1 := a[1], a := StrSplit(p1," "), p2 := (a.Length) ? a[a.Length] : ""
        msg := "========================================================`r`n"
             . "This is the captured console grid.`r`n"
             . "========================================================`r`n"
             . data "`r`n`r`n"
             . "========================================================`r`n"
             . "wget.exe example:  (Check Ex #8 comments)`r`n"
             . "========================================================`r`n"
             . "Percent Complete: " p2
        
        oGui["CmdOutput"].Value := msg
    }
}

StdErrCallback(data,ID,cliObj) { ; Handle StdErr data as it streams (optional).
	If (ID = "Console")
		AppendText(oGui["CmdOutput"].hwnd,data)
}

PromptCallback(prompt,ID,cliObj) { ; cliPrompt callback function --- default: cliPromptCallback()
	oGui["CmdPrompt"].Text := "========> new prompt =======> " prompt ; set Text control to custom prompt
}
; ============================================================================
; send command to CLI instance when user presses ENTER
; ============================================================================

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN
WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; wParam = keycode in decimal | 13 = Enter | 32 = space
    CtrlHwnd := "0x" Format("{:x}",hwnd) ; control hwnd formatted to match +HwndVarName
    If (CtrlHwnd = oGui["CmdInput"].hwnd And wParam = 13) ; ENTER in App List Filter
		SetTimer "SendCmd", -10 ; this ensures cmd is sent and control is cleared
}

SendCmd() { ; timer label from WM_KEYDOWN	
	CmdInput := oGui["CmdInput"].Value
	c.write(CmdInput) ; send cmd
	
	oGui["CmdInput"].Value := ""
	oGui["CmdInput"].Focus()
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
AppendText(hEdit, sInput, loc:="bottom") {
    txtLen := SendMessage(0x000E, 0, 0,, "ahk_id " hEdit)		;WM_GETTEXTLENGTH
	If (loc = "bottom")
		SendMessage 0x00B1, txtLen, txtLen,, "ahk_id " hEdit	;EM_SETSEL
	Else If (loc = "top")
		SendMessage 0x00B1, 0, 0,, "ahk_id " hEdit
    SendMessage 0x00C2, False, StrPtr(sInput),, "ahk_id " hEdit		;EM_REPLACESEL
}

; ================================================================================
; hotkeys
; ================================================================================

#HotIf WinActive("ahk_class AutoHotkeyGUI")
^c::c.KeySequence("^c")
^CtrlBreak::c.CtrlBreak()
^b::c.CtrlBreak()			; in case user doesn't have BREAK key
^x::c.close()				; closes active CLi instance if idle
^d::c.KeySequence("^d")
