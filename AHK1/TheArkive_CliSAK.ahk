; ================================================================
; === cli class, easy one-time and streaming output that collects stdOut and stdErr, and allows writing to stdIn.
; === huge thanks to:
; ===	user: segalion ; https://autohotkey.com/board/topic/82732-class-command-line-interface/#entry526882
; === ... who posted his version of this on 20 July 2012 - 08:43 AM.
; === his code was so clean even I could understand it, and I'm new to classes!
; === another huge thanks to:
; ===	user(s): Sweeet, sean, and maraksan_user ; https://autohotkey.com/board/topic/15455-stdouttovar/page-7#entry486617
; === ... for thier work with StdoutToVar() which inspired me, and thanks to SKAN, HotKeyIt, Sean, maz_1 for
; === StdOutStream() ; https://autohotkey.com/board/topic/96903-simplified-versions-of-seans-stdouttovar/page-2
; === ... which was another very important part of the road map to making this function work.
; === And thanks go "just me" who taught me how to understand structures, pointers, and alignment
; === of elements in a structure on a level where I can finally do this kind of code.
; === Finally, thanks to Lexikos for all the advice he gave to the above users that allowed the creation of these
; === amazing milestones.
; ===
; === Also, thanks to TheGood for coming up with a super easy and elegant way of appending large amounts of text in an
; === edit control, which pertains directly to how some code like this would be used with a GUI.
; ===
; === Thanks to @joedf for LibCon.  That library helped me understand how to read console output and was integral
; === to me being able to create mode "m" to capture console animations.
; ===
; === This class basically combines StdoutToVar() and StdOutStream() into one package, and has the added benefit of not 
; === hanging up the script/GUI as much.  I am NOT throwing shade at StdoutToVar(), StdOutStream(), or the people who created
; === them.  Those functions were amazing milestones.  Without those functions, this version, and other implementations like
; === LibCon would likely not have been possible.
; ========================================================================================================
;	new cli(sCmd, options="")
; ========================================================================================================
;	Parameters:
;		sCmd		(required)
;			Single-line command or multi-line batch command, depending on mode: specified in options.
;
;		options		(optional)
;			Zero or more of the following strings, pipe (|) delimited:
; ========================================================================================================
; Options
; ========================================================================================================
;
;	ID:MyID
;		User defined string to identify CLI sessions.  This is used to identify a CLI instance in
;		callback functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;	mode:[modes]  -  Primary Modes
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;		Modes define how the CLI instance is launched and handled.
;
;		*** Specify ONLY ONE of the following primary modes ***
;		*** If you specify more than one of these primary modes you will get an error ***
;
;		mode "w" = Wait mode, run command, collect data, and exit (default mode).
;			If "s", "b" or "w" are not specified then "w" is assumed.  Note that myObj.ctrlC() and
;			myObj.ctrlBreak() will NOT function in this mode!  If a cmd/process appears to hang, usually
;			the user will have to forcefully terminate the process manually.  The function that runs this
;			mode will also hang if the process hangs.
;
;			Furthermore, if the process/script hangs, you may want to consider using "s", "b", or "m".
;
;		mode "s" = Streaming mode, continual collection until exit.  If you want an interactive background
;			CLI session, use mode "s".
;
;			*** NOTE: Modes "b" and "m" are NOT interactive.  They process the batch and exit.
;
;		mode "b" = Batch mode, run multi-line command lists and capture CLI prompt in a callback function.
;			Default callback: cliPromptCallback()
;
;		mode "m" = Monitoring mode, this launches a hidden CLI window and records text as you would 
;			actually see it.  Usually used with a callback function.  Useful for capturing animations like
;			incrementing percent, or a progress bar... ie.  [======>       ]
;
;			These kinds of animations are not sent to STDOUT, only to the console, hence mode "m".
;
;				Usage: m(width,height[,modes])
;				- width : number of columns
;				- height: number of rows
;				- modes : modes for cmd.exe
;					
;					Ex : /Q /K, etc.
;					Use any valid combo of modes.  Default mode is "/C".
;					* type "cmd /?" to see a list of valid modes
;
;					A smaller area captured performs better than capturing a larger area.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;	mode:[modes]  -  Secondary Modes
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;		*** apped these modes as needed to further modify/refine CLI behavior ***
;
;		mode "c" = Delay sCmd execution.  Execute with obj.RunCmd()  Optionally set more options by
;			specifying [obj.option := value]
;
;		mode "x" = Extract StdErr in a separate pipe.  Stored in myObj.error by default.
;
;		mode "e" = Use a callback function for StdErr.  If the function does not exist, then StdErr is
;			stored in myObj.error ... note that mode "e" implies mode "x".
;
;		   ** Default: stdErrCallback(data,ID)
;
;		mode "o" = Use StdOut callback function.  By default when no callback, myObj.output contains
;			StdOut data.
;
;			Default callback: stdOutCallback(data,ID)
;
;		mode "i" = Uses a callback function to capture the prompt from StdOut.
;
;			Default callback: CliPromptCallback(prompt,ID)
;
;		mode "p" = Prune mode, remove prompt from StdOut data.  Mostly used with mode "i" / mode "b".
;
;	workingDir:c:\myDir
;		Set working directory.  Defaults to %A_ScriptDir%.  Commands that generate files will put those
;		files here, unless otherwise specified in the command parameters.
;
;	codepage:CP###
;		Codepage (UTF-8 = CP65001 / Windows Console = CP437 / etc...)
;
;	stdOutCallback:myFunc
;		Defines the stdOutCallback function name.
;		> Default callback: stdOutCallback(data,ID)
;
;	stdErrCallback:myFunc
;		Defines the stdErrCallback function.
;		> Default callback: stdErrCallback(data,ID)
;
;	cliPromptCallback:MyFunc
;		Defines the cliPromptCallback function.
;		> Default callback: cliPromptCallback(prompt,ID) ... only with mode "b".
;
;	showWindow:#
;		Specify 0 or 1.  Default = 0 to hide.  1 will show.
;		This is really only useful in mode "m".  Although a callback function will give you much more
;		fleibility.  In any other mode the CLI window will remain blank.  This is because StdOut is
;		being redirected so it can be captured.  The window exists so that obj.CtrlBreak() and
;		obj.CtrlC() can function as expected to terminate a console command on demand.
;
;	waitTimeout:###   (ms)
;		The waitTimeout is an internal correction.  There is a slight pause after sCmd execution before
;		the buffer is filled with data.  This class will check the buffer every 10 ms (up to a max
;		specified by waitTimeout, default: 300 ms).  Usually, it doesn't take that long for the buffer to
;		have data after executing a command.  If your command takes longer than 300ms to return data, then
;		you may need to increase this value for proper functionality.
;
;	cmdTimeout:0   (ms)
;		By default, cmtTimeout is set to 0, to wait for the command to complete indefinitely.  This mostly
;		only applies to mode "w".  If you use this class under normal circumstances, you shouldn't need to
;		use this value.
;
;		This class has separate modes so that you can handle single short commands, extended streaming
;		logs, and even interactive CLI sessions.
;
;		But if you find commands just aren't exiting properly, you can try using this value to force a 
;		timeout, but this is not recommended, as you will likely lose data that is meant to be captured.
;		First try other CLI options for the command you are running, or try other options with "cmd" as
;		part of the executed command.  Lastly double-check the command you are trying to run for other
;		options that may effect how you use this class.
; ========================================================================================================
; CLI class Methods and properties
; ========================================================================================================
; If you want more fine-tuned control over the CLI class, you can use these methods:
;
;	myObj.runCmd()
;		Runs the command specified in sCmd parameter.  This is meant to be used with mode "c" when
;		delayed execution is desired.
;
;	myObj.close()
;		Closes all open handles and tries to end the session.  Ending sessions like this usually only
;		succeeds when the CLI prompt is idle.  If you need to force termination then send a CTRL+C or
;		CTRL+Break signal.  Read more below.
;
;	myObj.CtrlC()
;		Sends a CTRL+C signal to the console.  Usually this cancels whatever command is running, but it
;		depends on the command.  Launch this with a button, hotkey, timer, or other event.
;
;	myObj.CtrlBreak()
;		Sends a CTRL+Break signal to the console.  Usually this will cancel whatever command is running,
;		but it depends on the command.  Launch this with a button, hotkey, timer, or other event.
;
;	myObj.kill()
;		Attempts to run TASKKILL on the process launched by sCmd.  This is only provided as a convenience.
;		Don't use this if you can avoid it.  If this CLI class is properly used, and if your CLI
;		application is designed according to normal specifications, then it is easy to terminate a process
;		by using myObj.CtrlC() or myObj.CtrlBreak(), and then if necessary finish up with myObj.close()
;
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; The following options are included as a convenience for power users.  Use with caution.
; Most CLI functionality can be handled without using the below methods / properties directly.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;
;	myObj.write(sInput)
;		Write to StdIn and send commands.  CRLF is appended automatically.
;
;	myObj.read(n=0)
;		Read N bytes from the buffer.
;
;	myObj.AtEOF()   (EOF = end of file)
;		Returns 0 if there is data waiting to be read, otherwise 1 if empty.
;
;	myObj.Length()
;		Returns the amount of data waiting to be read in bytes.
;
;	NOTE: Whatever values you get when using myObj.AtEOF() and myObj.Length() are only true for the exact
;	instant you happen to check them.  Once you read the buffer these values will change.  Furthermore,
;	just because you read the buffer, doesn't mean you are done reading it.  You can only read the buffer
;	approximately 4,096 bytes at a time.  Also, just because there doesn't happen to be data in the buffer
;	now doesn't mean there won't be 10ms later.
;			
; ========================================================================================================
; I know this class is a bit of a monster.  Please check the example script for practical appliations.
; ========================================================================================================

