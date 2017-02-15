
#include <File.au3>
#include 'lib/GetOpt.au3'
#include 'functions.au3'
#include 'banner.au3'

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

Func ProcessTitle($title)
   ;; Read ROM info
   Local $short = _InfoGet($title, 'short')
   Local $long = _InfoGet($title, 'long')
   Local $author = _InfoGet($title, 'author')
   Local $serial = _InfoGet($title, 'serial')
   Local $id = _InfoGet($title, 'id')
   Local $release = _InfoGet($title, 'release')

   Local $file
   $files = _FileListToArray(_GetInput($title), '*.s?c', $FLTA_FILES)
   For $i = 1 To $files[0]
	  $ext = StringRight($files[$i], 3)
	  If $ext == 'smc' Or $ext == 'sfc' Then
		 $file = $files[$i]
	  EndIf
   Next
   If Not FileExists(_GetInput($title) & $file) Then
	  _Error('ERROR: Missing rom file. Make sure you have a rom file in ' & _GetInput($title))
	  SetError(-1)
	  Return
   EndIf

   Local $cleanCia = False

   If $optClean Or Not FileExists(_GetOutput($title) & 'icon.bin') Then
	  _LogProgress('Creating icon.bin ...')
	  _CreateIcon($title, $short, $long, $author)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
	  $cleanCia = True
   EndIf

   If $optClean Or Not FileExists(_GetOutput($title) & 'banner.bin') Then
	  _LogProgress('Creating banner.bin ...')
	  _GenerateBanner($title)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
	  $cleanCia = True
   EndIf

   If $optClean Or $cleanCia Or Not FileExists(_GetCiaDir() & $title & '.cia') Then
	  _LogProgress('Creating CIA ...')
	  DirCreate(_GetCiaDir())

	  _CreateRomfs($title, $long)

	  _RunWait('tools\makerom -f cia -target t -rsf "template\custom.rsf" ' _
		 & '-o "' & _GetCiaDir() & $title & '.cia" -exefslogo ' _
		 & '-icon "' & _GetOutput($title) & 'icon.bin" ' _
		 & '-banner "' & _GetOutput($title) & 'banner.bin" ' _
		 & '-elf "template\' & $optEmulator & '" ' _
		 & '-DAPP_TITLE="' & $long & '" ' _
		 & '-DAPP_PRODUCT_CODE="' & $serial & '" ' _
		 & '-DAPP_UNIQUE_ID="0x' & $id & '" ' _
		 & '-DAPP_ROMFS="' & _GetOutput($title) & 'romfs"')

	  FileDelete(_GetOutput($title) & 'romfs\*')
	  DirRemove(_GetOutput($title) & 'romfs')
   EndIf

   _LogProgress('Done')
EndFunc

Func _CreateRomfs($title, $long)
   DirCreate(_GetOutput($title) & "romfs")

   FileCopy(_GetInput($title) & "*.smc", _GetOutput($title) & "romfs\rom.smc")
   FileCopy(_GetInput($title) & "*.sfc", _GetOutput($title) & "romfs\rom.smc")

   ;; snes9x
   FileCopy(_GetInput($title) & "\*.cfg", _GetOutput($title) & "romfs\rom.cfg")
   ;; blargsnes
   FileCopy(_GetInput($title) & "\*.bmp", _GetOutput($title) & "romfs\blargSnesBorder.bmp")
   FileCopy(_GetInput($title) & "\*.ini", _GetOutput($title) & "romfs\blargSnes.ini")

   FileWrite(_GetOutput($title) & "romfs\rom.txt", $long)
EndFunc

Func _CreateIcon($title, $short, $long, $author)
   DirCreate(_GetOutput($title))

   Local $file = _FileExistsArr('icon.png|icon.jpg|icon.jpeg|banner.png|banner.jpg|banner.jpeg', _GetInput($title))
   If Not $file Then
	  _Error('ERROR: Icon image not found')
	  SetError(-1)
	  Return
   EndIf

   _RunWait('tools\convert "' & $file & '" -resize 40x40! "' & _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert template\icon.png "' & _GetOutput($title) & 'temp.png" -gravity center -composite "' & _GetOutput($title) & 'icon.png"')
   _RunWait('tools\bannertool makesmdh -s "' & $short & '" -l "' & $long & '" -p "' & $author & '" -i "' & _GetOutput($title) & 'icon.png" -o "' & _GetOutput($title) & 'icon.bin"')

   FileDelete(_GetOutput($title) & "temp.png")
EndFunc

Func UpdateCIA($cia)
   _LogProgress('Extracting NCCH ...')
   _RunWait('tools\ctrtool -x -t cia --contents ncch "' & $cia & '"', _GetCiaDir())
   $ncchs = _FileListToArray(_GetCiaDir(), 'ncch*.*', $FLTA_FILES)
   If @error == 0 Then
	  For $i = 1 To $ncchs[0]
		 $ncch = $ncchs[$i]
		 _LogProgress('Extracting exefs ' & $i & ' ...')
		 _RunWait('tools\ctrtool -x -t ncch --exefsdir exefs --romfsdir romfs "' & $ncch & '"', _GetCiaDir())
		 FileDelete(_GetCiaDir() & $ncch)
	  Next
   EndIf

   _LogProgress('Extracting info ...')
   _RunWait('tools\ciainfo "' & $cia & '"', _GetCiaDir())
   $arr = FileReadToArray(_GetCiaDir() & 'info.txt')
   FileDelete(_GetCiaDir() & 'info.txt')
   If UBound($arr) <> 5 Then
	  _Error('ERROR: CIA info returned wrong number of values')
	  Return
   EndIf
   $id = $arr[0]
   $serial = $arr[1]
   $title = $arr[2]
   $long = $arr[3]
   $author = $arr[4]

   _LogProgress('Creating CIA ...')
   _RunWait('tools\makerom ' _
	  & '-f cia -target t ' _
	  & '-rsf "template\custom.rsf" ' _
	  & '-o "' & _GetCiaDir() & $cia & '" ' _
	  & '-exefslogo ' _
	  & '-icon "' & _GetCiaDir() & 'exefs\icon.bin" ' _
	  & '-banner "' & _GetCiaDir() & 'exefs\banner.bin" ' _
	  & '-elf "template\' & $optEmulator & '" ' _
	  & '-DAPP_TITLE="' & $title & '" ' _
	  & '-DAPP_PRODUCT_CODE="' & $serial & '" ' _
	  & '-DAPP_UNIQUE_ID=0x' & $id & ' ' _
	  & '-DAPP_ROMFS="' & _GetCiaDir() & 'romfs"')

   FileDelete(_GetCiaDir() & 'exefs\*')
   DirRemove(_GetCiaDir() & 'exefs')
   FileDelete(_GetCiaDir() & 'romfs\*')
   DirRemove(_GetCiaDir() & 'romfs')

   _LogProgress('Done')
EndFunc
