
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#include "tools.au3"

#include-once

If @ScriptName == 'banner.au3' Or @ScriptName == 'banner.exe' Then
   $titles = _FileListToArray("input", "*", $FLTA_FOLDERS)
   For $t = 1 To $titles[0]
	  $title = $titles[$t]
	  ConsoleWrite($t & " of " & $titles[0] & ": " & $title & @CRLF)
	  _GenerateBanner($title)
   Next
EndIf

Func _GenerateBanner($title)
   ;; Read ROM info
   Local $long = _InfoGet($title, 'long')
   Local $author = _InfoGet($title, 'author')
   Local $serial = _InfoGet($title, 'serial')
   Local $id = _InfoGet($title, 'id')
   Local $release = _InfoGet($title, 'release')

   If StringLen($long) <> 0 Then
	  $vc = $long
   EndIf
   If StringLen($release) == 0 Then
	  ConsoleWrite("WARNING: Missing release")
   EndIf

   Local $fLabel = _FileExistsArr("label.png|label.jpg|label.jpeg", "input\" & $title)
   If Not $fLabel Then
	  _Error("ERROR: Label image not found")
	  SetError(-1)
	  Return
   EndIf

   Local $fBanner = _FileExistsArr("banner.png|banner.jpg|banner.jpeg", "input\" & $title)
   If Not $fBanner Then
	  _Error("ERROR: Banner image not found")
	  SetError(-1)
	  Return
   EndIf

   DirCreate("output\" & $title)

   ;; Process label, ETC1
   _RunWait("tools\convert """ & $fLabel & """ -rotate 270 -resize 23x44! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\USA_EN3.png ""output\" & $title & "\temp.png"" -geometry +122+205 -composite -flip ""output\" & $title & "\USA_EN3.png""")
   _RunWait("tools\3dstex -r -o auto-etc1 ""output\" & $title & "\USA_EN3.png"" ""output\" & $title & "\USA_EN3.bin""")

   _RunWait("tools\convert """ & $fLabel & """ -resize 54x18! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\EUR_EN3.png ""output\" & $title & "\temp.png"" -geometry +198+227 -composite -flip ""output\" & $title & "\EUR_EN3.png""")
   _RunWait("tools\3dstex -r -o auto-etc1 ""output\" & $title & "\EUR_EN3.png"" ""output\" & $title & "\EUR_EN3.bin""")

   ;; Process banner, 32-bit ARGB
   _RunWait("tools\convert """ & $fBanner & """ -resize 120x102! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\COMMON1.png ""output\" & $title & "\temp.png"" -geometry +4+6 -composite -flip ""output\" & $title & "\common1.png""")
   _RunWait("tools\3dstex -r -o rgba8 ""output\" & $title & "\common1.png"" ""output\" & $title & "\common1.bin""")

   _RunWait("tools\convert """ & $fBanner & """ -resize 60x51! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\COMMON1_2.png ""output\" & $title & "\temp.png"" -geometry +2+3 -composite -flip ""output\" & $title & "\common1_2.png""")
   _RunWait("tools\3dstex -r -o rgba8 ""output\" & $title & "\common1_2.png"" ""output\" & $title & "\common1_2.bin""")

   _RunWait("tools\convert """ & $fBanner & """ -resize 30x26! ""output\" & $title & "\temp.png""")
   _RunWait("tools\convert template\COMMON1_3.png ""output\" & $title & "\temp.png"" -geometry +1+1 -composite -flip ""output\" & $title & "\common1_3.png""")
   _RunWait("tools\3dstex -r -o rgba8 ""output\" & $title & "\common1_3.png"" ""output\" & $title & "\common1_3.bin""")

   FileDelete("output\" & $title & "\temp.png")

   ;; Format title text
   $f=14
   $k=1
   $w=6
   $lt=3
   $lr=6
   If StringLen($title) > 14 Then
	  $f = 13
	  Local $aParts = StringSplit($vc, " ")
	  Local $len = 0
	  $vc = ""
	  For $i = 1 To $aParts[0]
		 $len += StringLen($aParts[$i]) + 1
		 If $len > 18 Then
			$lt=1
			$lr=20
			$vc &= "\n"
			$len = 0
		 EndIf
		 $vc &= $aParts[$i]
		 If $i < $aParts[0] Then
			$vc &= " "
		 EndIf
	  Next
   EndIf
   ;; L8A8 greyscale format
   _RunWait("tools\convert template\USA_EN2.png -gravity center -font template\SCE-PS3-RD-R-LATIN.TTF -pointsize " & $f & " -kerning " & $k & " -fill #1e1e1e -interword-spacing " & $w & " -interline-spacing " & $lt & " -annotate +45+0 """ & $vc & "\n"" -pointsize " & $f & " -kerning 1.5 -interword-spacing 6 -interline-spacing " & $lr & " -annotate +46+0 ""\nReleased: " & $release & """ -flip ""output\" & $title & "\USA_EN2.png""")
   _RunWait("tools\3dstex -r -o la8 ""output\" & $title & "\USA_EN2.png"" ""output\" & $title & "\USA_EN2.bin""")

   DirCopy("template\banner", "output\" & $title & "\banner", $FC_OVERWRITE)

   For $i = 0 To 0
	  Local $file, $hFileOpen
	  $file = @WorkingDir & "\output\" & $title & "\common1.bin" ;; VC Title, offset 0x7700, 16BPP L8A8 (Grayscale)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\common1_2.bin" ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\common1_3.bin" ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex3 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\banner\banner" & $i & ".bcmdl"
	  Local $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bFileHead = FileRead($hFileOpen, 0x9F00)
	  FileSetPos($hFileOpen, 0x1EF00, $FILE_BEGIN)
	  Local $bFileTail = FileRead($hFileOpen)
	  FileClose($hFileOpen)
	  FileDelete($file)
	  Local $hFileOpen = FileOpen($file, $FO_APPEND + $FO_BINARY)
	  FileWrite($hFileOpen, $bFileHead)
	  FileWrite($hFileOpen, $bTex1)
	  FileWrite($hFileOpen, $bTex2)
	  FileWrite($hFileOpen, $bTex3)
	  FileWrite($hFileOpen, $bFileTail)
	  FileClose($hFileOpen)
   Next

   For $i = 1 To 8
	  Local $file, $hFileOpen
	  $file = @WorkingDir & "\output\" & $title & "\USA_EN2.bin" ;; VC Title, offset 0x7700, 16BPP L8A8 (Grayscale)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\EUR_EN3.bin" ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\banner\banner" & $i & ".bcmdl"
	  Local $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bFileHead = FileRead($hFileOpen, 0x7700)
	  FileSetPos($hFileOpen, 0x17700, $FILE_BEGIN)
	  Local $bFileTail = FileRead($hFileOpen)
	  FileClose($hFileOpen)
	  FileDelete($file)
	  Local $hFileOpen = FileOpen($file, $FO_APPEND + $FO_BINARY)
	  FileWrite($hFileOpen, $bFileHead)
	  FileWrite($hFileOpen, $bTex1)
	  FileWrite($hFileOpen, $bTex2)
	  FileWrite($hFileOpen, $bFileTail)
	  FileClose($hFileOpen)
   Next

   For $i = 10 To 13
	  Local $file, $hFileOpen
	  $file = @WorkingDir & "\output\" & $title & "\USA_EN2.bin" ;; VC Title, offset 0x7700, 16BPP L8A8 (Grayscale)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\USA_EN3.bin" ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = @WorkingDir & "\output\" & $title & "\banner\banner" & $i & ".bcmdl"
	  Local $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bFileHead = FileRead($hFileOpen, 0x7700)
	  FileSetPos($hFileOpen, 0x17700, $FILE_BEGIN)
	  Local $bFileTail = FileRead($hFileOpen)
	  FileClose($hFileOpen)
	  FileDelete($file)
	  Local $hFileOpen = FileOpen($file, $FO_APPEND + $FO_BINARY)
	  FileWrite($hFileOpen, $bFileHead)
	  FileWrite($hFileOpen, $bTex1)
	  FileWrite($hFileOpen, $bTex2)
	  FileWrite($hFileOpen, $bFileTail)
	  FileClose($hFileOpen)
   Next

   _RunWait("tools\3dstool -c -f banner.bin -t banner --banner-dir banner", "output\" & $title & "\")

   FileDelete("output\" & $title & "\" & "common1.png")
   FileDelete("output\" & $title & "\" & "common1.bin")
   FileDelete("output\" & $title & "\" & "common1_2.png")
   FileDelete("output\" & $title & "\" & "common1_2.bin")
   FileDelete("output\" & $title & "\" & "common1_3.png")
   FileDelete("output\" & $title & "\" & "common1_3.bin")
   FileDelete("output\" & $title & "\" & "USA_EN2.png")
   FileDelete("output\" & $title & "\" & "USA_EN2.bin")
   FileDelete("output\" & $title & "\" & "USA_EN3.png")
   FileDelete("output\" & $title & "\" & "USA_EN3.bin")
   FileDelete("output\" & $title & "\" & "EUR_EN3.png")
   FileDelete("output\" & $title & "\" & "EUR_EN3.bin")
   FileDelete("output\" & $title & "\" & "banner\*")
   DirRemove("output\" & $title & "\" & "banner")
EndFunc

