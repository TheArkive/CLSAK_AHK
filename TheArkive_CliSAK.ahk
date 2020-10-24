; AHK v1
; ================================================================
; === cli class, easy one-time and streaming output that collects stdOut and stdErr, and allows writing to stdIn.
; === huge thanks to:
; ===    user: segalion ; https://autohotkey.com/board/topic/82732-class-command-line-interface/#entry526882
; === ... who posted his version of this on 20 July 2012 - 08:43 AM.
; === his code was so clean even I could understand it, and I'm new to classes!
; === another huge thanks to:
; ===    user(s): Sweeet, sean, and maraksan_user ; https://autohotkey.com/board/topic/15455-stdouttovar/page-7#entry486617
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
; === Thanks to Lexikos for his old ConsoleSend() function.  https://autohotkey.com/board/topic/25446-consolesend/
; === This function provided one of the final bits of functionality I needed to finalize this library.
; ===
; === This class basically combines StdoutToVar() and StdOutStream() into one package, and has several other features for a 
; === very dynamic CLI management.  I am NOT throwing shade at StdoutToVar(), StdOutStream(), or the people who created
; === them.  Those functions were amazing milestones.  Without those functions, this version, and other implementations like
; === LibCon would likely not have been possible.

; ========================================================================================================
; CliData(inCommand)
; ========================================================================================================
;
;   Usage:   var := CliData("cmd /C you_command here")
;
;       Using this library, this function is the easiest way to "just run a command and collect the data".
;       Generally this should always be launched with "cmd /C".
;
; ========================================================================================================
;   new cli(sCmd, options="")
; ========================================================================================================
;     Parameters:
;
;       sCmd        (required)
;
;           Single-line command or multi-line batch command, depending on mode: specified in options.
;           If you are using WAIT mode ("w"), then this must be a single line.  Multiple commands can be
;           concatenated with "&" or "&&" or "||".
;
;           This class will ensure your command conforms to the following criteria below:
;
;             Your command should be formatted as follows:
;
;               1) CMD /C your_command(s)     (default Primary mode, "w")
;                   your_command = Must be single line.  Commands can be concatenated with &, &&, or ||.
;
;               2) CMD /K your_command(s)     (streaming Primary modes, "s" or "m")
;                   your_command = Can be single or multi-line.  This can be like a batch file, except
;                                  certain batch environment conventions won't work.  Don't think of this
;                                  or treat this as a true batch environment.  You can launch an
;                                  interactive session and dynamically manipulate the commands run as well
;                                  as the parameters passed to the CLI session using streaming modes.
;
;                                  If your command doesn't conform to this an error will be thrown.
;
;       options    (optional)
;
;           Zero or more of the following strings, pipe (|) delimited:
; ========================================================================================================
; Options
; ========================================================================================================
;
;   ID:MyID
;       User defined string to identify CLI sessions.  This is used to identify a CLI instance in
;       callback functions.  If you manage multiple CLI sessions simultaneously you may want to use this
;       option to tell which session is which within your callback functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   Modes define how the CLI instance is launched and handled.
;
;   mode:[modes]  -  Primary Modes
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;        
;        There are 2 main categories of modes:
;           1) Wait mode (mode "w")   Command format:   cmd /C your_command
;              - Simply run the command, collect data, and exit.
;
;           2) Stream mode (modes "s" = stream, "m" = monitor)
;              - Much more flexibility.  Among other things, the stream modes allow callback functions for
;                StdOut, StdErr, prompt events, and a user-defined QuitString (just to name a few).
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;        IMPORTANT NOTES ABOUT STREAMING MODES:
;           - When using stream modes, the user MUST call obj.Close() to terminate the open handles after
;             properly exiting the program.  "Properly exiting the program" means the CLI session is still
;             active, but idle.  If you don't properly exit the program you may see the following processes
;             remaining in Task Manager:
;                1) cmd.exe
;                2) the program you ran on the command line
;                3) conhost.exe
;
;           - Using streaming mode REQUIRES the user to be familiar with how to propertly close, interrupt,
;             and terminate the program.  Improperly using/closing/interrupting/terminating the CLI program 
;             will likely result in the user needing to forcefully exit the program manually.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;
;        *** Specify ONLY ONE of the following primary modes ***
;        *** If you specify more than one of these primary modes you will get an error ***
;
;        mode "w" = Wait mode, run command, collect data, and exit (default mode).
;            If no modes are specified then "w" is assumed.  Note that the function that runs using this
;            mode will hang if the process hangs, or if the process is returning a lot of data.
;            >>> For best results, always use:   cmd /C your_command
;
;        mode "s" = Streaming mode, continual collection until exit.  The user MUST call obj.Close() AFTER
;           properly terminating the program to cleanup the open handles.
;           >>> For best results, always use:   cmd /K your_command_or_batch   (#NotATrueBatchEnvironment)
;
;        mode "m" = Monitoring mode, this launches a hidden CLI window and records text as you would 
;           actually see it from the console.  Usually used with the StdOut callback function.  Useful for
;           capturing animations like incrementing percent, or a progress bar... ie.  [90%]{======> }
;
;           These kinds of animations are not sent to StdOut, only to the console, hence mode "m".
;
;               Usage: m(width, height)
;               - width : number of columns (of characters)
;               - height: number of rows
;
;                   Note: A smaller area captured performs better than capturing a larger area.  Be sure
;                   to use at least 2 rows.  A single row will usually be generally unusable.
;
;           Your initial command will be modified to resize the console if you specify m(w,h).
;           For Example:
;               cmd [SWITCHES] MODE CON: COLS=[width] LINES=[height] & your_first_command
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;    mode:[modes]  -  Secondary Modes
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;        *** Append these modes as needed to further modify/refine CLI behavior ***
;
;        mode "c" = Delay sCmd execution.  Execute with obj.RunCmd()  Optionally set more options by
;            specifying:    CLIobj.option := value
;
;        mode "x" = Extract StdErr in a separate pipe for each packet.  The full StdErr stream for the
;           session is still stored in CLIobj.stderr.
;
;        mode "e" = Use StdErr callback function.  Each StdErr packet sent fires the callback function.
;            StdErr stream for the session is still stored in CLIobj.stderr
;            Note that mode "e" implies mode "x".
;
;            ** Default callback: stdErrCallback(data,ID,CLIobj)
;            ** For a description of CLIobj, see Methods and Properties below.
;
;        mode "o" = Use StdOut callback function.
;            The full StdOut stream for the session is still stored in CLIobj.stdout
;
;            ** Default callback: stdOutCallback(data,ID,CLIobj)
;            ** For a description of CLIobj, see Methods and Properties below.
;
;        mode "p" = Uses a callback function to capture the prompt from StdOut and fires the callback.
;            This is useful to detect when a command is finished running.
;
;            ** Default callback: PromptCallback(prompt,ID,CLIobj)
;            ** For a description of CLIobj, see Methods and Properties below.
;
;        mode "r" = Prune mode, remove prompt from StdOut data.
;
;        mode "f" = Filter control codes.  This mostly pertains to an SSH session, or older ADB sessions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;    More Options
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;
;   workingDir:c:\myDir
;       Set working directory.  Defaults to %A_ScriptDir%.  Commands that generate files will put those
;       files here, unless otherwise specified in the command parameters.
;
;   codepage:CP###
;       Codepage (UTF-8 = CP65001 / Windows Console = CP437 / etc...)
;
;   stdOutCallback:Give_It_A_Name
;       Defines the stdOutCallback function name.  Enabled with mode "o".
;       > Default callback: stdOutCallback(data,ID,CLIobj)
;
;   stdErrCallback:Give_It_A_Name
;       Defines the stdErrCallback function.  Enabled with modes "x" and "e".
;       > Default callback: stdErrCallback(data,ID,CLIobj)
;
;   PromptCallback:Give_It_A_Name
;       Defines the PromptCallback function.  Enabled with mode "p".
;       > Default callback: PromptCallback(prompt,ID,CLIobj)
;
;   QuitCallback:Give_It_A_Name
;       Defines the QuitCallback function.
;       > Default callback: QuitCallback(quitString,ID,CLIobj)
;       > The QuitString option must be set in order to use the QuitCallback.
;
;   QuitString:Your_Quit_Msg_Here
;       If you define this option, and if the QuitCallback function exists, then the specified string
;       will be searched while the output is streaming.  If this string is found at the end of a StdOut
;       packet (usually right before a prompt event as a command finishes) then data collection will
;       halt and the QuitCallback will be triggered, then the process will be terminated.  Usually you
;       will have your QuitString defined as the last line of your batch, ie. "ECHO My Quit String", or
;       your QuitString will be a known message output by one of your programs run within the CLI session.
;
;   showWindow:#
;       Specify 0 or 1.  Default = 0 to hide.  1 will show.
;       Normally the CLI window will always be blank, except i mode "m".  The CLI window exists so that
;       control signals (CTRL+C / CTRL+Break / etc.) can be sent to the window.  See the Methods section
;       below.  Ultimately this is only provided as a convenience but isn't all that useful.
;
;   waitTimeout:###   (ms)
;       The waitTimeout is an internal correction.  There is a slight pause after sCmd execution before
;       the buffer is filled with data.  This class will check the buffer every 10 ms (up to a max
;       specified by waitTimeout, default: 300 ms).  Usually, it doesn't take that long for the buffer to
;       have data after executing a command.  If your command takes longer than 300ms to return data, then
;       you may need to increase this value for proper functionality.
;
;   cmdTimeout:0   (ms)
;       By default, cmtTimeout is set to 0, to wait for the command to complete indefinitely.  This mostly
;       only applies to mode "w".  If you use this class under normal circumstances, you shouldn't need to
;       modify this value.
;
;       This is provided as a convenience, but is generally not recommended for use.  Try using streaming
;       modes ("s" or "m"), or use methods .CtrlC() or .CtrlBreak() (see below) before using this value.
;       If your command is taking a while to return it may be because of the following reasons:
;
;           1) The command is returning more data than anticipated.  Use streaming mode, or wait.
;           2) You might have misused the command.
;           3) Your CLI session might actually be interactive.
;
; ========================================================================================================
; CLI class Methods and properties (also CLIobj parameter for callback functions).
; ========================================================================================================
;     Methods:
; ========================================================================================================
;
;    CLIobj.runCmd()
;       Runs the command specified in sCmd parameter.  This is meant to be used with mode "c" when
;       delayed execution is desired.
;
;    CLIobj.close()
;       Closes all open handles and tries to end the session.  Ending sessions like this usually only
;       succeeds when the CLI prompt is idle.  If you need to force termination then send a CTRL+C or
;       CTRL+Break signal first.  Read more below.
;
;    CLIobj.CtrlC()
;       Sends a CTRL+C signal to the console.  Usually this cancels whatever command is running, but it
;       depends on the command.
;
;    CLIobj.CtrlBreak()
;       Sends a CTRL+Break signal to the console.  Usually this will cancel whatever command is running,
;       but it depends on the command.
;
;    CLIobj.kill()
;       Attempts to run TASKKILL on the process launched by sCmd.  This is only provided as a convenience.
;       Don't use this if you can avoid it.  If this CLI class is properly used, and if your application
;       makes proper use of the CLI, then it is easy to terminate a process by using CLIobj.CtrlC() or
;       CLIobj.CtrlBreak(), and then if necessary finish up with CLIobj.close()
;
;   CLIobj.GetLastLine(str)
;       Returns last line of "str".  This is useful in callback functions.
;
; ========================================================================================================
;    Properties (useful with CLIobj in callback functions):
; ========================================================================================================
;
;    CLIobj.stdout
;        This is the full output of StdOut during the session.  You can check or clear this value.
;
;    CLIobj.stderr
;        This is the full output of StdErr during the session.  You can check or clear this value.
;
;    CLIobj.[option]
;        All options above are also properties that can be checked or set.
;
;    CLIobj.pID, CLIobj.tID
;        Get the process/thread ID of the CLI session.
;
;   CLIobj.hProc, CLIobj.hThread
;       Get the handle to the process/thread of the CLI session.
;
;   CLIobj.lastCmd
;       This is the last command that was run during your CLI session.  Usually this command is the one
;       that is currently being executed.
;
;   CLIobj.cmdHistory
;       This is a text list (delimited by `r`n) of commands executed so far during your CLI session. The
;       last command in the list is the same as the lastCmd property.
;
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; The following options are included as a convenience for power users.  Use with caution.
; Most CLI functionality can be handled without using the below methods / properties directly.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;
;    CLIobj.write(sInput)
;        Write to StdIn and send commands.  CRLF is appended automatically.
;
;    CLIobj.read(n:=0)
;        Read N bytes from the buffer.  Default is to read all bytes if n is not specified.
;
;    CLIobj.AtEOF()   (EOF = end of file)
;        Returns 0 if there is data waiting to be read in the buffer, otherwise 1 if the buffer is empty.
;
;    CLIobj.Length()
;        Returns the number of bytes in the buffer waiting to be read.
;
;    CLIobj.KeySequence("string")
;        Sends a key sequence, ie. CTRL+Key.  DO NOT use this like the .write() method.  Only use this
;        to send control signals other than CTRL+C and CTRL+Break to the CLI session.
;
;    NOTE: Whatever values you get when using CLIobj.AtEOF() and CLIobj.Length() are only true for the exact
;    instant you happen to check them.  Once you read the buffer these values will change.  Furthermore,
;    just because you read the buffer, doesn't mean you are done reading it.  You can only read the buffer
;    approximately 4,096 bytes at a time.  Also, just because there doesn't happen to be data in the buffer
;    now doesn't mean there won't be 10 ms later.
;            
; ========================================================================================================
; I know this class is a bit of a monster.  Please check the example script for practical appliations.
; ========================================================================================================

