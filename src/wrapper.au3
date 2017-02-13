
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

   _CreateRomfs($title)

   _LogProgress('Creating icon.bin ...')
   If Not FileExists(_GetOutput($title) & 'icon.bin') Then
	  _CreateIcon($title, $long, $author)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
   EndIf

   _LogProgress('Creating banner.bin ...')
   If Not FileExists(_GetOutput($title) & 'banner.bin') Then
	  _GenerateBanner($title)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
   EndIf

   _LogProgress('Creating CIA ...')
   DirCreate(_GetOutput('cia'))
   _RunWait('tools\makerom -f cia -target t -rsf "template\custom.rsf" ' _
	  & '-o "' & _GetOutput('cia') & $title & '.cia" -exefslogo ' _
	  & '-icon "' & _GetOutput($title) & 'icon.bin" ' _
	  & '-banner "' & _GetOutput($title) & 'banner.bin" ' _
	  & '-elf "template\' & $optEmulator & '" ' _
	  & '-DAPP_TITLE="' & $title & '" ' _
	  & '-DAPP_PRODUCT_CODE="' & $serial & '" ' _
	  & '-DAPP_UNIQUE_ID="0x' & $id & '" ' _
	  & '-DAPP_ROMFS="output\' & $title & '\romfs"')

   FileDelete(_GetOutput($title) & 'romfs\*')
   DirRemove(_GetOutput($title) & 'romfs')

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

