
#NoTrayIcon

#include <File.au3>
#include 'lib/GetOpt.au3'
#include 'options.au3'
#include 'functions.au3'
#include 'banner.au3'

If @ScriptName == 'sneswrapper.au3' Or @ScriptName == 'sneswrapper.exe' Then
   ConsoleWrite("SNES Wrapper - SNES VC for Old 3DS" & @CRLF & @CRLF)
   ParseOpts()

   $optFolder = _PathFull($optFolder)
   If Not FileExists($optFolder) Then
	  _LogError('Folder not found: ' & $optFolder)
	  Exit 1
   EndIf
   _LogMessage('Using folder: ' & $optFolder)

   If $optUpdate Then
	  $cias = _FileListToArrayRec(_GetCiaOutput(), '*.cia', $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)
	  If @error == 0 Then
		 _LogMessage('Updating CIA files')
		 For $c = 1 To $cias[0]
			$cia = $cias[$c]
			_LogVerbose('')
			_LogMessage($c & " of " & $cias[0] & ": " & $cia)
			UpdateCIA($cia)
		 Next
	  EndIf
   Else
	  $titles = _FileListToArrayRec(_GetInput(), '*', $FLTAR_FOLDERS, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)
	  If @error == 0 Then
		 For $t = 1 To $titles[0]
			$title = StringReplace($titles[$t], '\', '')
			_LogVerbose('')
			_LogMessage($t & " of " & $titles[0] & ": " & $title)
			ProcessTitle($title)
		 Next
	  EndIf
   EndIf
EndIf

Func ProcessTitle($title)
   ;; Read ROM info
   Local $short = _GetInfoValue($title, 'short')
   Local $long = _GetInfoValue($title, 'long')
   Local $author = _GetInfoValue($title, 'author')
   Local $serial = _GetInfoValue($title, 'serial')
   Local $id = _GetInfoValue($title, 'id')
   If Not $short Or Not $long Or Not $author Or Not $serial Or Not $id Then
	  _LogError('Game info not found')
	  Return SetError(-1)
   EndIf

   Local $file
   $files = _FileListToArrayRec(_GetInput($title), '*.s?c', $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)
   For $i = 1 To $files[0]
	  $ext = StringRight($files[$i], 3)
	  If $ext == 'smc' Or $ext == 'sfc' Then
		 $file = $files[$i]
	  EndIf
   Next
   If Not FileExists(_GetInput($title) & $file) Then
	  _LogError('ROM file not found, make sure you have a rom file in ' & _GetInput($title))
	  Return SetError(-1)
   EndIf

   Local $cleanCia = False

   If $optClean Or Not FileExists(_GetOutput($title) & 'icon.bin') Then
	  _LogProgress('Creating icon.bin ...')
	  CreateIcon($title)
	  If @error <> 0 Then
		 Return SetError(-1)
	  EndIf
	  $cleanCia = True
   EndIf

   If $optClean Or Not FileExists(_GetOutput($title) & 'banner.bin') Then
	  _LogProgress('Creating banner.bin ...')
	  GenerateBanner($title)
	  If @error <> 0 Then
		 Return SetError(-1)
	  EndIf
	  $cleanCia = True
   EndIf

   If $optClean Or $cleanCia Or Not FileExists(_GetCiaOutput() & $title & '.cia') Then
	  _LogProgress('Creating CIA ...')
	  DirCreate(_GetCiaOutput())

	  CreateRomfs($title)
	  If @error <> 0 Then
		 Return SetError(-1)
	  EndIf

	  _RunWait('tools\makerom -f cia -target t -rsf "template\custom.rsf" ' _
		 & '-o "' & _GetCiaOutput() & $title & '.cia" -exefslogo ' _
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

Func CreateRomfs($title)
   DirCreate(_GetOutput($title) & "romfs")
   Local $long = _GetInfoValue($title, 'long')
   If Not $long Then
	  _LogError('Game info not found')
	  Return SetError(-1)
   EndIf

   FileCopy(_GetInput($title) & "*.smc", _GetOutput($title) & "romfs\rom.smc")
   FileCopy(_GetInput($title) & "*.sfc", _GetOutput($title) & "romfs\rom.smc")

   If $optEmulator == $emuSnes9x Then
	  ;; snes9x
	  FileCopy(_GetInput($title) & "\*.cfg", _GetOutput($title) & "romfs\rom.cfg")
   Else
	  ;; blargsnes
	  FileCopy(_GetInput($title) & "\*.bmp", _GetOutput($title) & "romfs\blargSnesBorder.bmp")
	  FileCopy(_GetInput($title) & "\*.ini", _GetOutput($title) & "romfs\blargSnes.ini")
   EndIf

   FileWrite(_GetOutput($title) & "romfs\rom.txt", $long)
EndFunc

Func CreateIcon($title)
   DirCreate(_GetOutput($title))
   Local $short = _GetInfoValue($title, 'short')
   Local $long = _GetInfoValue($title, 'long')
   Local $author = _GetInfoValue($title, 'author')
   If Not $short Or Not $long Or Not $author Then
	  _LogError('Game info not found')
	  Return SetError(-1)
   EndIf

   Local $files = ['icon.png', 'icon.jpg', 'icon.jpeg', 'banner.png', 'banner.jpg', 'banner.jpeg']
   Local $fIcon = _FileExistsArr($files, _GetInput($title))
   If Not $fIcon Then
	  _LogError('Icon image not found')
	  Return SetError(-1)
   EndIf

   _RunWait('tools\convert ' _
	  & '-size 48x48 ( gradient:#ffffff-#626262 ) ' _
	  & '( -size 44x44 gradient:#626262-#c5c5c5 ) -gravity center -composite ' _
	  & '( -size 40x40 canvas:#1e1e1e ) -gravity center -composite ' _
	  & '( "' & $fIcon & '" -resize 40x40! ) -gravity center -composite ' _
	  & '"' & _GetOutput($title) & 'icon.png"')
   _RunWait('tools\bannertool makesmdh -s "' & $short & '" -l "' & $long & '" -p "' & $author & '" -i "' & _GetOutput($title) & 'icon.png" -o "' & _GetOutput($title) & 'icon.bin"')
EndFunc

Func UpdateCIA($cia)
   _LogProgress('Extracting NCCH ...')
   _RunWait('tools\ctrtool -x -t cia --contents ncch "' & $cia & '"', _GetCiaOutput())
   $ncchs = _FileListToArray(_GetCiaOutput(), 'ncch*.*', $FLTA_FILES)
   If @error == 0 Then
	  For $i = 1 To $ncchs[0]
		 $ncch = $ncchs[$i]
		 _LogProgress('Extracting exefs ' & $i & ' ...')
		 _RunWait('tools\ctrtool -x -t ncch --exefsdir exefs --romfsdir romfs "' & $ncch & '"', _GetCiaOutput())
		 FileDelete(_GetCiaOutput() & $ncch)
	  Next
   EndIf

   _LogProgress('Extracting info ...')
   _RunWait('tools\ciainfo "' & $cia & '"', _GetCiaOutput())
   $arr = FileReadToArray(_GetCiaOutput() & 'info.txt')
   FileDelete(_GetCiaOutput() & 'info.txt')
   If UBound($arr) <> 5 Then
	  _LogError('CIA info returned wrong number of values')
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
	  & '-o "' & _GetCiaOutput() & $cia & '" ' _
	  & '-exefslogo ' _
	  & '-icon "' & _GetCiaOutput() & 'exefs\icon.bin" ' _
	  & '-banner "' & _GetCiaOutput() & 'exefs\banner.bin" ' _
	  & '-elf "template\' & $optEmulator & '" ' _
	  & '-DAPP_TITLE="' & $title & '" ' _
	  & '-DAPP_PRODUCT_CODE="' & $serial & '" ' _
	  & '-DAPP_UNIQUE_ID=0x' & $id & ' ' _
	  & '-DAPP_ROMFS="' & _GetCiaOutput() & 'romfs"')

   FileDelete(_GetCiaOutput() & 'exefs\*')
   DirRemove(_GetCiaOutput() & 'exefs')
   FileDelete(_GetCiaOutput() & 'romfs\*')
   DirRemove(_GetCiaOutput() & 'romfs')

   _LogProgress('Done')
EndFunc

Func ParseOpts()
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
			_LogError('Unknown option: ' & $GetOpt_Opt & @CRLF)
			Help()
		 Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
		 Case 'c'
			$optClean = $GetOpt_Arg
		 Case 'u'
			$optUpdate = $GetOpt_Arg
		 Case 'v'
			$optVerbose = $GetOpt_Arg
		 Case 'b'
			If $GetOpt_Arg Then
			   $optEmulator = $emuBlarg
			EndIf
		 Case 'h'
			Help()
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

Func Help()
   _LogMessage('Usage: ' & @ScriptName & ' [-h] [-c|-u] [-b] [-v] [<folder>]')
   _LogMessage(@TAB & '-h --help' & @TAB & 'Show this help message')
   _LogMessage(@TAB & '-c --clean' & @TAB & 'Recreate output')
   _LogMessage(@TAB & '-u --update' & @TAB & 'Update existing CIAs with new emulator')
   _LogMessage(@TAB & '-b --blarg' & @TAB & 'Inject blargSNES instead of snes9x')
   _LogMessage(@TAB & '-v --verbose' & @TAB & 'Verbose output')
   _LogMessage(@TAB & '<folder>' & @TAB & 'Set the working folder where "input" folder resides')
   Exit
EndFunc