class cli {
    __New(sCmd, options="") {
		this.StdOutCallback := "stdOutCallback", this.StdErrCallback := "stdErrCallback"
		this.CliPromptCallback := "cliPromptCallback", this.delay := 10
		this.waitTimeout := 300, this.cmdTimeout := 0, this.showWindow := 0
		
		Loop, Parse, options, |
		{
			curOpt := A_LoopField
			If curOpt contains codepage:
				codepage := SubStr(curOpt,10), this.codepage:=(codepage="")?A_FileEncoding:codepage
			Else If curOpt contains workingDir:
				sDir := SubStr(curOpt,12), this.workingDir := sDir?sDir:A_WorkingDir
			Else If curOpt contains StdOutCallback:
				SoCb := SubStr(curOpt,16), this.StdOutCallback := SoCb?SoCb:"StdOutCallback"
			Else If curOpt contains StdErrCallback:
				SeCb := SubStr(curOpt,16), this.StdErrCallback := SeCb?SeCb:"StdErrCallback"
			Else If curOpt contains CliPromptCallback:
				CpCb := SubStr(curOpt,19), this.CliPromptCallback := CpCb?CpCb:"CliPromptCallback"
			Else If curOpt contains waitTimeout:
				wT := SubStr(curOpt,13), this.waitTimeout := wT?wT:300
			Else If curOpt contains cmdTimeout:
				cT := SubStr(curOpt,12), this.cmdTimeout := cT?cT:0
			Else If curOpt contains showWindow:
				sW := SubStr(curOpt,12), this.showWindow := sW?sW:0
			Else If curOpt contains delay:
				dL := SubStr(curopt,7), this.delay := dL?dL:10
			Else If curOpt contains ID:
				ID := SubStr(curOpt,4), this.ID := ID
			Else If curOpt contains mode:
				mode := SubStr(curOpt,6), this.mode := mode ? mode : "w"
		}
		
		cmdLines := this.shellCmdLines(sCmd,firstCmd,batchCmd) ; ByRef firstCmd / ByRef batchCmd
		this.firstCmd := firstCmd, this.batchCmd := batchCmd, this.lastCmd := firstCmd	; firstCmd, batchCmd, lastCmd property
		this.stream := ObjBindMethod(this,"sGet") ; register function Obj for timer (stream)
		
		cmdSwitchRegEx := "^cmd(?:\.exe)?[ ]?(((/A|/U|/Q|/D|/E:ON|/E:OFF|/F:ON|/F:OFF|/V:ON|/V:OFF|/S|/C|/K)?[ ]?)*)"
		cmdSwitchResult := RegExMatch(firstCmd,"i)" cmdSwitchRegEx,cmdSwitches), cmdSwitches := Trim(cmdSwitches1)
		cmdCmdRegEx := "^(" comspec "|cmd\.exe|cmd)"
		cmdCmdResult := RegExMatch(firstCmd,"i)" cmdCmdRegEx,cmdCmd), cmdCmd := cmdCmd1
		cmdCmdParams := Trim(StrReplace(StrReplace(firstCmd,cmdCmd,""),cmdSwitches,""))
		this.cmdSwitches := cmdSwitches, this.cmdCmd := cmdCmd, this.cmdCmdParams := cmdCmdParams
		
		If ((cmdCmd And InStr(cmdSwitches,"/K") And InStr(mode,"w")) Or (cmdCmd And !cmdSwitches) And InStr(mode,"w")) {
			MsgBox Using "cmd /K" or plain "cmd" with mode "w" (the default mode) will cause the script to halt indefinitely.
			return
		}
		
		If (InStr(mode,"c") = 0) ; if not invoking "custom" mode, run command
			this.runCmd()
	}
    __Delete() {
		mode := this.mode
		If (!InStr(mode,"m"))
			this.close() ; close all handles / objects
    }
	runCmd() {
		mode := this.mode
		modeCount := 0, modeCount += InStr(mode,"w")?1:0, modeCount += InStr(mode,"s")?1:0, modeCount += InStr(mode,"b")?1:0, modeCount += InStr(mode,"m")?1:0
		If (modeCount > 1) { ; check for mode conflicts
			MsgBox Conflicting modes detected.  Check documentation to properly set modes.
			return
		} Else If (modeCount = 0)
			mode .= "w", this.mode := mode			; imply "w" with no primary modes selected
		If (InStr(mode,"e") And !InStr(mode,"x"))	; imply "x" with "e"
			mode .= "x", this.mode := mode
		; If (InStr(mode,"i") And !InStr(mode,"b"))	; imply "b" with "i" ... or not...
			; mode .= "b", this.mode := mode
		If (InStr(mode,"(") And InStr(mode,")") And InStr(mode,"m")) { ; mode "m" !!
			s1 := InStr(mode,"("), e1 := InStr(mode,")"), mParam := SubStr(mode,s1+1,e1-s1-1), dParam := StrSplit(mParam,",")
			conWidth := dParam[1], conHeight := dParam[2], this.conWidth := conWidth, this.conHeight := conHeight
			mMode := dParam[3]?dParam[3]:"/C", this.mMode := mMode
		} Else If (InStr(mode,"m")) {
			this.conWidth := 100, this.conHeight := 10
		}
		
		firstCmd := this.firstCmd, mode := this.mode, stream := this.stream, delay := this.delay
		sDir := this.workingDir, sDirA := (sDir=A_WorkingDir Or !sDir) ? 0 : &sDir, cmdSwitches := this.cmdSwitches
		StdErrCallback := this.StdErrCallback, showWindow := this.showWindow, cmdCmd := this.cmdCmd
		
		If (!InStr(mode,"m")) { ; NOT mode "m"
			DllCall("CreatePipe","Ptr*",hStdInRd,"Ptr*",hStdInWr,"Uint",0,"Uint",0)		; get handle - stdIn (R/W)
			DllCall("CreatePipe","Ptr*",hStdOutRd,"Ptr*",hStdOutWr,"Uint",0,"Uint",0)	; get handle - stdOut (R/W)
			
			DllCall("SetHandleInformation","Ptr",hStdInRd,"Uint",1,"Uint",1)			; set flags inherit - stdIn
			DllCall("SetHandleInformation","Ptr",hStdOutWr,"Uint",1,"Uint",1)			; set flags inherit - stdOut
			If (InStr(mode,"x")) {
				DllCall("CreatePipe","Ptr*",hStdErrRd,"Ptr*",hStdErrWr,"Uint",0,"Uint",0) ; stdErr pipe on mode "x"
				DllCall("SetHandleInformation","Ptr",hStdErrWr,"Uint",1,"Uint",1)
			}
			
			this.hStdInRd := hStdInRd, this.hStdOutWr := hStdOutWr, this.hStdOutRd := hStdOutRd
			this.hStdOutRd := hStdOutRd, this.hStdInWr := hStdInWr
			
			if (A_PtrSize=4) {						; x86
				VarSetCapacity(pi, 16, 0)			; PROCESS_INFORMATION structure
				sisize:=VarSetCapacity(si,68,0)		; STARTUPINFO Structure
				NumPut(sisize, si,  0, "UInt")
				NumPut(0x101, si, 44, "UInt")		; dwFlags ; 0x100 = inherit handles ; 0x1 = check wShowWindow
				If (showWindow)
					NumPut(0x1, si, 48, "Int")		; wShowWindow / 0x1 = show
				Else
					NumPut(0x0, si, 48, "Int")		; wShowWindow / 0x0 = hide
				NumPut(hStdInRd , si, 56, "Ptr")	; stdIn handle
				NumPut(hStdOutWr, si, 60, "Ptr")	; stdOut handle
				If (InStr(mode,"x"))
					NumPut(hStdErrWr, si, 64, "Ptr")	; direct stdErr to stdOut
				Else
					NumPut(hStdOutWr, si, 64, "Ptr")	; stdErr handle
			}
			else if (A_PtrSize=8) {					; x64
				VarSetCapacity(pi, 24, 0)			; PROCESS_INFORMATION structure
				sisize:=VarSetCapacity(si,104,0)	; STARTUPINFO Structure
				NumPut(sisize, si,  0, "UInt")
				NumPut(0x101, si, 60, "UInt")		; dwFlags ; 0x100 = inherit handles ; 0x1 = check wShowWindow
				If (showWindow)
					NumPut(0x1, si, 64, "Int")		; wShowWindow / 0x1 = show
				Else
					NumPut(0x0, si, 64, "Int")		; wShowWindow / 0x0 = hide
				NumPut(hStdInRd , si, 80, "Ptr")	; stdIn handle
				NumPut(hStdOutWr, si, 88, "Ptr")	; stdOut handle
				If (InStr(mode,"x"))
					NumPut(hStdErrWr, si, 96, "Ptr")	; stdErr write handle
				Else
					NumPut(hStdOutWr, si, 96, "Ptr")	; direct stdErr to stdOut
			}
			
			this.shell := "windows"
			s := "^((.*[ ])?adb (-a |-d |-e |-s [a-zA-Z0-9]*|-t [0-9]+|-H |-P |-L [a-z0-9:_]*)?[ ]?shell)$"
			If (RegExMatch(firstCmd,s))
				this.shell := "android"
			
			r := DllCall("CreateProcess"
				, "Uint", 0					; application name
				, "Ptr", &firstCmd			; command line str
				, "Uint", 0					; process attributes
				, "Uint", 0					; thread attributes
				, "Int", True			 	; inherit handles - defined in si
				, "Uint", 0x00000010		; dwCreationFlags ; 0x00000010 = CREATE_NEW_CONSOLE
				, "Uint", 0					; environment
				, "Ptr", sDirA				; working Directory pointer
				, "Ptr", &si				; startup info structure - contains stdIn/Out handles
				, "Ptr", &pi)				; process info sttructure - contains proc/thread handles/IDs
			
			if (r) {
				pid := NumGet(pi, A_PtrSize*2, "uint")
				hProc := NumGet(pi,0), hThread := NumGet(pi,A_PtrSize)
				this.pid := pid, this.hProc := hProc, this.hThread := hThread
				If (InStr(mode,"m")) {
					atch := DllCall("AttachConsole","UInt",pid)
					hStdOutRd := DllCall("GetStdHandle", "int", -11, "ptr"), this.hStdOutRd := hStdOutRd
				}
				DllCall("CloseHandle","Ptr",hStdInRd)					; stdIn  read  handle not needed
				DllCall("CloseHandle","Ptr",hStdOutWr)					; stdOut write handle not needed
				
				this.fStdOutRd := FileOpen(hStdOutRd, "h", this.codepage)	; open StdOut file Obj
				If (InStr(mode,"x")) {
					DllCall("CloseHandle","Ptr",hStdErrWr)
					this.fStdErrRd := FileOpen(hStdErrRd, "h", this.codepage)
				}
				
				If (this.shell = "android") ; specific CLI shell fixes
					this.uWrite(this.checkShell())
				
				this.wait()				; wait for buffer to have data
				If (InStr(mode,"w")) {
					this.wGet()			; (wGet) wait mode
				} Else If (InStr(mode,"s") Or InStr(mode,"b"))
					SetTimer, % stream, %delay%		; data collection timer / default delay = 10ms
			} Else {
				if (this.output)
					this.output .= "`r`nINVALID COMMAND"
				Else
					this.output := "INVALID COMMAND"
				this.close()
			}
			If (this.cmdCmd And InStr(this.cmdSwitches,"/C") And !this.cmdCmdParams) { ; check if cmd /C with no params sent
				if (this.output)
					this.output .= "`r`nNo command sent?"
				Else
					this.output := "No command sent?"
			}
		} Else { ; mode "m" !! ; set buffer to width=200 / height=2 ... minimum 2 lines, or icky things happen
			; next line didn't work so well...
			; cmd := "cmd.exe " mMode " " chr(34) "MODE CON:COLS=" conWidth " LINES=" conHeight Chr(34) " & " firstCmd
			
			; this line worked better to launch mode "m"
			cmd := "cmd.exe " mMode " MODE CON: COLS=" conWidth " LINES=" conHeight " & " firstCmd
			; clipboard := cmd
			; msgbox % cmd
			runOpt := this.showWindow ? "" : "hide"
			Run, %cmd%,,%runOpt%,pid
			this.pid := pid
			
			while !(result := DllCall("AttachConsole", "uint", pid)) ; retry attach console until success
				sleep, 10
			
			hwnd := DllCall("GetStdHandle", "int", -11, "ptr"), this.hStdOutRd := hwnd ; get stdOut/console handle
			SetTimer, % stream, %delay%
		}
	}
	close() { ; closes handles and may/may not kill process instance
		mode := this.mode, stream := this.stream, pid := this.pid
		If (mode contains m) {
			SetTimer, % stream, Off
			DllCall("FreeConsole")
			Process, Close, %pid%		; if ErrorLevel = pid then close was successful, else PID never existed.
		} Else {
			StdErrCallback := this.StdErrCallback, hStdInWr:=this.hStdInWr, hStdOutRd:=this.hStdOutRd
			hProc:=this.hProc, hThread:=this.hThread
			DllCall("CloseHandle","Ptr",hStdInWr), DllCall("CloseHandle","Ptr",hStdOutRd)	; close stdIn/stdOut handle
			DllCall("CloseHandle","Ptr",hProc), DllCall("CloseHandle","Ptr",hThread)		; close process/thread handle
			this.fStdOutRd.Close()															; close fileObj stdout handle
			If (InStr(mode,"x"))
				DllCall("CloseHandle","Ptr",hStdErrRd), this.fStdErrRd.Close() ; close stdErr handles
		}
	}
	wait() {
		mode := this.mode, delay := this.delay, waitTimeout := this.waitTimeout, ticks := A_TickCount
		Loop {												; wait for Stdout buffer to have content
			Sleep, %delay% ; default delay = 10 ms
			Process, Exist, % this.pid						; check if process exited prematurely
			If (this.fStdOutRd.AtEOF = 0 Or !ErrorLevel)	; break when there's data or process terminates
				Break
			Else If (InStr(mode,"x") And this.fStdErrRd.AtEOF = 0)
				Break
			Else If (A_TickCount - ticks >= waitTimeout)	; default waitTimeout = 300 ms
				Break
		}
	}
	wGet() { ; wait-Get - pauses script until process exists AND buffer is empty
		ID := this.ID, delay := this.delay, mode := this.mode, cmdTimeout := this.cmdTimeout, ticks := A_TickCount
		StdOutCallback := this.StdOutCallback, StdErrCallback := this.StdErrCallback
		
		Loop {
			Sleep, %delay%									; reduce CPU usage (default delay = 10ms)
			buffer := this.fStdOutRd.read()					; check buffer
			If (buffer) {
				If (InStr(mode,"p")) {
					lastLine := this.shellLastLine(buffer)	; looks for end of data and/or shell change
					If (lastLine)
						buffer := RegExReplace(buffer,"\Q" lastLine "\E$","")
				}
				If (InStr(mode,"o") And IsFunc(StdOutCallback)) {
					%StdOutCallback%(buffer,ID)				; run callback function
				} Else
					this.output .= buffer					; collect data in this.output
			}
			
			If (InStr(mode,"x")) {							; if "x" mode, check stdErr
				stdErr := this.fStdErrRd.read()
				If (stdErr) {
					If (InStr(mode,"e") And IsFunc(StdErrCallback))
						%StdErrCallback%(stdErr,ID)
					Else
						this.error .= stdErr
				}
			}
			
			Process, Exist, % this.pid
			If (!ErrorLevel And this.fStdOutRd.AtEOF) ; process exits AND buffer is empty
				Break
			Else If (this.fStdOutRd.AtEOF And A_TickCount - ticks >= cmdTimeout And cmdTimeout > 0)
				Break
		}
	}
	sGet() { ; stream-Get (timer) - collects until process exits AND buffer is empty
		ID := this.ID, mode := this.mode, batchCmd := this.batchCmd, stream := this.stream ; stream (timer)
		StdOutCallback := this.StdOutCallback, StdErrCallback := this.StdErrCallback
		CliPromptCallback := this.CliPromptCallback, pid := this.pid, hStdOutRd := this.hStdOutRd
		
		If (!InStr(mode,"m")) {
			buffer := this.fStdOutRd.read()						; check buffer
			If (buffer) {
				lastLine := this.shellLastLine(buffer)			; looks for end of data and/or shell change
				If (lastLine and InStr(mode,"p"))
					buffer := this.removePrompt(buffer)
					; buffer := RegExReplace(buffer,"\Q" lastLine "\E$","")
				
				If (InStr(mode,"o") And IsFunc(StdOutCallback))
					%StdOutCallback%(buffer,ID)					; run callback function, or...
				Else
					this.output .= buffer						; collect data in this.output
			}
			If (lastLine And InStr(mode,"i") And IsFunc(CliPromptCallback))
				%CliPromptCallback%(lastLine,ID)	; run callback when prompt is ready
			
			If (InStr(mode,"x")) {
				stdErr := this.fStdErrRd.read()
				If (stdErr) {
					stdErr := Trim(stdErr,OmitChars:=" \t\r\n")
					If (InStr(mode,"e") And IsFunc(StdErrCallback))
						%StdErrCallback%(stdErr,ID)
					Else
						this.error .= stdErr "`r`n`r`n"
				}
			}
			
			fullEOF := this.fStdOutRd.AtEOF
			if (InStr(mode,"x")) {
				If (this.fStdOutRd.AtEOF And this.fStdErrRd.AtEOF)
					fullEOF := true
				Else
					fullEOF := false
			}
			
			Process, Exist, % this.pid					; check if process still exists
			If (!ErrorLevel And fullEOF)				; if process exits AND buffer is empty
				SetTimer, % stream, Off					; stop data collection timer
			
			If (InStr(mode,"b")) {
				If (lastLine And fullEOF) {					; process should be idle when prompt appears
					If (batchCmd)
						this.write(batchCmd)				; write next command in bach, if any
					Else {
						SetTimer, % stream, Off
						this.close()
						If (InStr(mode,"o") And IsFunc(StdOutCallback))
							%StdOutCallback%("`r`n__Batch Finished__",ID)
					}
				}
			}
		} Else { ; mode "m" !!
			conHeight := this.conHeight, conWidth := this.conWidth
			Process, Exist, %pid%
			If (ErrorLevel)
				this.mCountdown := 10
			Else
				this.mCountdown -= 1
			If (this.mCountdown) {
				VarSetCapacity(lpCharacter,conWidth*conHeight*2,0) ; console buffer size to collect
				VarSetCapacity(dwBufferCoord,4,0)
				
				result := DllCall("ReadConsoleOutputCharacter"
								,"UInt",hStdOutRd ; console buffer handle
								,"Str",lpCharacter ; str buffer
								,"UInt",conWidth * conHeight ; define console dimensions
								,"uint",Numget(dwBufferCoord,"uint") ; start point >> 0,0
								,"UInt*",lpNumberOfCharsRead,"Int")
				size := VarSetCapacity(lpCharacter,-1), str := ""
				Loop, % size/2 {
					crlf := (Mod(A_Index,conWidth)=0) ? "`r`n" : ""
					str .= Chr(NumGet(lpCharacter,(A_Index-1)*2,"UChar"))
					If (StrLen(crlf))
						str := Trim(str) crlf
				}
				str := Trim(str,OmitChars:=" `t`r`n")
				
				lastLine := this.shellLastLine(str)
				If (lastLine and InStr(mode,"p"))
					str := this.removePrompt(str)
				
				If (!InStr(mode,"o"))
					this.output := str
				Else If (IsFunc(StdOutCallback))
					%StdOutCallback%(str,ID)
				
				If (lastLine) {
					If (batchCmd)
						this.write(batchCmd)
					Else {
						SetTimer, % stream, Off
						this.close()
						If (InStr(mode,"o") And IsFunc(StdOutCallback))
							%StdOutCallback%("`r`n__Batch Finished__",ID)
					}
				}
			} Else {
				this.close()
				SetTimer, % stream, Off
			}
		}
	}
	write(sInput="") {
		sInput := Trim(sInput,OmitChars:="`r`n")
		If (sInput = "")
			Return
		
		mode := this.mode, ID := this.ID, delay := this.delay, stream := this.stream, pid := this.pid
		cmdLines := this.shellCmdLines(sInput,firstCmd,batchCmd) ; ByRef firstCmd / ByRef batchCmd
		this.batchCmd := batchCmd, this.lastCmd := firstCmd, this.cmdHistory .= firstCmd "`r`n"
		
		androidRegEx := "^((.*[ ])?adb (-a |-d |-e |-s [a-zA-Z0-9]*|-t [0-9]+|-H |-P |-L [a-z0-9:_]*)?[ ]?shell)$"
		If (RegExMatch(firstCmd,androidRegEx)) ; check shell change on-the-fly
			this.shell := "android"
		
		If mode contains m
		{
			DetectHiddenWindows, On
			ControlSend, , %sInput%`r`n, ahk_pid %pid%	
			DetectHiddenWindows, Off
		}
		Else
			f := FileOpen(this.hStdInWr, "h", this.codepage).Write(firstCmd "`r`n"), f.close(), f := "" ; send cmd

		If (this.shell = "android") ; check shell
			this.uWrite(this.checkShell()) ; ADB - appends missing prompt after data complete
	}
	uWrite(sInput="") {
		sInput := Trim(sInput,OmitChars:="`r`n")
		If (sInput != "")
            f := FileOpen(this.hStdInWr, "h", this.codepage).Write(sInput "`r`n"), f.close(), f := ""
	}
	read(chars="") {
		if (this.fStdOutRd.AtEOF=0)
			return chars=""?this.fStdOutRd.Read():this.fStdOutRd.Read(chars)
	}
	ctrlBreak() {
		If (InStr(this.mode,"m")) {
			stream := this.stream
			DllCall("FreeConsole")					; CTRL+Break and CTRL+C will not work without:
			SetTimer, % stream, Off					; dwCreationFlags : 0x00000010 = CREATE_NEW_CONSOLE
		}											; STARTUPINFO: dwFlags: 
		pid := this.pid								; 		0x100 = inherit handles, and...
		DetectHiddenWindows, On						; 		0x1   = check wShowWindow, and...
		ControlSend, , ^{CtrlBreak}, ahk_pid %pid%	; STARTUPINFO: wShowWindow: 0x0 = hide or 0x1 = show
		DetectHiddenWindows, Off
		If (InStr(this.mode,"m"))					; Window must exist for CTRL signals to work
			result := this.ReattachConsole()		; Original creation flag 0x08000000 (no window) overrides ...
	}												; ... dwFlags, thus CTRL signals won't work.
	ctrlC() {
		If (InStr(this.mode,"m")) {
			stream := this.stream
			DllCall("FreeConsole")
			SetTimer, % stream, Off
		}
		pid := this.pid
		DetectHiddenWindows, On						
		ControlSend, , ^c, ahk_pid %pid%			
		DetectHiddenWindows, Off
		If (InStr(this.mode,"m"))
			result := this.ReattachConsole()
	}
	KeySequence(sInput) {
		If (InStr(this.mode,"m")) {			; assume custom sequence is a CTRL signal ...
			stream := this.stream			; ... therefore detach console first, or script will exit.
			DllCall("FreeConsole")
			SetTimer, % stream, Off
		}
		pid := this.pid
		DetectHiddenWindows, On
		ControlSend, , %sInput%, ahk_pid %pid%
		DetectHiddenWindows, Off
		If (InStr(this.mode,"m"))
			result := this.ReattachConsole()
	}
	DetachConsole() {
		DllCall("FreeConsole")
	}
	ReattachConsole() {
		pid := this.pid, delay := this.delay, stream := this.stream
		Process, Exist, %pid%
		If (ErrorLevel) {
			while !(result := DllCall("AttachConsole", "uint", pid)) ; retry attach console until success
				sleep, 10
			
			hwnd := DllCall("GetStdHandle", "int", -11, "ptr"), this.hStdOutRd := hwnd ; get stdOut/console handle
			SetTimer, % stream, %delay%
			
			return "success" ; process exists and was reattached
		} else
			Return "fail" ; process no longer exists
	}
	kill() {	; not as important now that ctrlBreak() works, but still handy
		pid := this.pid
		Run, %comspec% /C TASKKILL /F /T /PID %pid%,,hide
		this.close()
	}
	shellLastLine(str) { ; catching windows prompt, or "end of data" string
		If (!str)
			return ""
		winRegEx := "[\r\n]*([A-Z]\:\\[^/?<>:*|" Chr(34) "]*>)$" ; orig: "[\n]?([A-Z]\:\\[^/?<>:*|``]*>)$"
		netshRegEx := "[\r\n]*(netsh[ a-z0-9]*\>)$"
		telnetRegEx := "[\r\n]*(\QMicrosoft Telnet>\E)$"
		androidRegEx := "[\r\n]*([\-_a-zA-Z0-9]*\:[^\r\n]* \>)$"
		
		If (RegExMatch(str,netshRegEx,match)) {
			this.shell := "netsh"
			result := match1
		} Else If (RegExMatch(str,telnetRegEx,match)) {
			this.shell := "telnet"
			result := match1
		} Else If (RegExMatch(str,winRegEx,match)) {
			this.shell := "windows"
			result := match1
		} Else If (RegExMatch(str,androidRegEx,match)) {
			this.shell := "android"
			result := match1
		} Else
			result := ""
		
		return result
	}
	removePrompt(str) {
		str := Trim(RegExReplace(str,"\Q" lastLine "\E$",""),OmitChars:=" `t`r`n")
		oneMore := this.shellLastLine(str)
		While (oneMore) {
			str := Trim(RegExReplace(str,"\Q" oneMore "\E$",""),OmitChars:=" `t`r`n")
			oneMore := this.shellLastLine(str)
		}
		return str
	}
	checkShell() {
		If (this.shell = "android")
			return "echo " Chr(34) "$HOSTNAME:$PWD >" Chr(34)
		Else
			return ""
	}
	shellCmdLines(str, ByRef firstCmd, ByRef batchCmd) {
		firstCmd := "", batchCmd := "", str := Trim(str,OmitChars:=" `t`r`n"), i := 0
		Loop, Parse, str, `n, `r
		{
			If (A_LoopField != "") {
				i++
				If (A_Index = 1)
					firstCmd := A_LoopField
				Else
					batchCmd .= A_LoopField "`r`n"
			}
		}
		return i
	}
	AtEOF() {
		return this.fStdOutRd.AtEOF
	}
	Length() {
		return this.fStdOutRd.Length
	}
}



