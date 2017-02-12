
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
   $files = _FileListToArray("input\" & $title, "*.s?c", $FLTA_FILES)
   For $i = 1 To $files[0]
	  $ext = StringRight($files[$i], 3)
	  If $ext == "smc" Or $ext == "sfc" Then
		 $file = $files[$i]
	  EndIf
   Next
   If Not FileExists("input\" & $title & "\" & $file) Then
	  _Error("ERROR: Missing rom file. Make sure you have a rom file in input\" & $title & "\")
	  SetError(-1)
	  Return
   EndIf

   _CreateRomfs($title)

   _LogProgress('Creating icon.bin ...')
   If Not FileExists('output\' & $title & '\icon.bin') Then
	  _CreateIcon($title, $long, $author)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
   EndIf

   _LogProgress('Creating banner.bin ...')
   If Not FileExists('output\' & $title & '\banner.bin') Then
	  _GenerateBanner($title)
	  If @error <> 0 Then
		 SetError(-1)
		 Return
	  EndIf
   EndIf

   _LogProgress('Creating CIA ...')
   DirCreate("cia")
   _RunWait("tools\makerom -f cia -target t -rsf ""template\custom.rsf"" " _
	  & "-o ""cia\" & $title & ".cia"" -exefslogo " _
	  & "-icon ""output\" & $title & "\icon.bin"" " _
	  & "-banner ""output\" & $title & "\banner.bin"" " _
	  & "-elf ""template\" & $optEmulator & """ " _
	  & "-DAPP_TITLE=""" & $title & """ " _
	  & "-DAPP_PRODUCT_CODE=""" & $serial & """ " _
	  & "-DAPP_UNIQUE_ID=""0x" & $id & """ " _
	  & "-DAPP_ROMFS=""output\" & $title & "\romfs""")

   FileDelete("output\" & $title & "\romfs\*")
   DirRemove("output\" & $title & "\romfs")
EndFunc

Func _CreateRomfs($title)
   DirCreate("output\" & $title & "\romfs")

   FileCopy("input\" & $title & "\*.smc", "output\" & $title & "\romfs\rom.smc")
   FileCopy("input\" & $title & "\*.sfc", "output\" & $title & "\romfs\rom.smc")

   ;; snes9x
   FileCopy("input\" & $title & "\*.cfg", "output\" & $title & "\romfs\rom.cfg")
   ;; blargsnes
   FileCopy("input\" & $title & "\*.bmp", "output\" & $title & "\romfs\blargSnesBorder.bmp")
   FileCopy("input\" & $title & "\*.ini", "output\" & $title & "\romfs\blargSnes.ini")

   FileWrite("output\" & $title & "\romfs\rom.txt", $title)
EndFunc

Func _CreateIcon($title, $long, $author)
   Local $file = _FileExistsArr("icon.png|icon.jpg|icon.jpeg|banner.png|banner.jpg|banner.jpeg", "input\" & $title)
   If Not $file Then
	  _Error("ERROR: Icon image not found")
	  SetError(-1)
	  Return
   EndIf

   _RunWait("tools\convert """ & $file & """ -resize 40x40! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\icon.png ""output\" & $title & "\temp.png"" -gravity center -composite ""output\" & $title & "\icon.png""")
   _RunWait("tools\bannertool makesmdh -s """ & $title & """ -l """ & $long & """ -p """ & $author & """ -i ""output\" & $title & "\icon.png"" -o ""output\" & $title & "\icon.bin""")

   FileDelete("output\" & $title & "\temp.png")
EndFunc

