
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#include <Math.au3>
#include 'functions.au3'

#include-once

If @ScriptName == 'banner.au3' Or @ScriptName == 'banner.exe' Then
   For $t = 1 To $CmdLine[0]
	  $title = $CmdLine[$t]
	  ConsoleWrite($t & ' of ' & $CmdLine[0] & ': ' & $title & @CRLF)
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

   Local $vc
   If StringLen($long) <> 0 Then
	  $vc = $long
	  If Not StringInStr($vc, '\n') Then
		 $vc = StringReplace($vc, ': ', ':\n', 1)
	  EndIf
   EndIf
   If StringLen($release) == 0 Then
	  ConsoleWrite('WARNING: Missing release' & @CRLF)
   EndIf

   Local $fLabel = _FileExistsArr('label.png|label.jpg|label.jpeg', _GetInput($title))
   If Not $fLabel Then
	  _Error('ERROR: Label image not found')
	  SetError(-1)
	  Return
   EndIf

   Local $fBanner = _FileExistsArr('banner.png|banner.jpg|banner.jpeg', _GetInput($title))
   If Not $fBanner Then
	  _Error('ERROR: Banner image not found')
	  SetError(-1)
	  Return
   EndIf

   Local $resourceDir = 'template\'
   If Not FileExists($resourceDir) Then
	  $resourceDir = 'tools\'
   EndIf
   DirCreate(_GetOutput($title))

   ;; Process label, ETC1
   _RunWait('tools\convert "' & $fLabel & '" -rotate 270 -resize 23x44! "' & _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert ' & $resourceDir & 'USA_EN3.png "' &  _GetOutput($title) & 'temp.png" -geometry +122+205 -composite -flip "' &  _GetOutput($title) & 'USA_EN3.png"')
   _RunWait('tools\3dstex -r -o auto-etc1 "' &  _GetOutput($title) & 'USA_EN3.png" "' &  _GetOutput($title) & 'USA_EN3.bin"')

   _RunWait('tools\convert "' & $fLabel & '" -resize 54x18! "' &  _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert ' & $resourceDir & 'EUR_EN3.png "' &  _GetOutput($title) & 'temp.png" -geometry +198+227 -composite -flip "' &  _GetOutput($title) & 'EUR_EN3.png"')
   _RunWait('tools\3dstex -r -o auto-etc1 "' &  _GetOutput($title) & 'EUR_EN3.png" "' &  _GetOutput($title) & 'EUR_EN3.bin"')

   ;; Process banner, 32-bit ARGB
   _RunWait('tools\convert "' & $fBanner & '" -resize 120x102! "' &  _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert ' & $resourceDir & 'COMMON1.png "' &  _GetOutput($title) & 'temp.png" -geometry +4+6 -composite -flip "' &  _GetOutput($title) & 'common1.png"')
   _RunWait('tools\3dstex -r -o rgba8 "' &  _GetOutput($title) & 'common1.png" "' &  _GetOutput($title) & 'common1.bin"')

   _RunWait('tools\convert "' & $fBanner & '" -resize 60x51! "' &  _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert ' & $resourceDir & 'COMMON1_2.png "' &  _GetOutput($title) & 'temp.png" -geometry +2+3 -composite -flip "' &  _GetOutput($title) & 'common1_2.png"')
   _RunWait('tools\3dstex -r -o rgba8 "' &  _GetOutput($title) & 'common1_2.png" "' &  _GetOutput($title) & 'common1_2.bin"')

   _RunWait('tools\convert "' & $fBanner & '" -resize 30x26! "' &  _GetOutput($title) & 'temp.png"')
   _RunWait('tools\convert ' & $resourceDir & 'COMMON1_3.png "' &  _GetOutput($title) & 'temp.png" -geometry +1+1 -composite -flip "' &  _GetOutput($title) & 'common1_3.png"')
   _RunWait('tools\3dstex -r -o rgba8 "' &  _GetOutput($title) & 'common1_3.png" "' &  _GetOutput($title) & 'common1_3.bin"')

   FileDelete(_GetOutput($title) & 'temp.png')

   ;; VC label
   $font = _PathFull($resourceDir & 'SCE-PS3-RD-B-LATIN.TTF')
   If Not FileExists($font) Then
	  $font = _PathFull($resourceDir & 'SCE-PS3-RD-R-LATIN.TTF')
   EndIf
   Local $fontSetup = ' -font "' & $font & '"' & ' -stretch Normal' & ' -background #0000' & ' -fill #1e1e1e'
   Local $vcCaption = ' -gravity center' & ' -interline-spacing 1' & ' -size 159x' & ' caption:"' & $vc & '"'
   Local $releaseCaption = ' -gravity center' & ' -kerning 1' & ' -size 159x' & ' caption:"Released: ' & $release & '"'

   ;; Calculate the best fit
   For $point = 16 To 12 Step -2
	  ;; Check the height
	  $height = _RunWait('tools\convert' & $fontSetup & ' -pointsize ' & $point & $vcCaption & ' -format "%[fx:h]"' & ' info:')
	  ;; Exit if small enough
	  If $height <= 34 Then
		 ExitLoop
	  EndIf
   Next
   ;; Reduce a bit to look nicer and be one of 15, 13, 11
   $point -= 1
   ;; Don't go smaller than 11pt
   $point = _Max(11, $point)
   $pointSize = ' -pointsize ' & $point
   $height = _RunWait('tools\convert' & $fontSetup & ' -pointsize ' & $point & $vcCaption & ' -format "%[fx:h]"' & ' info:')

   ;; Calculate offsets
   Local $vcOffset = 26 - ($height / 2)
   $vcOffset = _Min(42 - $height, $vcOffset)
   Local $releaseHeight = 16
   Local $releaseOffset = 64 - ($vcOffset + $height + $releaseHeight)
   $releaseOffset = _Max(6, $releaseOffset)

   Local $vcCaptionComp = ' -gravity northeast' & ' -geometry +4+' & $vcOffset & ' -compose over' & ' -composite'
   Local $releaseCaptionComp = ' -gravity southeast' & ' -geometry +4+' & $releaseOffset & ' -compose over' & ' -composite'

   ;; Create composite image
   _RunWait('tools\convert' _
	  & ' "' & $resourceDir & 'USA_EN2.png"' _
	  & $fontSetup _
	  & $pointSize _
	  & $vcCaption _
	  & $vcCaptionComp _
	  & ' -pointsize 13' _
	  & $releaseCaption _
	  & $releaseCaptionComp _
	  & ' -flip' _
	  & ' "' &  _GetOutput($title) & 'USA_EN2.png"')

   ;; L8A8 greyscale format
   _RunWait('tools\3dstex -r -o la8 "' &  _GetOutput($title) & 'USA_EN2.png" "' &  _GetOutput($title) & 'USA_EN2.bin"')

   ;; Insert into banner models
   If FileExists($resourceDir & 'banner') Then
	  DirCopy($resourceDir & 'banner',  _GetOutput($title) & 'banner', $FC_OVERWRITE)
   Else
	  DirCopy('banner',  _GetOutput($title) & 'banner', $FC_OVERWRITE)
   EndIf

   For $i = 0 To 0
	  Local $file, $hFileOpen
	  $file =  _GetOutput($title) & 'common1.bin'
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file =  _GetOutput($title) & 'common1_2.bin'
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file =  _GetOutput($title) & 'common1_3.bin'
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex3 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file =  _GetOutput($title) & 'banner\banner' & $i & '.bcmdl'
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
	  $file = _GetOutput($title) & 'USA_EN2.bin' ;; VC Title, offset 0x7700, 16BPP L8A8 (Grayscale)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = _GetOutput($title) & 'EUR_EN3.bin' ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = _GetOutput($title) & 'banner\banner' & $i & '.bcmdl'
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
	  $file = _GetOutput($title) & 'USA_EN2.bin' ;; VC Title, offset 0x7700, 16BPP L8A8 (Grayscale)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex1 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = _GetOutput($title) & 'USA_EN3.bin' ;; Console, offset 0xF700, 24BPP ETC1 (iPACKMAN)
	  $hFileOpen = FileOpen($file, $FO_READ + $FO_BINARY)
	  Local $bTex2 = FileRead($hFileOpen)
	  FileClose($hFileOpen)

	  $file = _GetOutput($title) & 'banner\banner' & $i & '.bcmdl'
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

   ;; Generate banner
   _RunWait('tools\3dstool -c -f banner.bin -t banner --banner-dir banner', _GetOutput($title))

   ;; Clean up
   FileDelete(_GetOutput($title) & 'common1.png')
   FileDelete(_GetOutput($title) & 'common1.bin')
   FileDelete(_GetOutput($title) & 'common1_2.png')
   FileDelete(_GetOutput($title) & 'common1_2.bin')
   FileDelete(_GetOutput($title) & 'common1_3.png')
   FileDelete(_GetOutput($title) & 'common1_3.bin')
   FileDelete(_GetOutput($title) & 'USA_EN2.png')
   FileDelete(_GetOutput($title) & 'USA_EN2.bin')
   FileDelete(_GetOutput($title) & 'USA_EN3.png')
   FileDelete(_GetOutput($title) & 'USA_EN3.bin')
   FileDelete(_GetOutput($title) & 'EUR_EN3.png')
   FileDelete(_GetOutput($title) & 'EUR_EN3.bin')
   FileDelete(_GetOutput($title) & 'banner\*')
   DirRemove(_GetOutput($title) & 'banner')
EndFunc