; ========================================================================
; Modified  :  SKAN 31-Aug-2013 http://goo.gl/j8XJXY 
; Thanks to :  HotKeyIt         http://goo.gl/IsH1zs     
; Original  :  Sean 20-Feb-2007 http://goo.gl/mxCdn
; x64 by    :  maz_1            https://bit.ly/2TvU5UQ
; thans to SKAN, HotKeyIt, Sean, maz_1
; ========================================================================
StdOutStream(sCmd,Callback="") {                             
    Static StrGet := "StrGet"                                         

    DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
    DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )

    VarSetCapacity( STARTUPINFO, 104, 0  )      ; STARTUPINFO          ;  http://goo.gl/fZf24
    NumPut( 68,         STARTUPINFO,  0 )      ; cbSize
    NumPut( 0x100,      STARTUPINFO, 60 )      ; dwFlags    =>  STARTF_USESTDHANDLES = 0x100 
    NumPut( hPipeWrite, STARTUPINFO, 88 )      ; hStdOutput ; skipping stdIn
    NumPut( hPipeWrite, STARTUPINFO, 96 )      ; hStdError

    VarSetCapacity( PROCESS_INFORMATION, 32 )  ; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI      

    If ! DllCall( "CreateProcess"
		, UInt,0
		, UInt,&sCmd
		, UInt,0
		, UInt,0 ;  http://goo.gl/USC5a
		, UInt,1 ; inherit handles
		, UInt,0x08000000
		, UInt,0
		, UInt,0
		, UInt,&STARTUPINFO
		, UInt,&PROCESS_INFORMATION ) 
    Return "", DllCall( "CloseHandle", UInt,hPipeWrite ), DllCall( "CloseHandle", UInt,hPipeRead ), DllCall( "SetLastError", Int,-1 )
	
    hProcess := NumGet( PROCESS_INFORMATION, 0 )                 
    hThread  := NumGet( PROCESS_INFORMATION, 8 )                      

    DllCall( "CloseHandle", UInt,hPipeWrite )

    AIC := ( SubStr( A_AhkVersion, 1, 3 ) = "1.0" )                   ;  A_IsClassic 
    VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 

    While DllCall( "ReadFile", UInt,hPipeRead ; DllCall() ReadFile
							 , UInt,&Buffer
							 , UInt,4094
							 , UIntP,nSz
							 , Int,0 ) {
		
        tOutput := (AIC && NumPut(0,Buffer,nSz,"Char") && VarSetCapacity(Buffer,-1)) ? Buffer : %StrGet%(&Buffer,nSz,"CP850")
		; ? Buffer : %StrGet%( &Buffer, nSz, "CP850" )

        Isfunc( Callback ) ? %Callback%( tOutput, A_Index ) : sOutput .= tOutput
    }

    DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
    DllCall( "CloseHandle",  UInt,hProcess  )
    DllCall( "CloseHandle",  UInt,hThread   )
    DllCall( "CloseHandle",  UInt,hPipeRead )
    DllCall( "SetLastError", UInt,ExitCode  )

    Return Isfunc( Callback ) ? %Callback%( "", 0 ) : sOutput      
}