CliData(inCommand:="") {
    If (!inCommand)
        return ""
    Else {
        cli_session := new cli(inCommand)                           ; run command
        result := (cli_session.stdout) ? cli_session.stdout : ""    ; get the data
        cli_session.close(), cli_session := ""                      ; clean up
        return result                                               ; return result
    }
}

class cli {
    StdOutCallback:="stdOutCallback", StdErrCallback:="stdErrCallback"
    PromptCallback:="PromptCallback", QuitCallback:="QuitCallback", QuitString:=""
    delay:=10, waitTimeout:=300, cmdTimeout:=0, showWindow:=0, codepage:="CP0", workingDir:=A_WorkingDir, shell:="windows"
    ID:="", mode:="w", hStdIn:=0, hStdOut:=0, hStdErr:=0, stdout:="", stdoutRaw:="", stderr:="", cmdHistory:="", conWidth:=0, conHeight:=0
    batchCmd:="", firstCmd:="", lastCmd:="", cmdCmd:="", cmdSwitches:="", cmdProg:="", useAltShell := "", reason:=""
    
    __New(sCmd, options:="") {
        this.sCmd := sCmd, q := Chr(34), optGrp := StrSplit(options,"|")   ; next load specified properties (options param)
        For i, curItem in optGrp                        ; write options to "this"
            optItem := StrSplit(curItem,":"), this[optItem[1]] := optItem[2]
        
        cmdLines := this.shellCmdLines(sCmd,firstCmd,batchCmd) ; ByRef firstCmd / ByRef batchCmd
        this.firstCmd := firstCmd, this.batchCmd := batchCmd, this.lastCmd := firstCmd    ; firstCmd, batchCmd, lastCmd property
        this.stream := ObjBindMethod(this,"sGet") ; register function Obj for timer (stream)
        
        cmdSwitchRegEx := "^(cmd|cmd\.exe)[ ]*((/A|/U|/Q|/D|/E:ON|/E:OFF|/F:ON|/F:OFF|/V:ON|/V:OFF|/S|/C|/K| )*)(.*)"
        cmdSwitchResult := RegExMatch(firstCmd,"iO)" cmdSwitchRegEx,cmdElements)
        
        If (IsObject(cmdElements)) {
            cmdCmd := Trim(cmdElements.Value(1)), cmdSwitches := Trim(cmdElements.Value(2)), cmdProg := Trim(cmdElements.Value(4))
            this.cmdSwitches := cmdSwitches, this.cmdCmd := cmdCmd, this.cmdProg := cmdProg
        }
        
        IsInvalid := this.validateCmd()
        If (IsInvalid) {
            msg := "INVALID MODE/SWITCH COMBINATION OR NO COMSPEC USED`r`n`r`n"
                 . "1) Your CLI session should always start with " q "CMD" q ".`r`n`r`n"
                 . "2) If you just want to simply collect data, you must use:`r`n`tcmd /C your_command`r`n`r`n"
                 . "3) If you want to run a batch or create an interactive CLI session, use:`r`n`tcmd /K your_command`r`n`r`n"
                 . "When running a batch or interactive session, you will always need to manually terminate the CLI session using obj.Close()`r`n`r`n"
                 . "Using other switches on CMD is fine as long as you understand the effect it has on the CLI session.`r`n`r`n"
                 . "Command:`r`n`r`n" sCmd "`r`n`r`n"
                 . "Reason: " this.reason
            MsgBox % msg
            return
        }
        
        If (!InStr(this.mode,"c"))
            this.runCmd()
    }
    validateCmd() {
        IsInvalid := false, m := this.mode, s := this.cmdSwitches
        ;If (this.cmdCmd = "") ; doesn't start with COMSPEC
        ;    IsInvalid := true, this.reason:="Command doesn't start with CMD(.EXE)"
        If InStr(m,"w") And (InStr(s,"/K")) ; wait mode + /K
            IsInvalid := true, this.reason:="/K with WAIT mode (W)"
        If (InStr(m,"m") Or InStr(m,"s")) And InStr(s,"/C") ; stream mode + /C
            IsInvalid := true, this.reason:="/C with STREAMING mode (S or M)"
        
        return IsInvalid
    }
    __Delete() {
        this.close() ; close all handles / objects
    }
    runCmd() {
        p := A_PtrSize
        mode := this.mode, modeList := "wsbm", modeCount := 0, m := !InStr(mode,"m") ? 0 : 1 ; check for mode "m"
        Loop, Parse, modeList
            modeCount += InStr(mode,A_LoopField)?1:0
        
        If (modeCount > 1) { ; check for mode conflicts
            MsgBox % "Conflicting modes detected.  Check documentation to properly set modes."
            return
        } Else If (modeCount = 0)
            mode .= "w", this.mode := mode            ; imply "w" with no primary modes selected
        If (InStr(mode,"e") And !InStr(mode,"x"))     ; imply "x" with "e"
            mode .= "x", this.mode := mode
        If (InStr(mode,"(") And InStr(mode,")") And m) { ; mode "m" !!
            s1 := InStr(mode,"("), e1 := InStr(mode,")"), mParam := SubStr(mode,s1+1,e1-s1-1), dParam := StrSplit(mParam,",")
            conWidth := dParam[1], conHeight := dParam[2], this.conWidth := conWidth, this.conHeight := conHeight
            this.firstCmd := comspec " " this.cmdSwitches " MODE CON: COLS=" conWidth " LINES=" conHeight " & " this.cmdProg
        } Else If (m)
            this.conWidth := 100, this.conHeight := 10
        
        enc := !StrLen(Chr(0xFFFF))?"UTF-8":"UTF-16"
        batchCmd := this.batchCmd, mode := this.mode, delay := this.delay
        
        bSize := StrPut(this.firstCmd,enc) * (!StrLen(Chr(0xFFFF))?1:2)
        VarSetCapacity(bFirstCmd,bSize,0)
        StrPut(this.firstCmd, &bFirstCmd, enc)
        
        bSize := StrPut(this.workingDir,enc) * (!StrLen(Chr(0xFFFF))?1:2)
        VarSetCapacity(bWorkingDir,bSize,0)
        StrPut(this.workingDir, &bWorkingDir, enc)
        
        cmdSwitches := this.cmdSwitches
        StdErrCallback := this.StdErrCallback, showWindow := this.showWindow, cmdCmd := this.cmdCmd
        
        If (!m) {
            r1 := DllCall("CreatePipe","Ptr*",hStdInRd:=0,"Ptr*",hStdInWr:=0,"Uint",0,"Uint",0) ; get handle - stdIn (R/W)
            r2 := DllCall("SetHandleInformation","Ptr",hStdInRd,"Uint",1,"Uint",1)            ; set flags inherit - stdIn
            
            r1 := DllCall("CreatePipe","Ptr*",hStdOutRd:=0,"Ptr*",hStdOutWr:=0,"Uint",0,"Uint",0) ; get handle - stdOut (R/W)
            r2 := DllCall("SetHandleInformation","Ptr",hStdOutWr,"Uint",1,"Uint",1)            ; set flags inherit - stdOut
            
            If (InStr(mode,"x")) {
                r1 := DllCall("CreatePipe","Ptr*",hStdErrRd,"Ptr*",hStdErrWr,"Uint",0,"Uint",0) ; stdErr pipe on mode "x"
                r2 := DllCall("SetHandleInformation","Ptr",hStdErrWr,"Uint",1,"Uint",1)
            }
            
            this.hStdIn := hStdInWr, this.hStdOut := hStdOutRd, this.hStdErr := InStr(mode,"x") ? hStdErrRd : hStdOutRd
        }
        
        VarSetCapacity(pi, (p=4)?16:24, 0)          ; PROCESS_INFORMATION structure
        
        VarSetCapacity(si,siSize:=(p=4)?68:104,0)   ; STARTUPINFO Structure
        NumPut(siSize, si, 0, "UInt")               ; cb > structure size
        NumPut((!m ? 0x100 : 0x0) | 0x1, si, (p=4)?44:60, "UInt") ; dwFlags = 0x100 STARTF_USESTDHANDLES || 0x1 = check wShowWindow member below
        NumPut(showWindow ? 0x1 : 0x0, si, (p=4)?48:64, "UShort") ; wShowWindow / 0x1 = show
        
        If (!m) {
            NumPut(hStdInRd , si, (p=4)?56:80, "Ptr")    ; stdIn handle
            NumPut(hStdOutWr, si, (p=4)?60:88, "Ptr")    ; stdOut handle
            NumPut(InStr(mode,"x") ? hStdErrWr : hStdOutWr, si, (p=4)?64:96, "Ptr")    ; stdErr handle (only on mode "x", otherwise use stdout handle)
        }
        
        s := "^((.*)?adb(.exe)?([ ].*)?[ ]shell)$"
        If (r := RegExMatch(this.cmdProg,s))
            this.shell := "android"
        
        r := DllCall("CreateProcess"
            , "Uint", 0                    ; application name
            , "Ptr", &bFirstCmd            ; command line str
            , "Uint", 0                    ; process attributes
            , "Uint", 0                    ; thread attributes
            , "Int", (!m) ? true : false   ; inherit handles - true if STARTF_USESTDHANDLES (0x100) used in SI struct
            , "Uint", 0x10                 ; CMD is a console, no need for 0x10 (CREATE_NEW_CONSOLE), but doesn't hurt anything
            , "Uint", 0                    ; environment
            , "Ptr", &bWorkingDir          ; working Directory pointer
            , "Ptr", &si                   ; startup info structure - contains stdIn/Out handles
            , "Ptr", &pi)                  ; process info sttructure - contains proc/thread handles/IDs
        
        if (r) {
            pID := NumGet(pi, A_PtrSize*2, "uint"), tID := NumGet(pi, A_PtrSize * 2+4, "UInt")  ; get Process ID and Thread ID
            hProc := NumGet(pi,0,"UPtr"), hThread := NumGet(pi,A_PtrSize,"UPtr")                ; get Process handle and Thread handle
            this.pID := pID, this.tID := tID, this.hProc := hProc, this.hThread := hThread      ; save ID's and handles to "this"
            
            while (result := !DllCall("AttachConsole", "uint", pID) And this.ProcessExist(this.pID))    ; retry attach console until success
                Sleep, 10                                                                               ; if PID exists - cmd may have returned already
            
            If (InStr(mode,"m")) {                                                              ; mode "m" special cases...
                hStdIn  := DllCall("GetStdHandle", "Int", -10, "ptr"), this.hStdIn := hStdIn    ; get StdIn to send input
                hStdOut := DllCall("GetStdHandle", "Int", -11, "ptr"), this.hStdOut := hStdOut  ; get StdOut of the Console (not the process)
            } Else {
                r1 := DllCall("CloseHandle","Ptr",hStdOutWr), r2 := DllCall("CloseHandle","Ptr",hStdInRd) ; handles not needed, inherited by the process
                this.fStdOut := FileOpen(this.hStdOut, "h", this.codepage)  ; open StdOut stream object
            }
            
            If (InStr(mode,"x") And !m) { ; not going to mess with StdErr from console (mode m) yet, it's easier from the process
                DllCall("CloseHandle","Ptr",hStdErrWr)
                this.fStdErr := FileOpen(this.hStdErr, "h", this.codepage)
            }
            
            If (this.shell = "android" And !m) ; specific CLI shell fixes
                this.uWrite(this.checkShell())
            
            stream := this.stream, this.wait() ; wait for buffer to have data, default = 300 ms
            If (InStr(mode,"w"))
                this.wGet()                    ; (wGet) wait mode
            Else If (InStr(mode,"s") Or m)
                SetTimer, % stream, %delay%    ; data collection timer / default loop delay = 10 ms
        } Else {
            this.pid := 0, this.tid := 0, this.hProc := 0, this.hThread := 0
            this.stdout .= (this.stdout) ? "`r`nINVALID COMMAND" : "INVALID COMMAND"
            this.close()
            MsgBox % "Last Error: " A_LastError
        }
        If (this.cmdCmd And InStr(this.cmdSwitches,"/C") And !this.cmdProg) ; check if cmd /C with no params sent
            this.stdout .= (this.stdout) ? "`r`nNo command sent?" : "No command sent?"
    }
    ProcessExist(pid) {
        result := 0
        Process, Exist, %pid%
        result := ErrorLevel ? ErrorLevel : result
        return result
    }
    ProcessClose(pid) {
        result := 0
        Process, Close, %pid%
        result := ErrorLevel ? ErrorLevel : result
        return result
    }
    close() { ; closes handles and may/may not kill process instance
        stream := this.stream
        SetTimer, % stream, Off     ; disable streaming timer
        
        this.CtrlBreak()            ; send CTRL+Break to interrupt process if busy
        DllCall("FreeConsole")      ; detach console from script
        If !InStr(this.mode,"m")
            this.fStdOut.Close()    ; close fileObj stdout handle
        
        DllCall("CloseHandle","Ptr",this.hStdIn), DllCall("CloseHandle","Ptr",this.hStdOut)     ; close stdIn/stdOut handle
        DllCall("CloseHandle","Ptr",this.hProc),  DllCall("CloseHandle","Ptr",this.hThread)     ; close process/thread handle
        
        If (InStr(this.mode,"x"))
            this.fStdErr.Close(), DllCall("CloseHandle","Ptr",this.hStdErr)     ; close stdErr handles
        
        InStr(this.mode,"m") ? this.ProcessClose(this.pID) : ""                 ; close process if mode "m"
    }
    wait() {
        mode := this.mode, delay := this.delay, waitTimeout := this.waitTimeout, ticks := A_TickCount
        Loop {                                              ; wait for Stdout buffer to have content
            Sleep, %delay% ; default delay = 10 ms
            SoEof := this.fStdOut.AtEOF, SeEof := this.fStdErr.AtEOF, exist := this.ProcessExist(this.pID), timer := A_TickCount - ticks
            If (!SoEof Or !exist) Or (InStr(mode,"x") And !SeEof) Or (timer >= waitTimeout)
                Break
        }
    }
    wGet() { ; wait-Get - pauses script until process exists AND buffer is empty
        ID := this.ID, delay := this.delay, mode := this.mode, cmdTimeout := this.cmdTimeout, ticks := A_TickCount
        StdOutCallback := this.StdOutCallback, StdErrCallback := this.StdErrCallback
        
        Loop {
            Sleep, %delay%                                    ; reduce CPU usage (default delay = 10ms)
            buffer := Trim(this.fStdOut.read()," `r`n")       ; check buffer
            If (buffer) {
                If (InStr(mode,"r")) ; remove prompt
                    (lastLine := this.getPrompt(buffer,true)) ? buffer := RegExReplace(buffer,"\Q" lastLine "\E$","") : ""
                InStr(mode,"o") And IsFunc(StdOutCallback) ? %StdOutCallback%(buffer,ID,this) : this.stdout .= buffer ; StdOut Callback
            }
            
            If (InStr(mode,"x")) {  ; check stdErr
                stdErr := Trim(this.fStdErr.read()," `r`n")
                If (stdErr)
                    (InStr(mode,"e") And IsFunc(StdErrCallback)) ? %StdErrCallback%(stdErr,ID,this) : this.stdErr .= stdErr ; StdErr callback
            }
            
            If (!this.ProcessExist(this.pID) And this.fStdOut.AtEOF) ; process exits AND buffer is empty
                Break
            Else If (this.fStdOut.AtEOF And A_TickCount - ticks >= cmdTimeout) And (cmdTimeout > 0) ; check timeout if enabled
                Break
        }
        this.close()
    }
    sGet() { ; stream-Get (timer) - collects until process exits AND buffer is empty
        ID := this.ID, mode := this.mode, m := InStr(mode,"m") ? 1 : 0, batchCmd := Trim(this.batchCmd," `r`n`t"), prompt := ""
        StdOutCallback := this.StdOutCallback, StdErrCallback := this.StdErrCallback, stream := this.stream ; stream (timer)
        PromptCallback := this.PromptCallback, QuitCallback := this.QuitCallback
        pid := this.pid, hStdOut := this.hStdOut, mData := 0
        
        buffer := (!m) ? this.read() : this.mGet() ; check StdOut buffer
        
        If (InStr(mode,"x")) { ; StdErr in separate stream
            stdErr := this.fStdErr.read()
            If (stdErr) {
                (InStr(mode,"e") And IsFunc(StdErrCallback)) ? %StdErrCallback%(stdErr,ID,this) : "" ; StdErr callback
                this.stderr .= stdErr "`r`n`r`n"
            }
        }
        
        fullEOF := (!m) ? this.fStdOut.AtEOF : 1 ; check EOF, in mode "m" this is always 1 (because StdOut is grid, not a stream)
        if (InStr(mode,"x"))
            (this.fStdOut.AtEOF And this.fStdErr.AtEOF) ? fullEOF := true : fullEOF := false
        
        If (buffer) { ; buffer data automatically Trim()'s CRLF for better control
            buffer := Trim(buffer," `r`n")
            If (!m) Or (m And this.stdoutRaw != buffer) { ; normal collection - when there's a buffer
                prompt := "", this.stdoutRaw := buffer
                InStr(mode,"f") ? (buffer := this.filterCtlCodes(buffer)) : "" ; remove control codes (SSH, older ADB)
                
                prompt := this.getPrompt(buffer,true), buffer := this.removePrompt(buffer,prompt) ; isolate prompt from buffer
                
                If (this.QuitString And RegExMatch(buffer,"\Q" this.QuitString "\E$") And IsFunc(QuitCallback)) {
                    this.stdout .= buffer
                    %QuitCallback%(this.QuitString,ID,this)
                    SetTimer, % stream, Off
                    this.close()
                    return
                }
                
                (prompt) ? (buffer .= "`r`n`r`n") : (buffer := "`r`n" buffer)
                (prompt And !InStr(mode,"r")) ? (buffer .= prompt) : "" ; re-insert prompt if no mode "r" is used
            
                If (InStr(mode,"o") And IsFunc(StdOutCallback) And Trim(buffer," `r`n"))
                    %StdOutCallback%((m ? Trim(buffer," `r`n") : buffer),ID,this) ; trigger StdOut callback
                this.stdout .= buffer                                             ; collect data in this.stdout
                
                (prompt And InStr(mode,"p") And IsFunc(PromptCallback)) ? %PromptCallback%(prompt,ID,this) : "" ; prompt displayed event callback
                
                If (prompt And fullEOF And batchCmd)            ; process should be idle when prompt appears
                    batchCmd ? this.write(batchCmd) : ""        ; write next command in batch, if any
            } 
        }
        
        If (!this.ProcessExist(this.pID) And fullEOF)   ; if process exits AND buffer is empty
            SetTimer, % stream, Off                     ; stop data collection timer
    }
    mGet() { ; capture console grid output (from console buffer - not StdOut stream from the process)
        otherStr := ""
        If (exist := this.ProcessExist(this.pID)) {
            VarSetCapacity(lpCharacter,this.conWidth * this.conHeight * 2,0)  ; console buffer size to collect
            VarSetCapacity(dwBufferCoord,4,0)                       ; top-left start point for collection
            
            result := DllCall("ReadConsoleOutputCharacter"
                             ,"UInt",this.hStdOut ; console buffer handle
                             ,"Ptr",&lpCharacter ; str buffer
                             ,"UInt",this.conWidth * this.conHeight ; define console dimensions
                             ,"uint",NumGet(dwBufferCoord,"UInt") ; start point >> 0,0
                             ,"UInt*",lpNumberOfCharsRead:=0,"Int")
            
            enc := StrLen(Chr(0xFFFF)) ? "UTF-16" : "UTF-8"
            chunk := StrGet(&lpCharacter,enc) ; , otherStr := ""
            
            curPos := 1
            While (curLine := SubStr(chunk,curPos,this.conWidth)) {
                otherStr .= Trim(curLine) "`r`n", curPos += this.conWidth
            }
            otherStr := Trim(otherStr,"`r`n")
        }
        
        return otherStr
    }
    write(sInput:="") {
        sInput := Trim(sInput,OmitChars:="`r`n")
        If (sInput = "")
            Return
        
        mode := this.mode, ID := this.ID, delay := this.delay, stream := this.stream, pid := this.pid
        cmdLines := this.shellCmdLines(sInput,firstCmd,batchCmd) ; ByRef firstCmd / ByRef batchCmd
        this.batchCmd := batchCmd, this.lastCmd := firstCmd, this.cmdHistory .= firstCmd "`r`n"
        
        androidRegEx := "^((.*[ ])?adb (-a |-d |-e |-s [a-zA-Z0-9]*|-t [0-9]+|-H |-P |-L [a-z0-9:_]*)?[ ]?shell)$"
        If (RegExMatch(firstCmd,androidRegEx)) ; check shell change on-the-fly for ADB
            this.shell := "android"
        Else If (RegExMatch(firstCmd,"[ ]*exit[ ]*")) ; change back to windows on EXIT command
            this.shell := "windows"
        
        If (InStr(mode,"m"))
            this.consoleSend(firstCmd) ; special method to send text to console
        Else
            f := FileOpen(this.hStdIn, "h", this.codepage), f.Write(firstCmd "`r`n"), f.close(), f := "" ; send cmd
        
        If (this.shell = "android" And !InStr(mode,"m")) ; check shell
            this.uWrite(this.checkShell()) ; ADB - appends missing prompt after data complete
    }
    uWrite(sInput:="") { ; INTERNAL, don't use - this prevents .write() from triggering itself
        sInput := Trim(sInput,OmitChars:="`r`n")
        If (sInput != "") {
            If (InStr(this.mode,"m")) {
                this.consoleSend(sInput)
            } Else
                f := FileOpen(this.hStdIn, "h", this.codepage), f.Write(sInput "`r`n"), f.close(), f := "" ; send cmd
        }
    }
    consoleSend(inText) { ; internal, do not use directly, use .write(str) instead
        inText .= "`r`n"
        VarSetCapacity(ir, 24, 0)       ; ir := new INPUT_RECORD
        NumPut(1, ir, 0, "UShort")      ; ir.EventType := KEY_EVENT
        NumPut(1, ir, 8, "UShort")      ; ir.KeyEvent.wRepeatCount := 1
        
        Loop, Parse, inText
        {
            NumPut(Asc(A_LoopField), ir, 14, "UShort")
            
            NumPut(true, ir, 4, "Int")  ; ir.KeyEvent.bKeyDown := true
            keydown := DllCall("WriteConsoleInput", "Ptr", this.hStdIn, "Ptr", &ir, "uint", 1, "uint*", 0)
            
            NumPut(false, ir, 4, "Int") ; ir.KeyEvent.bKeyDown := false
            keyup := DllCall("WriteConsoleInput", "Ptr", this.hStdIn, "Ptr", &ir, "uint", 1, "uint*", 0)
        }
    }
    read(chars:="") {
        if (this.fStdOut.AtEOF=0) {
            VarSetCapacity(rawCli,size := (!chars ? this.fStdOut.Length : chars), 0)
            this.fStdOut.RawRead(&rawCli,size)
            str := Trim(StrGet(&rawCli,size,this.codepage))
            
            return str
        }
    }
    ctrlBreak() {
        this.KeySequence("^{CtrlBreak}")
    }
    ctrlC() {
        this.KeySequence("^c")
    }
    KeySequence(sInput) {
        curSet := A_DetectHiddenWindows
        DetectHiddenWindows, On
        If (WinExist("ahk_pid " this.pid)) {
            stream := this.stream ; detach console first, or script may exit.
            DllCall("FreeConsole")
            SetTimer, % stream, Off
            
            ControlSend, , %sInput%, % "ahk_pid " this.pid
            
            result := this.ReattachConsole()
        }
        DetectHiddenWindows, %curSet%
    }
    ReattachConsole() {
        delay := this.delay, stream := this.stream
        If (this.ProcessExist(this.pID)) {
            result := DllCall("AttachConsole", "uint", this.pID) ; retry attach console until success
            
            If (InStr(this.mode,"m")) {
                hStdIn  := DllCall("GetStdHandle", "int", -10, "ptr"), this.hStdIn  := hStdIn
                hStdOut := DllCall("GetStdHandle", "int", -11, "ptr"), this.hStdOut := hStdOut
            }
            
            SetTimer, % stream, % this.delay
        }
    }
    kill() {    ; not as important now that ctrlBreak() works, but still handy
        DllCall("TerminateProcess","Ptr",this.hProc,"UInt",0)
        this.close()
    }
    getPrompt(str,chEnv:=false) { ; catching shell prompt
        result := "", this.shellMatch := ""
        If (!str)
            return ""
        
        winRegEx := "O)[\r\n]*([A-Z]\:\\[^/?<>:*|" Chr(34) "]*>)$" ; orig: "[\n]?([A-Z]\:\\[^/?<>:*|``]*>)$"
        netshRegEx := "O)[\r\n]*(netsh[ a-z0-9]*\>)$"
        telnetRegEx := "O)[\r\n]*(\QMicrosoft Telnet>\E)$"
        androidRegEx := "O)[\r\n]*([\d]*\|?[\-_a-z0-9]+\:[^\r\n]+ (\#|\$)[ ]?)$"
        sshRegEx := "O)[\r\n]*([a-z][a-z0-9_\-]+\@?[\w_\-\.]*\:[^`r`n]*?[\#\$][ `t]*)$"
        
        If (RegExMatch(str,netshRegEx,match)) {
            result := match.Count() ? match.Value(1) : ""
            If (chEnv)
                this.shell := "netsh", this.shellMatch := match.Value(1)
        } Else If (RegExMatch(str,telnetRegEx,match)) {
            result := match.Count() ? match.Value(1) : ""
            If (chEnv)
                this.shell := "telnet"
        } Else If (RegExMatch(str,winRegEx,match)) {
            result := match.Count() ? match.Value(1) : ""
            If (chEnv)
                this.shell := "windows", this.shellMatch := match.Value(1)
        } Else If (RegExMatch(str,androidRegEx,match)) {
            result := match.Count() ? match.Value(1) : ""
            If (chEnv)
                this.shell := "android", this.shellMatch := match.Value(1)
        } Else If (RegExMatch(str,sshRegEx,match)) {
            result := match.Count() ? match.Value(1) : ""
            If (chEnv)
                this.shell := "ssh", this.shellMatch := match.Value(1)
        }
        
        return result
    }
    GetLastLine(sInput:="") { ; get last line from any data chunk
        sInput := sInput, lastLine := ""
        arr := StrSplit(sInput,"`n","`r")
        lastLine := arr[arr.Length()], arr := ""
        return lastLine
    }
    removePrompt(buffer,lastLine) {
        If (lastLine = "")
            return buffer
        Else {
            buffer := Trim(buffer,"`r`n ")
            nextLine := this.GetLastLine(buffer)
            While (nextLine = lastLine) {
                buffer := RegExReplace(buffer,"(\r\n|\r|\n)?\Q" lastLine "\E$","")
                nextLine := this.GetLastLine(buffer)
            }
            
            return Trim(buffer," `r`n")
        }
    }
    checkShell() {
        If (this.shell = "android")
            return "echo $HOSTNAME:$PWD ${PS1: -2}"
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
        return this.fStdOut.AtEOF
    }
    Length() {
        return this.fStdOut.Length
    }
    filterCtlCodes(buffer) {
        buffer := RegExReplace(buffer,"\x1B\[\d+\;\d+H","`r`n")
        buffer := RegExReplace(buffer,"`r`n`n","`r`n")
        
        r1 := "\x1B\[(m|J|K|X|L|M|P|\@|b|A|B|C|D|g|I|Z|k|e|a|j|E|F|G|\x60|d|H|f|s|u|r|S|T|c)"
        r2 := "\x1B\[\d+(m|J|K|X|L|M|P|\@|b|A|B|C|D|g|I|Z|k|e|a|j|E|F|G|\x60|d|H|f|r|S|T|c|n|t)"
        r3 := "\x1B(D|E|M|H|7|8|c)"
        r4 := "\x1B\((0|B)"
        r5 := "\x1B\[\??[\d]+\+?(h|l)|\x1B\[\!p"
        r6 := "\x1B\[\d+\;\d+(m|r|f)"
        r7 := "\x1B\[\?5(W|\;\d+W)"
        r8 := "\x1B\]0\;[\w_\-\.\@ \:\~]+?\x07"
        
        allR := r1 "|" r2 "|" r3 "|" r4 "|" r5 "|" r6 "|" r7 "|" r8
        buffer := RegExReplace(buffer,allR,"")
        
        buffer := StrReplace(buffer,"`r","")
        buffer := StrReplace(buffer,"`n","`r`n")
        return buffer
    }
}
