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
;   Usage:   var := CliData("your_command here")
;
;       Using this library, this function is the easiest way to "just run a command and collect the data".
;       The commands passed to CliData() must be single line commands.  You can concatenate commands.
;       For best usage, make sure that the command you pass to CliData() is intended to return to a
;       windows prompt.  Otherwise you should use the cli() class below.
;
; ========================================================================================================
;   cli_obj := cli(sCmd:="", options:="", env:="cmd", params:="/Q /K")
; ========================================================================================================
;   Parameters:
;
;       sCmd        (required)
;
;           Single-line command or multi-line batch command.  Different modes will provide different
;           functionality.  See "Options" below.
;
;       options    (optional)
;           Zero or more of the options below, separated by a pipe (|):
;
;       env
;           Specify the environment.  The default environment is "cmd".  Other possibilities include:
;           > "powershell"
;           > "ansicon" --> Use your own CLi shell, like ANSICON.
;           > "adb" --> read more below
;
;           This can be any EXE that loads a command line environment that allows redirecting StdIn,
;           StdOut, and/or StdErr.  The PATH environment var will be checked to find the full path to the
;           EXE.  If the environment you want to use is not in PATH, then specify the full path in this
;           parameter.
;
;           NOTE: If you specify "powershell" for env param, the default "params" are blank, not "/Q /K".
;
;           NOTE about Android Debug Bridge (ADB):
;           
;               When running ADB commands like so:
;               
;                   adb shell ls -la
;
;               ... these types of commands run and immediately exit the adb shell.  Because of this,
;               these types of commands are still treated as windows commands.  If you check CLIobj.shell
;               property after running one of these commands, then you will see it still returns "windows".
;               The reason for this is due to the fact that the windows prompt is returned after the
;               command exits.  In this case, you don't usually want to specify "adb" as the environment,
;               simply because these types of commands are usually one line anyway.
;
;               If you need to do something more elaborate than "adb shell [command]", or if you wish to
;               start an interactive (or pseudo-interactive) session in ADB, then this is the appropriate
;               context to use "adb" as the environment.  In this case your first command in the batch
;               must be any variant of:
;
;                   adb [switches] shell
;
;               This first command in your batch will be used to load the shell environment and is
;               technically not part of your batch.
;
;               You can issue a batch of commands (separated by "`r`n") starting with the above "adb shell"
;               example, or you can simply issue the above example as your only command to start a fully
;               interactive session.
;
;               In case you are wondering, "adb logcat" is still treated as a windows command.
;
;       params
;           The default param is "/Q /K" to set ECHO OFF.  The /Q prevents your commands from displaying in
;           the CLI session.  Note that, CliObj.lastCmd contains your last command so you can reconstruct a
;           normal-looking CLI session if you desire.  The /K prevents the typical Microsoft logo from
;           appearing in the CLI session.  If you want text this logo to appear, then specify a value for
;           params that does not include /K.
;
;           CMD and POWERSHELL environments are loaded in such a way that /K is technically not necessary,
;           because these environments are always loaded as "interactive", even when using the CliData()
;           wrapper function.  The "/K" parameter is included to simplify the usage of this class, since
;           in most cases, you don't want to see the following in your output data:
;
;               Microsoft Windows [Version 10.0.19042.1052]
;               (c) Microsoft Corporation. All rights reserved.
;
;           Check the help docs for your CLI shell to know what the options are and how to use them.
;
;           NOTE: If you specify "powershell" for env param, the default "params" are blank, not "/Q /K".
; ========================================================================================================
; Options
; ========================================================================================================
;
;   ID:MyID
;       User defined string to identify CLI sessions.  This is used to identify a CLI instance within
;       callback functions.  If you manage multiple CLI sessions simultaneously you may want to use this
;       option to tell which session is which within your callback functions.
;
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   Modes define how the CLI instance is launched and handled.
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;       The main purpose of this library is to stream CLI output, and/or to interact with the prompt.
;       It is suggested to use the CliData() wrapper function for collecting data from a single command.
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;       IMPORTANT NOTES ABOUT THIS LIBRARY:
;           Except when using the CliData() wrapper function, the user MUST call obj.Close() to
;           terminate the CLI session AFTER "properly exiting" your program.
;
;           "Properly exiting the program" means the CLI session is still active, but idle.  If you don't
;           properly exit the program you may see the following processes remaining in Task Manager:
;                1) cmd.exe
;                2) the program you ran on the command line
;                3) conhost.exe (you will see more than usual - I usually see 3 of these on my system)
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   mode:[modes]  -  Primary Modes
;
;       mode "m" (Monitoring mode) This allows the user to record text as actually seen on a typical
;           console.  Normally this must be used with the StdOutCallback().  Usage with PromptCallback()
;           can also be useful.  Mode "m" is used for capturing animations like incrementing percent, or
;           a progress bar.
;
;               For Example:
;
;                   (90%) [========>     ]
;
;           A typical console buffer consists of approx 80-120 COLS (columns) and several thousand rows.
;
;               Usage: m(width, height)
;               - width : number of columns (of characters)
;               - height: number of rows of text
;
;               Note: A smaller area captured performs better than capturing a larger area.  Be sure
;               to use at least 2 rows.  A single row will usually be generally unusable.  If you do not
;               specify height/width when using mode "m", then 100 COLS and 10 LINES are used by default.
;
;           The size of the console buffer is important to take into account.  The buffer size can affect
;           the display of the output you are trying to capture.  If you notice "graphical anomalies"
;           then try a wider buffer size, and/or more rows.
;
;           You can call mode "x" with mode "m", but there are a few instances when this is not beneficial.
;           Some commands may hang if StdErr is not piped to the console buffer.  In general, if you have
;           seemingly random or unexplained issues using mode "x" with mode "m", stop using mode "x" and
;           see if the issues continue.
;
;           WARNING:  Mode "m" has NOT been tested with PowerShell yet.
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   mode:[modes]  -  Secondary Modes
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;       *** Append these modes as needed to further modify/refine CLI behavior ***
;
;       mode "c" = Delay sCmd execution.  Execute with obj.RunCmd()  Optionally set more options before
;           execution by specifying:    CLIobj.option := value
;
;           This is quite useful.  You can attach an array as a property containing a list of commands.
;           In this case you would use the prompt callback event as the trigger to check the array and
;           execute commands.
;
;           You can also eaisly make use of a progress bar during your session.  Check the AutoHotkey v2
;           forums for the Progress2.
;
;           There are many ways you can construct your CLI environment.  Remember that the CLI object is
;           passed as a parameter in all callback functions, so you can attach anything you like.  This
;           allows the coder to reduce the number of global variables needed for complex operations.
;
;       mode "x" = Extract StdErr in a separate pipe for each command.  The full StdErr stream for the
;           session is still stored in:  CLIobj.stderr
;
;           This is best used with PromptCallback(). Generally, you should clear cli.stdout and cli.stderr
;           after each PromptCallback() cycle to keep the correlation between the command, stdout, and
;           stderr clear.
;
;       mode "f" = Filter control codes.  This mostly pertains to Linux environments such as SSH or
;           old ADB sessions.
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;   More Options    NOTE: All options are also properties that can be set prior to command execution
;                         when using Mode "c".
;   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;
;   AutoClean:1
;       This option attempts to automatically trim trailing spaces on lines of txt in stdout.  Depending
;       on the amount of text you capture, and how quickly, this may cost you an undesired performance
;       hit.  You may be better off analyzing the text you capture closely to determine the type of
;       treatment it should get.
;
;       AutoClean only happens on prompt events.  Note that when using mode "m" lines are automatically
;       cleaned in this manner, so using this option is usually unnecessary.
;
;       If you are concerned with returning CLI output that looks like a table, with columns of data, then
;       do NOT use this.  Your column alignment WILL be messed up.  You can manually auto-clean when
;       desired with the CliObj.clean_Lines() method (see below).
;
;   codepage:CP###
;       Codepage (UTF-8 = CP65001 / Windows Console = CP437 / etc...)
;
;   PromptCallback:Give_It_A_Name
;       Defines the PromptCallback function.  If the callback function exists, it will be called when the
;       CLI session encounters a recognized prompt.
;
;       Currently recognized prompts are:
;
;           Windows CMD
;           Windows Powershell
;           Android Debug Bridge (ADB)
;           netsh
;           SSH (particularly from plink, the CLI version of PuTTY)
;       
;       > Default callback: PromptCallback(prompt, ID, CLIobj)
;
;       If you check the "ready" property in the prompt callback on the first prompt, you will see:
;
;       PromptCallback(prompt, ID, c) {
;
;           MsgBox(CliObj.ready)   ; Returns 0 on the first prompt callback event, otherwise 1.
;
;       }
;
;       This signifies that the CLi session is "loaded", and also means the first command in your
;       batch is about to be sent.  Depending on how you use this library and the callbacks, you
;       may or may not need to pay attention to the "ready" property.
;
;       All instances of the prompt callback being triggered AFTER the first prompt will have the
;       "ready" property set to 1.
;
;       The Prompt Callback is the underlying mechanism that makes this library sane.  It is
;       important to be familiar with how this callback works if you are going to get the most out
;       of this library.
;
;       Example:
;
;           PromptCallback(prompt, ID, cliObj) {
;               If !(cliObj.ready)      ; Skip the first prompt.
;                   return              ; Again, you may or may not need this...
;
;               ... other stuff
;           }
;
;   QuitCallback:Give_It_A_Name
;       Defines the QuitCallback function.  If the callback function exists, it will be called when the
;       CLI session encounters the defined QuitString (see below).
;   
;       > Default callback: QuitCallback(quitString, ID, CLIobj)
;       > The QuitString option must be set in order to use the QuitCallback.
;
;   QuitString:Your_Quit_Msg_Here
;       If you define this option, and if the QuitCallback function exists, then the specified string
;       will be searched while the output is streaming.  If this string is found at the end of a StdOut
;       packet (usually right before a prompt event as a command finishes) then data collection will
;       halt and the QuitCallback will be triggered, then the process will be terminated.
;
;   showWindow:#
;       Specify 0 or 1.  Default = 0 to hide.  1 will show.
;       Normally the CLI window will always be blank, except in mode "m".  The CLI window exists so that
;       control signals (CTRL+C / CTRL+Break / etc.) can be sent to the window.  See the Methods section
;       below.  This is only provided as a convenience for curious coders, but usually isn't very useful.
;
;   StdOutCallback:Give_It_A_Name
;       Defines the stdOutCallback function name.  If the callback exists, it will fire on this event.
;
;       > Default callback: StdOutCallback(data, ID, CLIobj)
;
;   waitTimeout:###   (ms)
;       The waitTimeout is an internal correction.  There is a slight pause between starting a CLI
;       session and getting data in the buffer (usually the first prompt).  If this timeout value
;       elapses and there is no data in stdout, then you will see a message saying:
;
;           Primary environment failed to load: cmd                <-- assuming your environment is "cmd"
;       
;       Currently Android Debug Bridge (ADB), when specifying "adb" for the env parameter, is treated as
;       a secondary environment.  If it fails to load then you will see a message stating that the
;       "secondary" environment has failed to load.
;
;       The default delay to wait for the enviornment to load is 1000 milliseconds, but usually it doesn't
;       take that long to load.
;
;   width:#  /  height:#
;       Sets the number of columns/rows for the console to use.  This only affects mode "m".
;
;   workingDir:c:\myDir
;       Set working directory.  Defaults to A_ScriptDir.  Commands that generate files will put those
;       files in the working directory.  Also relative paths are normally relative to the working
;       directory.  Take care when specifying a working directory, especially when modifying files.
;
;   NOTE: Height and Width can also be set with mode "m" --> "mode:m(h,w)".  See above.
;
; ========================================================================================================
; CLI class Methods and properties
; ========================================================================================================
;   Methods:
; ========================================================================================================
;
;   CLIobj.clean_lines(sInput, sep := "`n")
;       Trims spaces at the end of each line.  When `n is specified for sep (the default) `r will be
;       omitted.  When `r is specified for sep, then `n will be omitted.  It is possible to get mixed
;       line endings in CLI output.  Running this method twice, once with `n as sep, and once with `r
;       as sep, will take care of trailing spaces on all lines when encountering mixed line-endings.
;
;       NOTE:  A line ending is commonly referred to as CR, LF, or CRLF.  In AutoHotkey:
;
;           CR = `r (character 13 - the CARRIAGE RETURN)
;           LF = `n (character 10 - the LINE FEED)
;
;       For native windows commands you will almost always get CRLF endings.  For linux commands ported
;       to windows, madness is likely to enuse.  It is not uncommon to get a mix of CR, LF, and CRLF
;       when using linux commands ported to windows.
;
;   CLIobj.close()
;       Closes all open handles and tries to end the session.  If you try this without "properly exiting"
;       your program, then your script may appear to hang or malfunciton.  If you need to force termination
;       of your program, then send a CTRL+C or CTRL+Break signal first.  Read more below.
;
;   CLIobj.GetLastLine(str)
;       Returns last line of "str".  This is useful in callback functions when reading stdout.
;
;   CLIobj.KeySequence("string")
;       Sends a key sequence, ie. CTRL+Key.  DO NOT use this like the .write() method because this method
;       is not accurate for sending commands.  Only use this to send control signals like CTRL+C or
;       CTRL+Break (or CTRL+D in ADB, which actually does the same as CTRL+C ;-).
;       
;       This is commonly used to "properly exit" a program that is still running, prior to calling
;       CliObj.close() and terminating the CLI session.  In this case you would normally pass "^c" (CTRL+C)
;       or "^{CtrlBreak}", but be sure you know how to use your program.  There could be a different
;       key combo to properly interrupt the program.
;
;   CLIobj.runCmd()
;       Runs the command specified in sCmd parameter.  This is meant to be used with mode "c" when
;       delayed execution is desired for specifying additional options, parameters, or properties.
;       When using Mode "c", you can also do something fancy, like attaching an array of commands as
;       a property to the CLi object, and then you can check that array in the callbacks during the
;       prompt events.
;
;   CLIobj.Wait(timeout := 1000, msg := "")
;       Use this when you 
;
; ========================================================================================================
;    Properties (useful with CLIobj in callback functions):
; ========================================================================================================
;
;   CLIobj.[option]
;       All options above are also properties that can be checked or set.
;
;   Cliobj.batchProgress
;       Contains the iteration count of completed commands.
;
;   Cliobj.batchCommands
;       Contains the total number of commands (lines) passed into the .write() method.
;
;   CLIobj.cmdHistory
;       This is a text list (delimited by `r`n) of commands executed so far during your CLI session. The
;       last command in the list is the same as the lastCmd property.
;
;   CLIobj.hProc, CLIobj.hThread
;       Get the handle to the process/thread of the CLI session.
;
;   CLIobj.lastCmd
;       This is the last command that was run during your CLI session.  When using the PromptCallback(),
;       the .stdout and .stderr properties contain output data as a result of the last command run.
;
;   CLIobj.pID, CLIobj.tID
;       Get the process/thread ID of the CLI session.
;
;   Cliobj.ready
;       This is set to FALSE until after the first prompt event has happened, then it is set to TRUE.
;       This is most useful for filtering out the first prmopt event when using the prompt callback
;       function.
;
;   Cliobj.shell
;       Returns the currently detected shell (so far as my regex can detect).  This is useful when
;       typing a command to load a shell within a shell, and trying to deal with certain quirks unique
;       to a specific shell environment.
;
;       Currently supported shell environments:
;           - Windows
;           - netsh
;           - ADB
;           - SSH
;
;   CLIobj.stderr
;       This is the full output of StdErr during the session.  You can check or clear this value.
;
;   CLIobj.stdout
;       This is the full output of StdOut during the session.  You can check or clear this value.
;
;   CLIobj.use_check_shell
;       This property is false by default.  Currently this property is only used with ADB, but will
;       be used for other envionments that I find exhibit the same behavior as ADB.  Keep in mind
;       some ADB environments DO return a prompt.  This class is set to auto-detect if the ADB
;       environment you are running returns a prompt or not, but this auto-detection only happens
;       when you create the CLIobj and specify "adb" as your enviornment:
;
;           Example:  CLIobj := cli(cmd, sOptions, "adb")
;
;               NOTE: ADB must be in the system/user PATH environment variable, or you must specify
;                     the full path to the EXE.
;
;       In the above example, you are basically setting up some form of an interactive ADB shell.
;       If you use the CliData() wrapper function for commands like "adb shell getprop", these will
;       return directly to the windows prompt, and are still considered to be the "cmd" or "powershell"
;       environment.
;
;       Please note that you MUST know before hand if your particular ADB environment will return a
;       prompt or not if you intend to run a batch script that enters and exits the ADB shell.  If your
;       ADB environment does not return a prompt, then specify   CLIobj.use_check_shell := true
;       to ensure your script has a better chance of functioning properly.  In general it is best
;       to treat an actual ADB shell environment as it's own separate entity/object.  Or to put it
;       another way, it is best to AVOID running a single CLI session that uses windows commands
;       and actually enters a live ADB shell session (with some variant of "adb shell") to also run an
;       interactive (or pseudo-interactive) ADB shell in the same CLI session.
;
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; The following options are included as a convenience for power users.  Use with caution.
; Most CLI functionality can be handled without using the below methods / properties directly.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;
;   CLIobj.write(sInput)
;       Write to StdIn and send commands.  CRLF (`r`n) is appended automatically.  This method will
;       automatically use the appropriate command whether in normal streaming mode, or mode "m".
;
;   CLIobj.fStdOut - file object (stream) - contains all methods and properties of an AHK File Object.
;       Note this member is NOT a file object when using mode "m" (it is only a handle).
;
;   CLIobj.fStdErr - same as CLIobj.fStdOut, but for StdErr (only when using mode "x").
;
; ========================================================================================================
; KNOWN ISSUES
; ========================================================================================================
;   * When typing an incomplete command in PowerShell (ie.  >> echo "test  <<) you will get a ">>" prompt
;     with the option to complete the command.  In a normal PowerShell window, you can complete the above
;     command by typing double quotes (") and get back to the prompt.
;
;       It should also be possible to press CTRL+C to abort the incomplete command.  This is also not
;     happening when trying to use CliObj.KeySequence("^c").
;
;     Both of these issues currently apply to PowerShell, or PowerShell through CMD (ie. "cmd /K
;     powershell").  I'm still trying to figure out what causes this.  Other than these issues, Powershell
;     still appears to function properly when commands don't spawn a ">>" prompt.
; ========================================================================================================

CliData(inCommand:="") { ; Single line commands ONLY!
    If (!inCommand)
        return ""
    Else {
        cli_session := cli(inCommand)  ; run command, prune prompt
        result := ""
        
        While !cli_session.batchProgress
            Sleep cli_session.delay
        
        result := cli_session.stdout                ; get the data
        cli_session.close(), cli_session := ""      ; clean up
        return Trim(result,"`r`n`t")                ; return result
    }
}

class cli {
    Static CtlKeyState := {CAPSLOCK:0x80, ENHANCED_KEY:0x100, LALT:0x2, LCTRL:0x8, NUMLOCK:0x20, RALT:0x1, RCTRL:0x4, SCROLLLOCK:0x40, SHIFT:0x10}
    
    StdOutCallback:="stdOutCallback", PromptCallback:="PromptCallback", QuitCallback:="QuitCallback", QuitString:=""
    delay:=10, waitTimeout:=1000, showWindow:=0, codepage:="CP0", workingDir:=A_WorkingDir, shell:="windows", ready:=false, run:=false
    ID:="", mode:="", hStdIn:=0, hStdOut:=0, hStdErr:=0, stdout:="", stdoutRaw:="", stderr:="", cmdHistory:="", conWidth:=100, conHeight:=10
    lastCmd:="", cmdCmd:="", cmdSwitches:="", cmdProg:="", useAltShell := "", reason:="", command:=""
    batchCmdLines:=0, batchProgress:=0, batchCmd:="", terminateBatch := false
    fStdErr:={AtEOF:1, Handle:0}, fStdOut:={AtEOF:1, Handle:0}, AutoClean := false
    
    androidRegEx := "i)^((.*[ ])?adb(?:\.exe)? (-a |-d |-e |-s [a-zA-Z0-9]+|-t [0-9]+|-H |-P |-L [a-z0-9:_])?[ ]?shell)$"
    use_check_shell := false
    prompt_helper := "generic_prompt"
    
    __New(sCmd, options:="", _env:="cmd", params:="/Q /K") {
        this._env := _env ; save originally passed env for shorthand comparisons
        (_env = "adb") ? _env := "cmd" : ""
        this.env := (!FileExist(_env)) ? this.check_exe(_env) : _env
        this.params := (_env = "powershell" && params="/Q /K") ? "" : params
        
        this.batchCmdLines := this.shellCmdLines(sCmd,&firstCmd,&batchCmd)        ; ByRef firstCmd / ByRef batchCmd ; isolate 1st line command
        this.sCmd := sCmd, q := Chr(34), optGrp := StrSplit(options,"|")        ; next load specified properties (options param)
        For i, curItem in optGrp
            optItem := SubStr(curItem, 1, (sep := InStr(curItem,":")) - 1)  ; do this with SubStr() otherwise setting WorkingDir won't work
          , this.%optItem% := SubStr(curItem, sep+1)                        ; write options to "this"
        this.batchCmd := sCmd
        this.stream := ObjBindMethod(this,"sGet") ; register function Obj for timer (stream)
        
        If (!InStr(this.mode,"c"))
            this.runCmd()
    }
    check_exe(sInput) {
        sInput := (!RegExMatch(sInput,"\.exe$")) ? sInput ".exe" : sInput
        path := EnvGet("PATH")
        Loop Parse path, ";"
            If FileExist(A_LoopField "\" sInput)
                return RegExReplace(A_LoopFIeld "\" sInput,"[\\]{2,}","\")
        return ""
    }
    __Delete() {
        this.close() ; close all handles / objects
    }
    runCmd() { ; old param --> sCmd:=""
        Static p := A_PtrSize
        this.run := true, this.m := !!InStr(this.mode,"m")
        
        ; If (sCmd)
            ; this.batchCmd := sCmd
        
        If (InStr(this.mode,"(") And InStr(this.mode,")") And this.m) { ; mode "m" !!
            s1 := InStr(this.mode,"("), e1 := InStr(this.mode,")"), mParam := SubStr(this.mode,s1+1,e1-s1-1), dParam := StrSplit(mParam,",")
            conWidth := dParam[1], conHeight := dParam[2], this.conWidth := conWidth, this.conHeight := conHeight
        }
        
        If (this.m) {
            hasK := false
            For i, p in StrSplit(this.params," ")
                If (hasK := (p = "/K"))
                    Break
            
            params_addon := (!hasK?" /K ":"") " MODE CON: COLS=" this.conWidth " LINES=" this.conHeight
            (this.params) ? this.params .= params_addon : this.params := Trim(params_addon)
        }
        
        ; implement this for PowerShell
        ; powershell -noexit -command "[console]::WindowWidth=100; [console]::WindowHeight=50; [console]::BufferWidth=[console]::WindowWidth"
        
        hStdInRd := 0, hStdInWr := 0, hStdOutRd := 0, hStdOutWr := 0, hStdErrRd := 0, hStdErrWr := 0 ; init handles
        
        r1 := DllCall("CreatePipe","Ptr*",&hStdInRd,"Ptr*",&hStdInWr,"Uint",0,"Uint",0)     ; get handle - stdIn (R/W)
        r2 := DllCall("SetHandleInformation","Ptr",hStdInRd,"Uint",1,"Uint",1)              ; set flags inherit - stdIn
        this.hStdIn := hStdInWr, this.hStdOut := 0
        
        If (!this.m) {
            r1 := DllCall("CreatePipe","Ptr*",&hStdOutRd,"Ptr*",&hStdOutWr,"Uint",0,"Uint",0) ; get handle - stdOut (R/W)
            r2 := DllCall("SetHandleInformation","Ptr",hStdOutWr,"Uint",1,"Uint",1)            ; set flags inherit - stdOut ;ZZZ
            this.hStdOut := hStdOutRd
        }
        
        If (InStr(this.mode,"x")) {
            r1 := DllCall("CreatePipe","Ptr*",&hStdErrRd,"Ptr*",&hStdErrWr,"Uint",0,"Uint",0) ; stdErr pipe on mode "x"
            r2 := DllCall("SetHandleInformation","Ptr",hStdErrWr,"Uint",1,"Uint",1)
        }
        this.hStdErr := InStr(this.mode,"x") ? hStdErrRd : hStdOutRd
        
        pi := Buffer((p=4)?16:24, 0)                               ; PROCESS_INFORMATION structure
        si := Buffer(siSize:=(p=4)?68:104,0)                       ; STARTUPINFO Structure
        NumPut("UInt", siSize, si, 0)                                   ; cb > structure size
        NumPut("UInt", 0x100|0x1, si, (p=4)?44:60)                      ; STARTF_USESTDHANDLES (0x100) | STARTF_USESHOWWINDOW (0x1)
        NumPut("UShort", this.showWindow ? 0x1 : 0x0, si, (p=4)?48:64)  ; wShowWindow / 0x1 = show
        
        NumPut("Ptr", hStdInRd , si, (p=4)?56:80)                       ; stdIn handle
        (!this.m) ? NumPut("Ptr", hStdOutWr, si, (p=4)?60:88) : ""      ; stdOut handle
        NumPut("Ptr", InStr(this.mode,"x") ? hStdErrWr : hStdOutWr, si, (p=4)?64:96)    ; stdErr handle (only on mode "x", otherwise use stdout handle)
        
        r := DllCall("CreateProcess"
            , "Str", this.env, "Str", this.params
            , "Uint", 0, "Uint", 0          ; process/thread attributes
            , "Int", true                   ; always inherit handles to keep StdIn secure
            , "Uint", 0x10                  ; 0x10 (CREATE_NEW_CONSOLE), 0x200 (CREATE_NEW_PROCESS_GROUP)
            , "Uint", 0                     ; environment
            , "Str", this.workingDir        ; working Directory pointer
            , "Ptr", si.ptr                 ; startup info structure - contains stdIn/Out handles
            , "Ptr", pi.ptr)                ; process info sttructure - contains proc/thread handles/IDs
        
        if (r) {
            this.pID := NumGet(pi, p * 2, "UInt"), this.tID := NumGet(pi, p * 2+4, "UInt")    ; get Process ID and Thread ID
            this.hProc := NumGet(pi,0,"UPtr"), this.hThread := NumGet(pi,p,"UPtr")            ; get Process handle and Thread handle
            stream := this.stream, delay := this.delay
            
            while (result := !DllCall("AttachConsole", "UInt", this.pID) And ProcessExist(this.pID))    ; retry attach console until success
                Sleep 10                                                                                ; if PID exists - cmd may have returned already
            
            r1 := DllCall("CloseHandle","Ptr",hStdInRd) ; handles not needed, inherited by the process
            If (!this.m) {
                r2 := DllCall("CloseHandle","Ptr",hStdOutWr)
                this.fStdOut := FileOpen(this.hStdOut, "h", this.codepage)  ; open StdOut stream object
            } Else
                hStdOut := DllCall("GetStdHandle", "Int", -11, "ptr"), this.hStdOut := hStdOut
            
            If (InStr(this.mode,"x")) {
                DllCall("CloseHandle","Ptr",hStdErrWr)
                this.fStdErr := FileOpen(this.hStdErr, "h", this.codepage)
            }
            
            this._wait() ; initial wait for cmd or powershell environment
            If this.m {
                SetTimer stream, delay
                return
            }
            
            ; dbg("   INIT: waiting for first prompt")
            
            stdout := ""
            While !(prompt := this.getPrompt(stdout)) { ; actually wit for the initial prompt (usually cmd or powershell)
                Sleep this.delay
                If (_out := this.filterCtlCodes(this.fStdOut.Read()))
                    stdout .= _out
            }
            
            If !prompt {
                msgbox "Primary environment failed to load: " this.env
                return
            }
            
            ; dbg("    INIT: Primary env loaded...")
            
            this.shellCmdLines(this.sCmd,&firstCmd,&batchCmd)
            
            If (this._env = "adb") { ; A fairly large, but necessary, concession for ADB environment.
                stdout := prompt := "" ; start with fresh stdout and prompt
                (!InStr(this.mode,"f")) ? this.mode .= "f" : "" ; automatically add mode "f" for ADB
                this.batchCmd := batchCmd
                this.shell := "android"
                
                f := FileOpen(this.hStdIn, "h", this.codepage)  ; run first adb command: usually a variant of "adb shell"
                f.Write(firstCmd "`r`n"), f.close(), f := ""    ; the main purpose is to enter the interactive adb shell
                f := FileOpen(this.hStdIn, "h", this.codepage), f.Write("echo 'no prompt'" "`r`n"), f.close(), f := ""
                
                While !InStr(stdout,"no prompt") {
                    If (_out := this.filterCtlCodes(this.fStdOut.Read()))
                        stdout .= _out
                      , prompt := this.getPrompt(stdout)
                      ; , dbg("   INIT: data!:  " _out)
                    Sleep this.delay
                }
                
                ; dbg("   INIT: Checking sub-shell prompt 1...")
                
                If (!prompt) {
                    this.use_check_shell := true
                    
                    f := FileOpen(this.hStdIn, "h", this.codepage), f.Write("getprop ro.hardware" "`r`n"), f.close(), f := ""
                    this._wait()
                    this.prompt_helper := Trim(this.fStdOut.Read()," `r`n")
                    
                    f := FileOpen(this.hStdIn, "h", this.codepage), f.Write(this.checkShell() "`r`n"), f.close(), f := ""
                    wait := this._wait()
                    stdout := (stdout?"`r`n":"") this.filterCtlCodes(this.fStdOut.Read())
                    prompt := this.getPrompt(stdout)
                    
                    ; dbg("   INIT: Checking sub-shell prompt 2...")
                    
                    If !prompt {
                        Msgbox "Secondary environment failed to load.`r`n`r`n"
                             . "current stdout:`r`n`r`n"
                             . stdout "`r`n`r`n"
                             . "wait: " wait "`r`n`r`n"
                             . "firstCmd: " firstCmd
                        
                        this.close() ; abort everything
                        return
                    }
                }
            }
            
            ; dbg("    INIT: check shell: " this.use_check_shell)
            
            stdout := this.fStdOut.Read() ; empty the buffer before continuing
            SetTimer stream, delay         ; data collection timer / default loop delay = 10 ms
            this.promptEvent(prompt)
        } Else {
            this.pid := 0, this.tid := 0, this.hProc := 0, this.hThread := 0
            this.stdout .= (this.stdout) ? "`r`nINVALID COMMAND" : "INVALID COMMAND"
            this.close()
            MsgBox "Last Error: " A_LastError
        }
    }
    close() { ; closes handles and may/may not kill process instance
        stream := this.stream
        SetTimer stream, 0                  ; disable streaming timer
        
        (ProcessClose(this.pID)) ? this.write("exit") : "" ; send "exit" if process still exists
        
        If (!this.m And this.fStdOut.Handle)
            this.fStdOut.Close()            ; close fileObj stdout handle
        
        DllCall("CloseHandle","Ptr",this.hStdIn), DllCall("CloseHandle","Ptr",this.hStdOut)     ; close stdIn/stdOut handle
        DllCall("CloseHandle","Ptr",this.hProc),  DllCall("CloseHandle","Ptr",this.hThread)     ; close process/thread handle
        
        If (InStr(this.mode,"x") And this.fStdErr.Handle)
            this.fStdErr.Close(), DllCall("CloseHandle","Ptr",this.hStdErr)     ; close stdErr handles
        
        DllCall("FreeConsole")                  ; detach console from script
        (this.m) ? ProcessClose(this.pID) : ""  ; close process if mode "m"
        
        this.pid := 0, this.tid := 0, this.hProc := 0, this.hThread := 0
    }
    _wait() {
        mode := this.mode, delay := this.delay, waitTimeout := this.waitTimeout, ticks := A_TickCount
        Loop {          ; wait for Stdout buffer to have content
            Sleep delay ; default delay = 10 ms
            SoEof := this.fStdOut.AtEOF, SeEof := this.fStdErr.AtEOF, exist := ProcessExist(this.pID), timer := A_TickCount - ticks
            If (!SoEof Or !exist) Or (InStr(mode,"x") And !SeEof) Or (timer >= waitTimeout)
                Break
        }
        return timer
    }
    mGet() { ; capture console grid output (from console buffer - not StdOut stream from the process)
        Static enc := StrLen(Chr(0xFFFF)) ? "UTF-16" : "UTF-8"
        otherStr := "", curPos := 1
        If (exist := ProcessExist(this.pID)) {
            lpCharacter := Buffer(this.conWidth * this.conHeight * 2,0)  ; console buffer size to collect
            dwBufferCoord := Buffer(4,0)                                 ; top-left start point for collection
            
            result := DllCall("ReadConsoleOutputCharacter"
                             ,"UInt",this.hStdOut   ; console buffer handle
                             ,"Ptr",lpCharacter.ptr ; str buffer
                             ,"UInt",this.conWidth * this.conHeight ; define console dimensions
                             ,"uint",NumGet(dwBufferCoord,"UInt") ; start point >> 0,0
                             ,"UInt*",lpNumberOfCharsRead:=0,"Int")
            chunk := StrGet(lpCharacter,enc)
            
            While (curLine := SubStr(chunk,curPos,this.conWidth))
                otherStr .= RTrim(curLine) "`r`n", curPos += this.conWidth
        }
        
        return Trim(otherStr,"`r`n")
    }
    sGet() { ; stream-Get (timer) - collects until process exits AND buffer is empty
        batchCmd := Trim(this.batchCmd," `r`n`t"), prompt := "", stream := this.stream
        cbStdOut := false, cbQuit := false
        
        Try cbQuit := (Type(%this.QuitCallback%) != "String") ? %this.QuitCallback% : false
        Try cbStdOut := (Type(%this.StdOutCallback%) != "String") ? %this.StdOutCallback% : false
        
        buf := (!this.m) ? this.fStdOut.read() : this.mGet()    ; check StdOut buffer
        this.getStdErr()                                        ; check StdErr buffer (only applies on mode "x")
        
        fullEOF := (!this.m) ? this.fStdOut.AtEOF : 1 ; check EOF, in mode "m" this is always 1 (because StdOut is grid, not a stream)
        if (InStr(this.mode,"x"))
            (this.fStdOut.AtEOF And this.fStdErr.AtEOF) ? fullEOF := true : fullEOF := false
        
        If (buf) {
            If (!this.m) Or (this.m And this.stdoutRaw != buf) {                                    ; collect when buffer exists
                this.stdoutRaw := buf                                                               ; record last unmodified buffer
                InStr(this.mode,"f") ? (buf := this.filterCtlCodes(buf)) : ""                       ; remove control codes (SSH, older ADB)
                
                buf := RegExReplace(buf,"^\Q" this.lastCmd "\E[\r\n]*","")                          ; prune the command if it is there
                If (this.shell = "android") && (RegExReplace(buf,"[`r`n]","") = this.lastCmd)       ; semi-rare, but definitely happens
                    buf := ""
                
                prompt := this.getPrompt(buf,true)                                                  ; isolate prompt
                buf := this.removePrompt(buf,prompt)                                                ; remove prompt from buffer
                
                If (this.QuitString And RegExMatch(Trim(buf,"`r`n`t"),"\Q" this.QuitString "\E[\r\n]*$") And cbQuit) {
                    cbQuit(this.QuitString,this.ID,this) ; check for QuitString before prompt is added
                    this.close()
                    return
                }
                
                ; dbg("    buffer: " buf)
                
                this.stdout .= buf
                
                (cbStdOut) ? cbStdOut(buf,this.ID,this) : ""        ; trigger StdOut callback
                (prompt) ? this.promptEvent(prompt) : ""            ; trigger prompt callback
            }
        }
        
        If (!ProcessExist(this.pID) And fullEOF) {  ; if process exits AND buffer is empty
            this.batchProgress += 1
            SetTimer stream, 0                      ; stop data collection timer
        }
    }
    clean_lines(sInput, sep:="`n") {
        result := ""
        omit := (sep = "`n") ? "`r" : "`n"
        
        Loop Parse sInput, sep, omit
            result .= ((A_Index>1)?"`r`n":"") RTrim(A_LoopField," `t")
        
        return result
    }
    getStdErr() {
        If (InStr(this.mode,"x") And !this.m) { ; StdErr in separate stream
            stdErr := RTrim(Trim(this.fStdErr.read(),"`r`n"))
            If (stdErr != "")
                (this.stdErr="") ? this.stderr := stderr : this.stderr .= "`r`n" stderr
        }
    }
    promptEvent(prompt) {
        prompt := StrReplace(StrReplace(prompt,"`r",""),"`n","")
        cbPrompt := false
        Try cbPrompt := (Type(%this.PromptCallback%) != "String") ? %this.PromptCallback% : false
        
        (this.ready) ? this.batchProgress += 1 : ""         ; increment batchProgress / when this is 1, the first command has been completed.
        
        If (this.AutoClean) {
            this.stdout := this.clean_lines(this.stdout)        ; sep by `n first, omit `r
            this.stdout := this.clean_lines(this.stdout, "`r")  ; sep by `r, omit `n (rare, but does happen)
        }                                                       ; ... sometimes you get `r line endings without `n
        
        ; dbg("prompt event1: " prompt " ===> ready: " this.ready " / batchProg: " this.batchProgress " / lastCmd: " this.lastCmd)
        
        (cbPrompt) ? cbPrompt(prompt,this.ID,this) : ""   ; trigger callback function
        
        ; dbg("prompt event: done`r`n" "prompt event commands: " this.batchCmd)
        
        (!this.ready) ? (this.ready := true) : ""           ; set ready after first prompt
        
        ; dbg("prompt event2: " prompt " ===> ready: " this.ready " / batchProg: " this.batchProgress " / lastCmd: " this.lastCmd)
        
        (this.batchCmd) ? this.write(this.batchCmd) : ""    ; write next command in batch, if any
        
        ; dbg("prompt event: ready: " this.ready " / cmd write complete`r`nbatchCmd: " this.batchCmd)
    }
    write(sInput:="") {
        If !this.run {
            Msgbox "The command has not been run yet.  You must call:`r`n`r`n     cliObj.runCmd()"
            return
        }
        
        sInput := Trim(sInput, "`r`n")
        If (sInput = "") Or this.terminateBatch {
            this.lastCmd := "", this.batchCmd := "", this.terminateBatch := false, this.batchProgress := 0, this.batchCmdLines := 0
            Return
        }
        
        cmdLines := this.shellCmdLines(sInput,&firstCmd,&batchCmd) ; ByRef firstCmd / ByRef batchCmd
        this.lastCmd := firstCmd, this.batchCmd := batchCmd, this.cmdHistory .= (this.cmdHistory?"`r`n":"") firstCmd ; this.firstCmd := firstCmd
        
        If (RegExMatch(firstCmd,this.androidRegEx)) ; check shell change on-the-fly for ADB
            this.shell := "android"
        
        ; dbg("   c.write(): " firstCmd " / shell: " this.shell)
        f := FileOpen(this.hStdIn, "h", this.codepage), f.Write(firstCmd "`r`n"), f.close(), f := "" ; send cmd
        
        If (!this.m And this.use_check_shell) ; check shell
            this.uWrite(this.checkShell()) ; ADB - appends missing prompt after data complete
    }
    uWrite(sInput:="") { ; INTERNAL, don't use - this prevents .write() from triggering itself
        sInput := Trim(sInput,"`r`n")
        If (sInput != "")
            f := FileOpen(this.hStdIn, "h", this.codepage), f.Write(sInput "`r`n"), f.close(), f := "" ; send cmd
    }
    KeySequence(sInput) {
        curSet := A_DetectHiddenWindows
        DetectHiddenWindows true
        If (WinExist("ahk_pid " this.pid)) {
            
            If (this.m)
                DllCall("CloseHandle","Ptr",this.hStdOut) ; close handle before free console on mode "m"
            
            DllCall("FreeConsole")
            SetTimer this.stream, 0
            ControlSend sInput,, "ahk_pid " this.pid

            result := this.ReattachConsole()
        }
        DetectHiddenWindows curSet
    }
    ReattachConsole() {
        If (ProcessExist(this.pID)) {
            result := DllCall("AttachConsole", "uint", this.pID)
            
            If (this.m)
                hStdOut := DllCall("GetStdHandle", "int", -11, "ptr"), this.hStdOut := hStdOut
            
            delay := this.delay, stream := this.stream
            SetTimer stream, delay
        }
    }
    getPrompt(str,chEnv:=false) { ; catching shell prompt
        result := "", this.shellMatch := ""
        If (!str)
            return ""
        
        Static inv_path := "\/\?\<\>\:\*\|\" Chr(34) "\r\n\``"              ; invalid path chars
        winRegEx     := "((?:\r\n)?(?:PS )?[A-Z]\:\\[^" inv_path "]*> *)$"  ; orig: "[\n]?([A-Z]\:\\[^/?<>:*|``]*>)$"
        netshRegEx   := "((?:\r\n)?netsh[ a-z0-9]*\>)$"
        androidRegEx := "m)^((?:[a-z][a-z0-9_\-]*\:)?(?:/.*?|~) (?:\#|\$)[ ]?)$"
        ; androidRegEx := "m)((?:(?:ADB_SHELL:)?\/[^\r\n]*|/.*?|~) (?:\#|\$))$"            ; has trailing `r`n due to manual ECHO cmd
                      ; "((?:\r\n)?[\d]*\|?[a-z0-9_\-]+\:[^\r\n]+ (\#|\$)[ ]?)\r\n$"
        sshRegEx     := "((?:\n)?[a-z][a-z0-9_\-]+\@?[\w_\-\.]*\:[^`r`n]*?[\#\$][ `t]*)$"     ; "user@PC:~/Dir/Path$ "
        ps_part      := "((?:\r\n)?>> *)$" ; PowerShell partial expression prompt
        
        If (this.shell = "windows" And RegExMatch(str,ps_part,&match)) {
            result := match.Count ? match[1] : ""
        } Else If (RegExMatch(str,netshRegEx,&match)) {
            result := match.Count ? match[1] : ""
            If (chEnv)
                this.shell := "netsh", this.shellMatch := match[1]
        } Else If (RegExMatch(str,winRegEx,&match)) {
            result := match.Count ? match[1] : ""
            If (chEnv)
                this.shell := "windows", this.shellMatch := match[1]
        } Else If (RegExMatch(str,androidRegEx,&match)) {
            result := match.Count ? match[1] : ""
            If (chEnv)
                this.shell := "android", this.shellMatch := match[1]
        } Else If (RegExMatch(str,sshRegEx,&match)) {
            result := match.Count ? match[1] : ""
            If (chEnv)
                this.shell := "ssh", this.shellMatch := match[1]
        }
        
        return result
    }
    GetLastLine(sInput:="") { ; get last line from any data chunk
        lastLine := ""
        Loop Parse RTrim(sInput,"`r`n"), "`n", "`r"
            lastLine := A_LoopField
        return lastLine
    }
    removePrompt(buf,prompt) {
        If (prompt = "")
            return buf
        Else {
            nextLine := this.GetLastLine(buf)
            While (Trim(nextLine,"`r`n") = Trim(prompt,"`r`n")) { ; below, "begin" captures any `r`n combo before prompt
                begin := ((RegExMatch(prompt,"^([\r\n]+)",&match)) ? StrReplace(StrReplace(match[1],"`r","\r"),"`n","\n") : "")
                buf := RegExReplace(buf, begin "\Q" Trim(prompt,"`r`n") "\E[ \r\n]*$","")
                nextLine := this.GetLastLine(buf)
            }
            
            return buf
        }
    }
    checkShell() {
        Static q := Chr(34)
        p := this.prompt_helper
        
        If (this.shell = "android") {
            If !InStr(this.mode,"x") {
                prompt := "echo " p ":$PWD $([ `whoami` == " q "root" q " ] && echo " q "#" q " || echo " q "$" q ") 1>&2"
                return prompt
            } Else {
                prompt := "echo " p ":$PWD $([ `whoami` == " q "root" q " ] && echo " q "#" q " || echo " q "$" q ")"
                return prompt
            }
        } Else
            return ""
    }
    shellCmdLines(str, &firstCmd, &batchCmd) {
        firstCmd := "", batchCmd := "", str := Trim(str," `t`r`n"), i := 0
        Loop Parse str, "`n", "`r"
        {
            If (A_LoopField != "")
                i++, ((A_Index = 1) ? (firstCmd := A_LoopField) : (batchCmd .= A_LoopField "`r`n"))
        }
        batchCmd := Trim(batchCmd," `r`n`t")
        return i
    }
    filterCtlCodes(buf) {
        buf := RegExReplace(buf,"\x1B\[\d+\;\d+H","`r`n")
        buf := RegExReplace(buf,"`r`n`n","`r`n")
        
        r1 := "\x1B\[(m|J|K|X|L|M|P|\@|b|A|B|C|D|g|I|Z|k|e|a|j|E|F|G|\x60|d|H|f|s|u|r|S|T|c)"
        r2 := "\x1B\[\d+(m|J|K|X|L|M|P|\@|b|A|B|C|D|g|I|Z|k|e|a|j|E|F|G|\x60|d|H|f|r|S|T|c|n|t)"
        r3 := "\x1B(D|E|M|H|7|8|c)"
        r4 := "\x1B\((0|B)"
        r5 := "\x1B\[\??[\d]+\+?(h|l)|\x1B\[\!p"
        r6 := "\x1B\[\d+\;\d+(m|r|f)"
        r7 := "\x1B\[\?5(W|\;\d+W)"
        r8 := "\x1B\]0\;[^\x07]+\x07"
        
        allR := r1 "|" r2 "|" r3 "|" r4 "|" r5 "|" r6 "|" r7 "|" r8
        buf := RegExReplace(buf,allR,"")
        
        buf := StrReplace(buf,"`r","")
        buf := StrReplace(buf,"`n","`r`n")
        return buf
    }
    Wait(timeout := 1000, msg := "") {
        ticks := A_TickCount, diff := 0
        While !this.fStdOut.AtEOF && (diff <= timeout) {
            diff := A_TickCount - ticks
            Sleep 10
        }
        
        If (diff>timeout) {
            msg ? Msgbox(msg) : ""
            this.Close()
            return 1
        }
        
        return 0
    }
}

; dbg(_in) {
    ; Loop Parse _in, "`n", "`r"
        ; OutputDebug "AHK: " A_LoopField
; }

; StdIn(close:=false) {
    ; Static f := FileOpen("*", "r")
    
    ; If (close) {
        ; f.Close()
        ; return
    ; }
    
    ; return (!f.AtEOF) ? f.Read() : ""
; }