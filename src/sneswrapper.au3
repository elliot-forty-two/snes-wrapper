
#include "lib/GetOpt.au3"
#include "functions.au3"
#include "wrapper.au3"

Global $optClear = False
Global $optEmulator = "snes9x_3ds.elf"
Global $optFolder = @WorkingDir

If @ScriptName == 'sneswrapper.au3' Or @ScriptName == 'sneswrapper.exe' Then
   ConsoleWrite("OldSNES -- SNES VC for Old 3DS users" & @CRLF)
   _ParseOpts()
   $titles = _FileListToArray('input', '*', $FLTA_FOLDERS)
   If $titles Then
	  For $t = 1 To $titles[0]
		 $title = $titles[$t]
		 ConsoleWrite($t & " of " & $titles[0] & ": " & $title & @CRLF)
		 ProcessTitle($title)
	  Next
   EndIf
EndIf

Func _ParseOpts()
   Local $sMsg
   Local $sOpt, $sOper
   Local $aOpts[3][3] = [ _
	  ['-c', '--clean', True], _
	  ['-b', '--blarg', True], _
	  ['-h', '--help', True] _
   ]
   _GetOpt_Set($aOpts)
   If 0 < $GetOpt_Opts[0] Then
	  While 1
		 $sOpt = _GetOpt('cbh')
		 If Not $sOpt Then ExitLoop
		 Switch $sOpt
		 Case '?'
			ConsoleWrite('Unknown option ' & $GetOpt_Opt & @CRLF)
			_Help()
		 Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
		 Case 'c'
			$optClear = $GetOpt_Arg
		 Case 'b'
			If $GetOpt_Arg Then
			   $optEmulator = "blargSnes.elf"
			EndIf
		 Case 'h'
			_Help()
		 EndSwitch
	  WEnd
   EndIf
   If 0 < $GetOpt_Opers[0] Then
	  While 1
		 $sOper = _GetOpt_Oper()
		 If Not $sOper Then ExitLoop
		 $optFolder = $sOper
	  WEnd
   EndIf
EndFunc

Func _Help()
   ConsoleWrite('Usage: sneswrapper.exe [-c] [-b] [-h] [folder]' & @CRLF)
   ConsoleWrite(@TAB & '-c --clear' & @TAB & 'Clear output to recreate' & @CRLF)
   ConsoleWrite(@TAB & '-b --blarg' & @TAB & 'Inject blargSNES instead of snes9x' & @CRLF)
   ConsoleWrite(@TAB & '-h --help' & @TAB & 'Show this help message' & @CRLF)
   Exit
EndFunc
