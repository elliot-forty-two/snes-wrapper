
#include <Constants.au3>
#include <String.au3>
#include <Math.au3>
#include <File.au3>
#include 'lib/Json.au3'
#include 'lib/Curl.au3'
#include 'lib/Request.au3'
#include 'lib/LibCsv2.au3'
#include 'lib/_XMLDomWrapper.au3'
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

Func GetSerial($crc32, $region = 'USA')
   Local $serial = $crc32
   Local $dataDir = 'game-data\'
   DirCreate($dataDir)

   Local $datomaticCsv = $dataDir & 'datomatic.csv'
   If Not FileExists($datomaticCsv) Then
	  Local $data = Request('https://github.com/elliot-forty-two/game-data/raw/master/snes/datomatic.csv')
	  FileWrite($datomaticCsv, $data)
   EndIf

   If FileExists($datomaticCsv) Then
	  Local $csv = _CSVReadFile($datomaticCsv)
	  For $i=1 To UBound($csv) - 1
		 If $crc32 == $csv[$i][6] Then
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
   ConsoleWrite('Clean ROMs' & @CRLF)
   _RunWait('tools\nsrt.exe -savetype uncompressed -remhead -rename -lowext -noext "*"', $targetDir)
EndFunc

Func ImportROMs()
   ConsoleWrite('Import ROMs' & @CRLF)

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

Func GetExtras($title, $crc32, $sha1)
   ConsoleWrite('GetExtras' & @CRLF)

   Local $destdir = $targetDir & '\' & $title & '\'
   DirCreate($destdir)
   Local $dataDir = 'game-data\'
   DirCreate($dataDir)

   Local $hashesCsv = $dataDir & 'thegamesdb-hashes.csv'
   If Not FileExists($hashesCsv) Then
	  Local $data = Request('https://github.com/elliot-forty-two/game-data/raw/master/snes/thegamesdb-hashes.csv')
	  FileWrite($hashesCsv, $data)
   EndIf
   Local $csv = _CSVReadFile($hashesCsv)
   Local $gameId
   For $i=1 To UBound($csv) - 1
	  If $sha1 == $csv[$i][0] Then
		 $gameId =  $csv[$i][1]
	  EndIf
   Next
   Local $xmlData = Request('http://thegamesdb.net/api/GetGame.php?id=' & $gameId)
   FileDelete($destdir & 'info.xml')
   FileWrite($destdir & 'info.xml', $xmlData)

   Local $xmlFile = _XMLFileOpen($destdir & 'info.xml')

   Local $release
   Local $nodes = _XMLGetValue('//ReleaseDate')
   For $i = 1 To $nodes[0]
	  $release = StringRight($nodes[$i], 4)
   Next

   Local $baseImgUrl, $logoSrc
   Local $nodes = _XMLGetValue('//baseImgUrl')
   For $i = 1 To $nodes[0]
	  $baseImgUrl = $nodes[$i]
   Next
   Local $nodes = _XMLGetValue('//clearlogo')
   For $i = 1 To $nodes[0]
	  $logoSrc = $nodes[$i]
   Next
   Local $logoData = Request($baseImgUrl & $logoSrc)
   FileDelete($destdir & 'label.png')
   FileWrite($destdir & 'label.png', $logoData)

   Local $snapData = Request('https://raw.githubusercontent.com/elliot-forty-two/game-data/master/snes/snap/' & $crc32 & '.png')
   FileDelete($destdir & 'banner.png')
   FileWrite($destdir & 'banner.png', $snapData)

   Local $titleData = Request('https://raw.githubusercontent.com/elliot-forty-two/game-data/master/snes/title/' & $crc32 & '.png')
   FileDelete($destdir & 'icon.png')
   FileWrite($destdir & 'icon.png', $titleData)

   Return $release
EndFunc

Func ImportROM($title)
   Local $destdir = $targetDir & '\' & $title & '\'
   Local $data = _RunWait('tools\nsrt.exe -hashes -infocsv "*.s?c"', $destdir)
   Local $csv = _CSVRead($data)
   For $i=1 To UBound($csv) - 1
	  $file =  $csv[$i][0]
	  $company =  $csv[$i][2]
	  $region =  $csv[$i][9]
	  $code =  StringStripWS($csv[$i][14], $STR_STRIPLEADING + $STR_STRIPTRAILING)
	  $crc32 =  $csv[$i][15]
	  $sha1 =  StringLower($csv[$i][18])

	  $name =  $csv[$i][23]
	  If $name == 'Not found in Database' Then
		 $name = $title
	  EndIf
	  If StringInStr($name, ', The') Then
		 $name = 'The ' & StringReplace($name, ', The', '')
	  EndIf
	  If StringLen($name) > 36 Then
		 ConsoleWrite('*** Name longer than 36 characters: ' & $name & @CRLF)
	  EndIf

	  $serial = GetSerial($crc32, $region)
	  If $serial == $crc32 Then
		 ConsoleWrite('*** Media serial not found: ' & $name & @CRLF)
	  EndIf

	  ;;
	  FileDelete($destdir & 'label.*')
	  FileDelete($destdir & 'banner.*')
	  FileDelete($destdir & 'icon.*')
	  $release = GetExtras($title, $crc32, $sha1)

	  ;; Write info.txt
	  $info = $destdir & 'info.txt'
	  FileDelete($info)
	  FileWriteLine($info,'title=' & $name)
	  FileWriteLine($info,'long=' & $name)
	  FileWriteLine($info,'author=' & $company)
	  FileWriteLine($info,'release=' & $release)
	  FileWriteLine($info,'id=' & $crc32)
	  FileWriteLine($info,'serial=' & $serial)
   Next
EndFunc