; StdOutStream_Callback( data, n ) {
  ;;;; use static variable to accumulate data in a single variable
  ;;;; ---
  ;;;; n = line number
  ;;;; data = input text
  
  ; If !(n) {
    ;;;; this is end of stream
  ; }
; }

; ========================================================================
; https://autohotkey.com/board/topic/15455-stdouttovar/page-7#entry486617
; Posted by: Sweeet, sean, and maraksan_user
; Originally by: sean and maraksan_user
; original function name: StdoutToVar_CreateProcess
; ========================================================================
StdoutToVar(sCmd, bStream="", sDir="", sInput="") {
	bStream=   ; not implemented
	sDir=      ; not implemented
	sInput=    ; not implemented
   
	DllCall("CreatePipe", "Ptr*", hStdInRd , "Ptr*", hStdInWr , "Uint", 0, "Uint", 0) ; get handles - stdIn - read,write - stdErr not used
	DllCall("CreatePipe", "Ptr*", hStdOutRd, "Ptr*", hStdOutWr, "Uint", 0, "Uint", 0) ; get handles - stdOut - read,write - stdErr not used
	DllCall("SetHandleInformation", "Ptr", hStdInRd , "Uint", 1, "Uint", 1) ; set flags inherit - stdIn
	DllCall("SetHandleInformation", "Ptr", hStdOutWr, "Uint", 1, "Uint", 1) ; set flags inherit - stdOut
	
	if A_PtrSize = 4	; Fill a StartupInfo structure ; We're on a 32-bit system.
	{
		VarSetCapacity(pi, 16, 0)
		sisize := VarSetCapacity(si, 68, 0)
		NumPut(sisize,    si,  0, "UInt")
		NumPut(0x100,     si, 44, "UInt")	; use sdIn/Out/Err handles
		NumPut(hStdInRd , si, 56, "Ptr")	; hStdin
		NumPut(hStdOutWr, si, 60, "Ptr")	; hStdout
		NumPut(hStdOutWr, si, 64, "Ptr")	; hStderr
	}
	else if A_PtrSize = 8	; Fill a StartupInfo structure ; We're on a 64-bit system.
	{
		VarSetCapacity(pi, 24, 0)
		sisize := VarSetCapacity(si, 96, 0)
		NumPut(sisize,    si,  0, "UInt")
		NumPut(0x100,     si, 60, "UInt")	; use sdIn/Out/Err handles
		NumPut(hStdInRd , si, 80, "Ptr")	; hStdin
		NumPut(hStdOutWr, si, 88, "Ptr")	; hStdout
		NumPut(hStdOutWr, si, 96, "Ptr")	; hStderr
	}
    
    If (sCmd <> "") {
        DllCall("CreateProcess", "Uint", 0			 ; Application Name
                               ,  "Ptr", &sCmd	     ; Command Line
                               , "Uint", 0			 ; Process Attributes
                               , "Uint", 0			 ; Thread Attributes
                               ,  "Int", True		 ; Inherit Handles
                               , "Uint", 0x08000000  ; Creation Flags (0x08000000 = Suppress console window)
                               , "Uint", 0			 ; Environment
                               , "Uint", 0			 ; Current Directory
                               ,  "Ptr", &si		 ; Startup Info
                               ,  "Ptr", &pi)		 ; Process Information
        
        DllCall("CloseHandle", "Ptr", NumGet(pi, 0))
        DllCall("CloseHandle", "Ptr", NumGet(pi, A_PtrSize))
        DllCall("CloseHandle", "Ptr", hStdOutWr)
        DllCall("CloseHandle", "Ptr", hStdInRd)
        DllCall("CloseHandle", "Ptr", hStdInWr)

        VarSetCapacity(sTemp, 4095)
        nSize := 0
        loop
        {
            result := DllCall("Kernel32.dll\ReadFile", "Uint", hStdOutRd	; hFile
													 , "Ptr", &sTemp		; lpBuffer
													 , "Uint", 4095			; nNumberOfBytesToRead
													 , "UintP", nSize		; lpNumberOfBytesRead
													 , "Uint", 0)			; lpOverlapped
            if (result = "0")
                break
            else
				sOutput := sOutput . StrGet(&sTemp, nSize, "CP850")
        }

        DllCall("CloseHandle", "Ptr", hStdOutRd)
        return, sOutput
    }
}

