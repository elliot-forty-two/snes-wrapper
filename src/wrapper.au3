
#include <Array.au3>
#include <File.au3>
#include "banner.au3"
#include "functions.au3"

#include-once

Func ProcessTitle($title)
   ;; Read ROM info
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
	  _CreateIcon($title, $long, $author)
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
	  _CreateRomfs($title)
	  _RunWait('tools\makerom -f cia -target t -rsf "template\custom.rsf" ' _
		 & '-o "' & _GetCiaDir() & $title & '.cia" -exefslogo ' _
		 & '-icon "' & _GetOutput($title) & 'icon.bin" ' _
		 & '-banner "' & _GetOutput($title) & 'banner.bin" ' _
		 & '-elf "template\' & $optEmulator & '" ' _
		 & '-DAPP_TITLE="' & $title & '" ' _
		 & '-DAPP_PRODUCT_CODE="' & $serial & '" ' _
		 & '-DAPP_UNIQUE_ID="0x' & $id & '" ' _
		 & '-DAPP_ROMFS="output\' & $title & '\romfs"')

	  FileDelete(_GetOutput($title) & 'romfs\*')
	  DirRemove(_GetOutput($title) & 'romfs')
   EndIf

   _LogProgress('Done')
EndFunc

Func _CreateRomfs($title)
   DirCreate(_GetOutput($title) & "romfs")

   FileCopy(_GetInput($title) & "*.smc", _GetOutput($title) & "romfs\rom.smc")
   FileCopy(_GetInput($title) & "*.sfc", _GetOutput($title) & "romfs\rom.smc")

   ;; snes9x
   FileCopy(_GetInput($title) & "\*.cfg", _GetOutput($title) & "romfs\rom.cfg")
   ;; blargsnes
   FileCopy(_GetInput($title) & "\*.bmp", _GetOutput($title) & "romfs\blargSnesBorder.bmp")
   FileCopy(_GetInput($title) & "\*.ini", _GetOutput($title) & "romfs\blargSnes.ini")

   FileWrite(_GetOutput($title) & "romfs\rom.txt", $title)
EndFunc

Func _CreateIcon($title, $long, $author)
   Local $file = _FileExistsArr('icon.png|icon.jpg|icon.jpeg|banner.png|banner.jpg|banner.jpeg', _GetInput($title))
   If Not $file Then
	  _Error('ERROR: Icon image not found')
	  SetError(-1)
	  Return
   EndIf

   _RunWait('tools\convert "' & $file & '" -resize 40x40! "' & _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert template\icon.png "' & _GetOutput($title) & 'temp.png" -gravity center -composite "' & _GetOutput($title) & 'icon.png"')
   _RunWait('tools\bannertool makesmdh -s "' & $title & '" -l "' & $long & '" -p "' & $author & '" -i "' & _GetOutput($title) & 'icon.png" -o "' & _GetOutput($title) & 'icon.bin"')

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
	  & '-DAPP_ROMFS="romfs"')

   FileDelete(_GetCiaDir() & 'exefs\*')
   DirRemove(_GetCiaDir() & 'exefs')

   _LogProgress('Done')
EndFunc
