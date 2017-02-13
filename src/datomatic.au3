
#include <Constants.au3>
#include <String.au3>
#include <Math.au3>
#include <File.au3>
#include 'lib/LibCsv2.au3'
#include 'functions.au3'

If @ScriptName == 'datomatic.au3' Or @ScriptName == 'datomatic.exe' Then
   Global $targetDir = 'input'
   If $CmdLine[0] == 1 Then
	  $targetDir = $CmdLine[1]
   EndIf
   $targetDir = _PathFull($targetDir)
   If Not FileExists($targetDir) Then
	  _Error('ERROR: Folder not found: ' & $targetDir & @CRLF)
	  Exit 1
   EndIf

   CleanROMs()
   ImportROMs()
EndIf

Func GetSerial($hash, $region = 'USA')
   Local $serial = $hash
   If FileExists('data\datomatic.txt') Then
	  Local $csv = _CSVReadFile('data\datomatic.txt')
	  Local $i, $j
	  For $i=1 To UBound($csv) - 1
		 If $hash == $csv[$i][6] Then
			$serial = $csv[$i][1]
			If  $region == $csv[$i][2] And Not StringLower($serial) == 'unk' Then
			   Return $serial
			EndIf
		 EndIf
	  Next
   EndIf
   Return $serial
EndFunc

Func CleanROMs()
   ConsoleWrite('CleanROMs' & @CRLF)
   _RunWait('tools\nsrt.exe -savetype uncompressed -remhead -rename -lowext -noext "*"', $targetDir)
EndFunc

Func _XmlFileLoad($strFile)
	$oXml = ObjCreate('Msxml2.DOMDocument.3.0')
	$oXml.async = 0
	$oXml.load($strFile)
	If $oXml.parseError.errorCode <> 0 Then
		_Error('Error opening specified file: ' & $strFile & ': ' & $oXml.parseError.reason)
		SetError($oXml.parseError.errorCode)
		Return 0
	EndIf
	Return $oXml
EndFunc

Func GetReleaseDate($file, $workingdir = $targetDir)
   $oOXml = _XmlFileLoad($workingdir & '\gamelist.xml')
   $oXmlroot = $oOXml.documentElement
   $objElement = $oXmlroot.getElementsByTagName('game')
   For $oXmlNode In $objElement
	  $match = False
	  For $oXmlNodeD In $oXmlNode.childNodes
		 Select
		 Case $oXmlnodeD.nodename = 'path'
			If StringCompare($file, StringTrimLeft($oXmlnodeD.text, 2)) == 0 Then
			   $match = True
			EndIf
		 Case $oXmlnodeD.nodename = 'releasedate'
			If $match Then
			   Return StringLeft($oXmlnodeD.text, 4)
			EndIf
		 EndSelect
	  Next
   Next
EndFunc

Func ImportROMs()
   ConsoleWrite('ImportROMs' & @CRLF)

   Local $file
   $files = _FileListToArray($targetDir, '*.s?c', $FLTA_FILES)
   If @error == 0 Then
	  For $i = 1 To $files[0]
		 $ext = StringRight($files[$i], 3)
		 If $ext == 'smc' Or $ext == 'sfc' Then
			$file = $files[$i]
			$name = StringTrimRight($file, 4)
			$name = StringRegExpReplace($name, '[\(\[].*[\)\]]', '')
			$name = StringStripWS($name, $STR_STRIPTRAILING)
			If StringInStr($name, ', The') Then
			   $name = 'The ' & StringReplace($name, ', The', '')
			EndIf

			$destdir = $targetDir & '\' & $name & '\'
			DirCreate($destdir)
			FileMove($targetDir & '\' & $file, $destdir)
		 EndIf
	  Next
   EndIf

   $titles = _FileListToArray($targetDir, '*', $FLTA_FOLDERS)
   For $t = 1 To $titles[0]
	  $title = $titles[$t]
	  ConsoleWrite($t & ' of ' & $titles[0] & ': ' & $title & @CRLF)
	  ImportROM($title)
   Next
EndFunc

Func ImportROM($title)
   $destdir = $targetDir & '\' & $title & '\'

   ConsoleWrite('GetExtras' & @CRLF)
   _RunWait('tools\scraper.exe -console_img l,a,b -image_dir label', $destdir)
   _RunWait('tools\scraper.exe -console_img b -image_dir box', $destdir)

   Local $data = _RunWait('tools\nsrt.exe -infocsv "*.s?c"', $destdir)
   Local $csv = _CSVRead($data)
   Local $i, $j
   For $i=1 To UBound($csv) - 1
	  $file =  $csv[$i][0]
	  $company =  $csv[$i][2]
	  $code =  StringStripWS($csv[$i][14], $STR_STRIPLEADING + $STR_STRIPTRAILING)
	  $hash =  $csv[$i][15]
	  $name =  $csv[$i][16]
	  If $name == 'Not found in Database' Then
		 $name = $title
	  EndIf
	  If StringInStr($name, ', The') Then
		 $name = 'The ' & StringReplace($name, ', The', '')
	  EndIf
	  If StringLen($name) > 36 Then
		 ConsoleWrite('*** Name longer than 36 characters: ' & $name & @CRLF)
	  EndIf
	  $region =  $csv[$i][9]
	  $serial = GetSerial($hash, $region)
	  If $serial == $hash Then
		 ConsoleWrite('*** Media serial not found: ' & $name & @CRLF)
	  EndIf

	  FileDelete($destdir & 'label.*')
	  FileDelete($destdir & 'banner.*')
	  FileDelete($destdir & 'icon.*')

	  ;; Copy images
	  $basename = StringTrimRight($file, 4)
	  FileCopy($destdir & '\label\' & $basename & '-image.jpg', $destdir & 'label.jpg', $FC_OVERWRITE)
	  if FileExists('data\snes\title\' & $hash & '.png') Then
		 FileCopy('data\snes\title\' & $hash & '.png', $destdir & 'banner.png', $FC_OVERWRITE)
		 FileCopy('data\snes\title\' & $hash & '.png', $destdir & 'icon.png', $FC_OVERWRITE)
	  Else
		 FileCopy($destdir & '\box\' & $basename & '-image.jpg', $destdir & 'banner.jpg', $FC_OVERWRITE)
		 FileCopy($destdir & '\box\' & $basename & '-image.jpg', $destdir & 'icon.jpg', $FC_OVERWRITE)
	  EndIf

	  ;; Parse gamelist.xml
	  $release = GetReleaseDate($file, $destdir)

	  ;; Write info.txt
	  $info = $destdir & 'info.txt'
	  FileDelete($info)
	  FileWriteLine($info,'title=' & $name)
	  FileWriteLine($info,'long=' & $name)
	  FileWriteLine($info,'author=' & $company)
	  FileWriteLine($info,'release=' & $release)
	  FileWriteLine($info,'id=' & $hash)
	  FileWriteLine($info,'serial=' & $serial)
   Next
EndFunc