; ========================================================================
; retrofitted from original post by Ferry
; URL: https://autohotkey.com/board/topic/103403-ipc-using-named-pipes/
; ========================================================================
; NamedPipeCreate(ArkPipeName, OpenMode=3, PipeMode=0, MaxInstances=255) { ; OpenMode: 1=in / 2=out / 3=2-way ; \\[computer]\pipe\[pipe name]
    ; ArkPipeName := "\\.\pipe\" ArkPipeName
    
    ; ptr := (A_PtrSize = 8) ? "Ptr" : "UInt" ; test this
    
    ; ArkPipeHandle := DllCall("CreateNamedPipe", "str", ArkPipeName, ; CreateNamedPipe returns -1 on fail
                                              ; . "uint", OpenMode,
                                              ; . "uint", PipeMode,
                                              ; . "uint", MaxInstances,
                                              ; . "uint", 0,
                                              ; . "uint", 0,
                                              ; . "uint", 0,
                                              ; . ptr, 0,
                                              ; . ptr)
    
    ; If (ArkPipeHandle = -1) {
    
    ; } Else If (ArkPipeHandle = 0) {
        ; MsgBox Handle = 0 ... now what? (Check CreateNamedPipe on MSDN)
        ; return 0
    ; } Else {
        ; ArkPipeConnectResult := DllCall("ConnectNamedPipe", ptr, ArkPipeHandle, ptr, 0)
        
        ; If (ArkPipeConnectResult = 0) {
            ; MsgBox Pipe was created but failed to connect.`r`n`r`n%ErrorLevel%
            ; CloseResult := DllCall("CloseHandle", ptr, ArkPipeHandle)
            
            ; If (CloseResult = 0) {
                ; MsgBox Pipe could not be closed.
                ; return ArkPipeHandle
            ; } Else {
                ; return 0
            ; }
        ; } Else {
            ; return ArkPipeHandle
        ; }
    ; }
; }

