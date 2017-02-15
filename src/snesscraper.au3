
#include <Constants.au3>
#include <String.au3>
#include <Math.au3>
#include <File.au3>
#include 'lib/GetOpt.au3'
#include 'lib/Json.au3'
#include 'lib/Curl.au3'
#include 'lib/Request.au3'
#include 'lib/LibCsv2.au3'
#include 'lib/_XMLDomWrapper.au3'
#include 'functions.au3'

Global $dataDir = 'game-data\'
Global $datomaticCsv = $dataDir & 'datomatic.csv'
Global $hashesCsv = $dataDir & 'thegamesdb-hashes.csv'

If @ScriptName == 'snesscraper.au3' Or @ScriptName == 'snesscraper.exe' Then
   ConsoleWrite("SNES Scraper - SNES VC for Old 3DS" & @CRLF & @CRLF)
   _ParseOpts()

   If Not FileExists(_GetInput()) Then
	  _Error('ERROR: Folder not found: ' & _GetInput() & @CRLF)
	  Exit 1
   EndIf

   UpdateGameData()

   ConsoleWrite('Clean ROMs' & @CRLF)
   _RunWait('tools\nsrt.exe -savetype uncompressed -remhead -rename -lowext -noext "*"', _GetInput())

   ImportROMs()
EndIf

Func UpdateGameData()
   DirCreate($dataDir)

   If Not FileExists($datomaticCsv) Then
	  Local $data = Request('https://github.com/elliot-forty-two/game-data/raw/master/snes/datomatic.csv')
	  FileWrite($datomaticCsv, $data)
   EndIf

   If Not FileExists($hashesCsv) Then
	  Local $data = Request('https://github.com/elliot-forty-two/game-data/raw/master/snes/thegamesdb-hashes.csv')
	  FileWrite($hashesCsv, $data)
   EndIf
EndFunc

Func GetSerial($crc32, $region = 'USA')
   Local $serial = $crc32

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

