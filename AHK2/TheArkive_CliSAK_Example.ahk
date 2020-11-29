; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.

; #INCLUDE %A_ScriptDir%
#INCLUDE "*i TheArkive_Debug.ahk"
#INCLUDE TheArkive_CliSAK.ahk

Global oGui, c:="", CmdOutput, CmdPrompt, CmdInput, cli_session
Global done := "__Batch Complete__"

CmdGui()

CmdGui() {
	oGui := Gui.New("+Resize","Console")
	oGui.OnEvent("Close","CmdClose")
    oGui.OnEvent("Size","CmdSize")
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
    oGui.Add("Button","x+0","Copy Selection").OnEvent("Click","copy")
	
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

copy(oCtl,info) {
    A_Clipboard := EditGetSelectedText(oGui["CmdOutput"].hwnd)
    Msgbox "Selected text copied."
}

CmdSize(o, MinMax, Width, Height) {
	h1 := Height - 10 - 103, w1 := Width - 20
	o["CmdOutput"].Move(,,w1,h1)
	
	y2 := Height - 75, w2 := Width - 20
	o["CmdPrompt"].Move(,y2,w2)
	
	y3 := Height - 55, w3 := Width - 20
	o["CmdInput"].Move(,y3,w3)
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
	
	output := CliData("dir") ; CliData() easy wrapper, no fuss, no muss
	AppendText(oGui["CmdOutput"].hwnd,output)
}
; ============================================================================
; ============================================================================
; ============================================================================
Example2(oCtl,Info) { ; simple example, short delay
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	output := CliData("dir " Chr(34) A_WinDir "\System32" Chr(34))
	AppendText(oGui["CmdOutput"].hwnd,output)
    MsgBox "There was a delay because there was lots of data, but now it's done."
}
; ============================================================================
; ============================================================================
; ============================================================================
Example3(oCtl,Info) { ; streaming example
	If (IsObject(c))
		c.close(), c := ""
	oGui["CmdOutput"].Value := ""
	
    cmd := "ECHO This is a simple interactive prompt. & "
         . "ECHO. & ECHO The current directory is visible below. & "
         . "ECHO. & ECHO This output box is cleared in preparation for the output of each command. & "
         . "ECHO. & ECHO This is useful for running a batch of commands to collect output in a single session, instead of creating and destroying the CLI session for every command. & "
         . "ECHO. & ECHO If you don't need to track errors in realtime, it is even more efficient to run a single batch file and collect output that way."
    
	c := cli.New(cmd,"ID:Console_Simple") ; Only using PromptCallback()
}
; ============================================================================
; ============================================================================
; ============================================================================
Example4(oCtl,Info) { ; batch example, pass multi-line var for batch commands, and QuitString
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	batch := "ECHO. & dir " Chr(34) A_WinDir "\System32" Chr(34) "`r`n" ; multi-line commands
		   . "ECHO. & ping 127.0.0.1`r`n"
		   . "ECHO. & ECHO This is an interactive prompt using full streaming, instead of just waiting for the prompt. & "
           . "ECHO. & ECHO "
	
	; Mode "r" removes prompt and command from data, so only output is visible.
	c := cli.New(batch,"mode:r|ID:Console_Streaming") ; Only using StdOutCallback()
}
; ============================================================================
; ============================================================================
; ============================================================================
Example5(oCtl,Info) { ; CTRL+C and CTRL+Break examples ; if you need to copy, disable CTRL+C (^c) hotkey below
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	MsgBox "Use CTRL+B for CTRL+Break and CTRL+C during this batch to interrupt the running commands.`r`n`r`n"
         . "CTRL+Break and CTRL+C will do different things depending on each command."
    
	cmd := "ping 127.0.0.1 & ping 127.0.0.1`r`n"
         . "ECHO. & The session is still active."
	c := cli.New(cmd,"ID:Console_Streaming") ; Only using StdOutCallback()
}
; ============================================================================
; ============================================================================
; ============================================================================
Example6(oCtl,Info) { ; stderr example
	If (IsObject(c))
		c.close(), c:=""
	oGui["CmdOutput"].Value := ""
	
	c := cli.New("dir poof","mode:xr|ID:error",,"/Q /K") ; blank param is "cmd" by default
    
	; Mode "x" separates StdErr from StdOut.
    ; Mode "r" removes prompt and command from output.
    
    ; It is best to check .stderr in the PromptCallback() function.  PromptCallback() fires after each
    ; command completes, so it is easy to check errors in conjunction with the output of each command.
}
; ============================================================================
; ============================================================================
; ============================================================================
Example7(oCtl,Info) {
	If (IsObject(c))
		c.close(), c:="" ; delete object and clear previous instance
	oGui["CmdOutput"].Value := "This is an interactive console.`r`n`r`n"
	
    c := cli.New("","mode:rx|ID:PowerShell","powershell")
    
	; Mode "r" removes the prompt from StdOut.
	; Mode "f" filters control codes, such as when logged into an SSH server hosted on a linux machine.
    ;          Use mode "f" with plink (from the pUTTY suite) in this example.
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
	
    If !FileExist("wget.exe") {
        Msgbox "This example requires wget.  Please see the comments in example 8."
        return
    }
    
	; ========================================================================================
    ; wget.exe example:
    ; ========================================================================================
	; 1) download wget.exe from https://eternallybored.org/misc/wget/
	; 2) unzip it in the same folder as this script
	; ========================================================================================
	; The file downloaded in this example is the Windows Android SDK (the medium version).
	; Home Page:   https://developer.android.com/studio/releases/platform-tools
	;
	; In this wget.exe example, you can isolate the incrementing percent and incorporate the
    ; text animation as part of your GUI.
    ;
    ; You will want to use the StdOutCallback() function to capture the animation in realtime,
    ; and then you will want to use the PromptCallback() function to detect when the operation
    ; is complete.
	; ========================================================================================
	
    cmd := "wget https://dl.google.com/android/repository/commandlinetools-win-6609375_latest.zip" ; big version
	; cmd := "wget https://dl.google.com/android/repository/platform-tools-latest-windows.zip" ; small version
    
	; ========================================================================================
	; Using 1 row may have unwanted side effects.  The last printed line may overwrite the
	; previous line. If the previous line is longer than the last line, then you may see
	; the remenants of the previous line.
	; ========================================================================================
	
	c := cli.New(cmd,"mode:m(150,10)r|ID:mode_M|showWindow:1") ; console size = 150 columns / 10 rows
}