; ========================================================================
; retrofitted from original post by Ferry
; URL: https://autohotkey.com/board/topic/103403-ipc-using-named-pipes/
; ========================================================================
; NamedPipeWrite(ArkPipeMsg,ArkPipeHandle) { ; NamedPipeWrite() returns 0 on fail ; use A_ErrorLevel / ErrorMessage to check if async is happening
    ; ptr := (A_PtrSize = 8) ? "Ptr" : "UInt"
    ; char_size := A_IsUnicode ? 2 : 1 ;;;; <- this happens only for write()
    ; ArkPipeMsg := (A_IsUnicode ? chr(0xfeff) : chr(239) chr(187) chr(191)) . ArkPipeMsg
    
    ; PipeWriteResult := DllCall("WriteFile", ptr, ArkPipeHandle,
                                          ; . "str", ArkPipeMsg,
                                          ; . "uint", (StrLen(ArkPipeMsg)+1)*char_size,
                                          ; . "uint*", 0,
                                          ; . ptr, 0)
    
    ; return PipeWriteResult
; }

; ========================================================================
; retrofitted from original post by Ferry
; URL: https://autohotkey.com/board/topic/103403-ipc-using-named-pipes/
; ========================================================================
; NamedPipeClose(ArkPipeHandle) {
    ; ptr := (A_PtrSize = 8) ? "Ptr" : "UInt"
    ; DllCall("CloseHandle", ptr, ArkPipeHandle)
; }