Func ImportROMs()
   ConsoleWrite('Import ROMs' & @CRLF)

   Local $file
   $files = _FileListToArray(_GetInput(), '*.s?c', $FLTA_FILES)
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

			DirCreate(_GetInput($name))
			FileMove(_GetInput() & '\' & $file, _GetInput($name))
		 EndIf
	  Next
   EndIf

   $titles = _FileListToArray(_GetInput(), '*', $FLTA_FOLDERS)
   For $t = 1 To $titles[0]
	  $title = $titles[$t]
	  ConsoleWrite($t & ' of ' & $titles[0] & ': ' & $title & @CRLF)
	  ImportROM($title)
   Next
EndFunc

Func OpenInfoXml($title, $sha1)
   _FileListToArray(_GetInput($title), 'info.xml', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Get info.xml...')
	  Local $csv = _CSVReadFile($hashesCsv)
	  Local $gameId
	  For $i=1 To UBound($csv) - 1
		 If $sha1 == $csv[$i][0] Then
			$gameId =  $csv[$i][1]
		 EndIf
	  Next
	  Local $xmlData = Request('http://thegamesdb.net/api/GetGame.php?id=' & $gameId)
	  FileDelete(_GetInput($title) & 'info.xml')
	  FileWrite(_GetInput($title) & 'info.xml', $xmlData)
   EndIf

   Return _XMLFileOpen(_GetInput($title) & 'info.xml')
EndFunc

Func GetGameImages($title, $crc32, $sha1)
   DirCreate(_GetInput($title))
   OpenInfoXml($title, $sha1)

   _FileListToArray(_GetInput($title), 'label.*', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Get label image...')
	  Local $baseImgUrl, $logoSrc, $bannerSrc, $boxartSrc
	  Local $nodes = _XMLGetValue('//baseImgUrl')
	  If @error == 0 Then
		 $baseImgUrl = $nodes[1]
	  EndIf
	  Local $nodes = _XMLGetValue('//clearlogo')
	  If @error == 0 Then
		 $logoSrc = $nodes[1]
	  EndIf
	  Local $nodes = _XMLGetValue('//banner')
	  If @error == 0 Then
		 $bannerSrc = $nodes[1]
	  EndIf
	  Local $nodes = _XMLGetValue('//boxart[@side="front"]')
	  If @error == 0 Then
		 $boxartSrc = $nodes[1]
	  EndIf

	  If $baseImgUrl And ($logoSrc Or $bannerSrc Or $boxartSrc) Then
		 Local $src
		 If $logoSrc Then
			$src = $logoSrc
		 ElseIf $bannerSrc Then
			$src = $bannerSrc
		 ElseIf $boxartSrc Then
			$src = $boxartSrc
		 EndIf
		 Local $labelData = Request($baseImgUrl & $src)
		 Local $ext = StringRight($src, 4)
		 FileDelete(_GetInput($title) & 'label' & $ext)
		 FileWrite(_GetInput($title) & 'label' & $ext, $labelData)
	  Else
		 ConsoleWriteError('ERROR: No logo found' & @CRLF)
	  EndIf
   EndIf

   _FileListToArray(_GetInput($title), 'banner.*', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Get banner image...')
	  Local $snapData = Request('https://raw.githubusercontent.com/elliot-forty-two/game-data/master/snes/snap/' & $crc32 & '.png')
	  FileDelete(_GetInput($title) & 'banner.png')
	  FileWrite(_GetInput($title) & 'banner.png', $snapData)
   EndIf

   _FileListToArray(_GetInput($title), 'icon.*', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Get icon image...')
	  Local $titleData = Request('https://raw.githubusercontent.com/elliot-forty-two/game-data/master/snes/title/' & $crc32 & '.png')
	  FileDelete(_GetInput($title) & 'icon.png')
	  FileWrite(_GetInput($title) & 'icon.png', $titleData)
   EndIf
EndFunc

Func GetGameRelease($title, $sha1)
   _LogProgress('Get release year...')
   OpenInfoXml($title, $sha1)
   Return StringRight(_XMLGetFirstValue('//ReleaseDate'), 4)
EndFunc

Func ImportROM($title)
   If $optClean Then
	  FileDelete(_GetInput($title) & 'rominfo.xml')
	  FileDelete(_GetInput($title) & 'info.xml')
	  FileDelete(_GetInput($title) & 'label.*')
	  FileDelete(_GetInput($title) & 'banner.*')
	  FileDelete(_GetInput($title) & 'icon.*')
   EndIf

   _FileListToArray(_GetInput($title), 'rominfo.xml', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Generate rominfo.xml...')
	  Local $xmlData = _RunWait('tools\nsrt.exe -hashes -infoxml "*.s?c"', _GetInput($title))
	  FileDelete(_GetInput($title) & 'rominfo.xml')
	  FileWrite(_GetInput($title) & 'rominfo.xml', $xmlData)
   EndIf
   _XMLFileOpen(_GetInput($title) & 'rominfo.xml')

   $file = _XMLGetFirstValue('//File')
   $company = _XMLGetFirstValue('//Company')
   $region = _XMLGetFirstValue('//Country')
   $code =  StringStripWS(_XMLGetFirstValue('//GameCode'), $STR_STRIPLEADING + $STR_STRIPTRAILING)
   $crc32 = _XMLGetFirstValue('//Section[@type="Hashes"]/CRC32')
   $sha1 = StringLower(_XMLGetFirstValue('//Section[@type="Hashes"]/SHA-1'))

   $name = _XMLGetFirstValue('//Section[@type="Database"]/Name')
   If $name == 'Not found in Database' Then
	  $name = $title
   EndIf
   If StringInStr($name, ', The') Then
	  $name = 'The ' & StringReplace($name, ', The', '')
   EndIf
   $name = StringReplace($name, ' - ', ': ')
   $long = $name

   $serial = GetSerial($crc32, $region)
   If $serial == $crc32 Then
	  ConsoleWrite('WARNING: Media serial not found' & @CRLF)
   EndIf

   ;; Game images
   GetGameImages($title, $crc32, $sha1)

   ;; Release year
   $release = GetGameRelease($title, $sha1)

   ;; Write info.txt
   $info = _GetInput($title) & 'info.txt'
   FileDelete($info)
   FileWriteLine($info,'title=' & $name)
   FileWriteLine($info,'long=' & $long)
   FileWriteLine($info,'author=' & $company)
   FileWriteLine($info,'release=' & $release)
   FileWriteLine($info,'id=' & $crc32)
   FileWriteLine($info,'serial=' & $serial)

_LogProgress('Done')
EndFunc

Func _ParseOpts()
   Local $sMsg
   Local $sOpt, $sOper
   Local $aOpts[5][3] = [ _
	  ['-c', '--clean', True], _
	  ['-v', '--verbose', True], _
	  ['-h', '--help', True] _
   ]
   _GetOpt_Set($aOpts)
   If 0 < $GetOpt_Opts[0] Then
	  While 1
		 $sOpt = _GetOpt('cvh')
		 If Not $sOpt Then ExitLoop
		 Switch $sOpt
		 Case '?'
			ConsoleWrite('Unknown option ' & $GetOpt_Opt & @CRLF & @CRLF)
			_Help()
		 Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
		 Case 'c'
			$optClean = $GetOpt_Arg
		 Case 'v'
			$optVerbose = $GetOpt_Arg
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
   ConsoleWrite('Usage: ' & @ScriptName & ' [-h] [-c] [<folder>]' & @CRLF)
   ConsoleWrite(@TAB & '-h --help' & @TAB & 'Show this help message' & @CRLF)
   ConsoleWrite(@TAB & '-c --clean' & @TAB & 'Recreate output' & @CRLF)
   ConsoleWrite(@TAB & '<folder>' & @TAB & 'Set the working folder where "input" folder resides' & @CRLF)
   Exit
EndFunc
