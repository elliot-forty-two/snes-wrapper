
#include <File.au3>
#include 'lib/GetOpt.au3'
#include 'functions.au3'
#include 'wrapper.au3'

If @ScriptName == 'sneswrapper.au3' Or @ScriptName == 'sneswrapper.exe' Then
   ConsoleWrite("SNES Wrapper - SNES VC for Old 3DS" & @CRLF & @CRLF)
   _ParseOpts()

   $optFolder = _PathFull($optFolder)
   If Not FileExists($optFolder) Then
	  _Error('ERROR: Folder not found: ' & $optFolder & @CRLF)
	  Exit 1
   EndIf
   ConsoleWrite('Using folder: ' & $optFolder & @CRLF)

   If $optUpdate Then
	  ConsoleWrite('Updating CIAs' & @CRLF)
	  $cias = _FileListToArray(_GetCiaDir(), '*.cia', $FLTA_FILES)
	  If @error == 0 Then
		 For $c = 1 To $cias[0]
			$cia = $cias[$c]
			ConsoleWrite($c & " of " & $cias[0] & ": " & $cia & @CRLF)
			UpdateCIA($cia)
		 Next
	  EndIf
   Else
	  $titles = _FileListToArray(_GetInput(), '*', $FLTA_FOLDERS)
	  If @error == 0 Then
		 For $t = 1 To $titles[0]
			$title = $titles[$t]
			ConsoleWrite($t & " of " & $titles[0] & ": " & $title & @CRLF)
			ProcessTitle($title)
		 Next
	  EndIf
   EndIf
EndIf

Func _ParseOpts()
   Local $sMsg
   Local $sOpt, $sOper
   Local $aOpts[5][3] = [ _
	  ['-c', '--clean', True], _
	  ['-u', '--update', True], _
	  ['-b', '--blarg', True], _
	  ['-v', '--verbose', True], _
	  ['-h', '--help', True] _
   ]
   _GetOpt_Set($aOpts)
   If 0 < $GetOpt_Opts[0] Then
	  While 1
		 $sOpt = _GetOpt('cuvbh')
		 If Not $sOpt Then ExitLoop
		 Switch $sOpt
		 Case '?'
			ConsoleWrite('Unknown option ' & $GetOpt_Opt & @CRLF & @CRLF)
			_Help()
		 Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
		 Case 'c'
			$optClean = $GetOpt_Arg
		 Case 'u'
			$optUpdate = $GetOpt_Arg
		 Case 'v'
			$optVerbose = $GetOpt_Arg
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
   ConsoleWrite('Usage: ' & @ScriptName & ' [-h] [-c|-u] [-b] [<folder>]' & @CRLF)
   ConsoleWrite(@TAB & '-h --help' & @TAB & 'Show this help message' & @CRLF)
   ConsoleWrite(@TAB & '-c --clean' & @TAB & 'Recreate output' & @CRLF)
   ConsoleWrite(@TAB & '-u --update' & @TAB & 'Update existing CIAs with new emulator' & @CRLF)
   ConsoleWrite(@TAB & '-b --blarg' & @TAB & 'Inject blargSNES instead of snes9x' & @CRLF)
   ConsoleWrite(@TAB & '<folder>' & @TAB & 'Set the working folder where "input" folder resides' & @CRLF)
   Exit
EndFunc