; ========================================================================
; originally posted by Lexikos
; URL: https://autohotkey.com/board/topic/54559-stdin/
; ========================================================================
; StdIn3(max_chars=0xfff) {
    ; static hStdIn=-1
	
    ; ptrtype := (A_PtrSize = 8) ? "ptr" : "uint" ; The following is for vanilla compatibility

    ; if (hStdIn = -1) {
        ; hStdIn := DllCall("GetStdHandle", "UInt", -10,  ptrtype) ; -10=STD_INPUT_HANDLE
        ; if ErrorLevel
            ; return 0
    ; }

    ; max_chars := VarSetCapacity(text, max_chars*(!!A_IsUnicode+1), 0)

    ; ret := DllCall("ReadFile"
        ; ,  ptrtype, hStdIn                        ; hFile
        ; , "Str", text                             ; lpBuffer
        ; , "UInt", max_chars*(!!A_IsUnicode+1)     ; nNumberOfBytesToRead
        ; , "UInt*", bytesRead                      ; lpNumberOfBytesRead
        ; ,  ptrtype, 0)                            ; lpOverlapped

    ; return text
; }

; ========================================================================
; originally posted by fincs
; URL: https://autohotkey.com/board/topic/54559-stdin/
; ========================================================================
; StdIn2(max_chars=0xfff) {
    ; static hStdIn=-1

    ; if (hStdIn = -1) {
        ; hStdIn := DllCall("GetStdHandle", "UInt", -10) ; -10=STD_INPUT_HANDLE
        ; if ErrorLevel
            ; return 0
    ; }

    ; max_chars := VarSetCapacity(text, max_chars, 0)

    ; ret := DllCall("ReadFile"
                 ; , "UInt", hStdIn        ; hFile
                 ; ,  "Str", text          ; lpBuffer
                 ; , "UInt", max_chars     ; nNumberOfBytesToRead
                 ; , "UIntP", bytesRead    ; lpNumberOfBytesRead
                 ; , "UInt", 0)            ; lpOverlapped

    ; return text
; }

; ========================================================================
; posted by ObiWanKenobi
; URL: https://autohotkey.com/board/topic/54559-stdin/
; ========================================================================
; StdIn(piMaxChars:=4095, psEncoding:="CP0") {
    ; sRetVal:=""
    ; static hStdIn:=-1

    ; if (hStdIn=-1) {
        ; hStdIn := DllCall("GetStdHandle", UInt, -10) ; -10=STD_INPUT_HANDLE
        ; if ErrorLevel
            ; return 0
    ; }

    ; VarSetCapacity(sText, piMaxChars)
    ; while (DllCall("ReadFile", Ptr, hStdIn, Ptr, &sText, UInt, piMaxChars, PtrP, nSize, Ptr, 0))
        ; sRetVal .= StrGet(&sText, nSize, psEncoding)

    ; return sRetVal
; }