; ============================================================================
; Callback Functions
; ============================================================================
QuitCallback(quitStr,ID,cliObj) { ; stream until user-defined QuitString is encountered (optional).
    If (ID = "ModeM")
        oGui["CmdOutput"].Value := "Download Complete"
    
    MsgBox "QuitString encountered:`r`n`t" quitStr "`r`n`r`nWhatever you choose to do in this callback functions will be done.`r`n`r`n"
         . "This could be used to terminate a batch before completion if desired."
}

StdOutCallback(data,ID,cliObj) { ; Handle StdOut data as it streams (optional)
	If (ID = "Console_Streaming") {
        If (oGui["CmdOutput"].Value = "")
            AppendText(oGui["CmdOutput"].hwnd,data) ; append data to edit box
        Else AppendText(oGui["CmdOutput"].hwnd,"`r`n" data)
    } Else If (ID = "mode_M") {                                 ; >>> mode "m" example capturing incrementing percent
        lastLine := cliObj.GetLastLine(data)
        b1 := InStr(lastLine,"["), b2 := InStr(lastLine,"]") ; brackets surrounding the progress bar
        
        lastLine_ := RegExReplace(Trim(lastLine),"[ ]{2,}"," ")
        a := StrSplit(lastLine_," ")
        
        file_disp := "", percent := "", prog_bar := "", rate := "", eta := "", trans := ""
        
        If (b1 and b2 and a.Length) { ; extracting elements of last line
            file_disp := a[1]
            percent := SubStr(lastLine,b1-4,4)
            prog_bar := SubStr(lastLine,b1+1,b2-b1-1)
            trans := (a[a.Length-1] = "eta") ? a[a.Length-3] : a[a.Length-1]
            rate := (a[a.Length-1] = "eta") ? a[a.Length-2] : a[a.Length]
            eta := (a[a.Length-1] = "eta") ? "eta " a[a.Length] : ""
        }
        
        oGui["CmdOutput"].Value := "File: " file_disp "`r`n`r`n"
                                 . "Percent Complete: " percent "`r`n`r`n"
                                 . "Progress Bar: [" prog_bar "]`r`n`r`n"
                                 . "Transfered: " trans "`r`n`r`n"
                                 . "Bandwidth: " rate "`r`n`r`n"
                                 . "ETA: " eta
    }
}

PromptCallback(prompt,ID,cliObj) { ; cliPrompt callback function --- default: PromptCallback()
	oGui["CmdPrompt"].Text := prompt ; echo prompt to text control in GUI
    
    If (ID = "Console_Simple") {                                ; >>> simple console example
        oGui["CmdOutput"].Value := cliObj.stdout
        cliObj.stdout := "" ; clear StdOut/StdErr for a proper interactive console.
    } Else If (ID = "error" And cliObj.Ready) {
        stdOut := ">>> StdOut:`r`n" RTrim(cliObj.stdout,"`r`n`t") "`r`n`r`n"
        stdErr := ">>> StdErr:`r`n" RTrim(cliObj.stderr,"`r`n`t") "`r`n`r`n"
        oGui["CmdOutput"].Value := stdOut stdErr
        cliobj.stdOut := "", cliobj.stdErr := ""
    } Else If (ID = "PowerShell") {                             ; >>> more complex interactive console example
        txt := ((cliobj.lastCmd) ? " " cliobj.lastCmd "`r`n`r`n" : "") ; reconstruct output similar to normal console
             . ((cliobj.stdout) ? cliobj.stdout "`r`n`r`n" : "")
             . ((cliobj.stderr) ? cliobj.stderr "`r`n`r`n" : "")
             . prompt
        AppendText(oGui["CmdOutput"].hwnd,txt)
        cliObj.stdout := "", cliObj.stderr := "" ; clear StdOut/StdErr for a proper interactive console.
    } Else If (ID = "mode_M")                                   ; >>> mode "m" example capturing incrementing percent
        oGui["CmdOutput"].Value := "Download complete."
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

#HotIf WinActive("ahk_id " oGui.hwnd)
^c::c.KeySequence("^c")
^CtrlBreak::c.KeySequence("^{CtrlBreak}")
^b::c.KeySequence("^{CtrlBreak}")   ; in case user doesn't have BREAK key
^x::c.close()				        ; closes active CLi instance if idle
^d::c.KeySequence("^d")
