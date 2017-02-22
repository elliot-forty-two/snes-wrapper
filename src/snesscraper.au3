
#NoTrayIcon

#include <File.au3>
#include 'lib/GetOpt.au3'
#include 'lib/LibCsv2.au3'
#include 'lib/_XMLDomWrapper.au3'
#include 'lib/WinHttp.au3'
#include 'lib/CRC.au3'
#include 'lib/MD5.au3'
#include 'lib/SHA1.au3'
#include 'ds/ss.au3'
#include 'ds/tgdb.au3'
#include 'ds/e42.au3'
#include 'options.au3'
#include 'functions.au3'

If @ScriptName == 'snesscraper.au3' Or @ScriptName == 'snesscraper.exe' Then
   Global $dataDir = 'game-data\'
   Global $datomaticCsv = $dataDir & 'datomatic.csv'

   _LogMessage("SNES Scraper - SNES VC for Old 3DS" & @CRLF)
   ParseOpts()

   If Not FileExists(_GetInput()) Then
	  _LogError('Folder not found: ' & _GetInput())
	  Exit 1
   EndIf

   UpdateGameData()

   ScrapeFiles()
EndIf

Func UpdateGameData()
   DirCreate($dataDir)

   If Not FileExists($datomaticCsv) Then
	  Local $data = HttpGet('https://github.com/elliot-forty-two/game-data/raw/master/snes/datomatic.csv')
	  FileWrite($datomaticCsv, $data)
   EndIf
EndFunc

Func GetGameSerial($crc32, $region = 'USA')
   UpdateGameData()
   Local $serial = Null
   If FileExists($datomaticCsv) Then
	  Local $csv = _CSVReadFile($datomaticCsv)
	  For $i=1 To UBound($csv) - 1
		 If StringLower($crc32) == StringLower($csv[$i][6]) Then
			$serial = $csv[$i][1]
			If StringLower($region) == StringLower($csv[$i][2]) And Not StringLower($serial) == 'unk' Then
			   Return $serial
			EndIf
		 EndIf
	  Next
   EndIf
   Return $serial
EndFunc

Func CreateSerialFromCode($code, $country, $video)
   Switch $country
   Case "USA"
	  Return 'SNS-' & $code & '-USA'
   Case "Japan"
	  Return 'SHVC-' & $code
   Case "Germ/Aust/Switz"
	  Return 'SNSP-' & $code & '-FRG'
   Case "Euro/Asia/Oceania"
	  Return 'SNSP-' & $code & '-EUR'
   Case "France"
	  Return 'SNSP-' & $code & '-FRA'
   Case "Italy"
	  Return 'SNSP-' & $code & '-ITA'
   Case "Spain"
	  Return 'SNSP-' & $code & '-ESP'
   Case "Sweden"
   Case "Finland"
	  Return 'SNSP-' & $code & '-SCN'
   Case "The Netherlands"
	  Return 'SNSP-' & $code & '-HOL'
   Case "South Korea"
	  Return 'SNSP-' & $code & '-KOR'
   Case "Honk Kong/China"
	  Return 'SNSP-' & $code & '-HKV'
   Case "Unknown"
   Case Else
	  Switch $video
	  Case 'NTSC'
		 Return 'SNS-' & $code
	  Case 'PAL'
		 Return 'SNSP-' & $code
	  EndSwitch
   EndSwitch
   Return Null
EndFunc

Func ScrapeFiles()
   _LogMessage('Scraping files')

   Local $file
   $files = _FileListToArrayRec(_GetInput(), '*.s?c', $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)
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

   $titles = _FileListToArrayRec(_GetInput(), '*', $FLTAR_FOLDERS, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)

   If $optClean Then
	  For $t = 1 To $titles[0]
		 $title = StringReplace($titles[$t], '\', '')
		 _LogProgress('Cleaning: ' & $title)
		 FileDelete(_GetInput($title) & 'info.txt')
		 FileDelete(_GetInput($title) & 'rominfo.xml')
		 FileDelete(_GetInput($title) & 'ssinfo.xml')
		 FileDelete(_GetInput($title) & 'tgdbinfo.xml')
		 FileDelete(_GetInput($title) & 'label.*')
		 FileDelete(_GetInput($title) & 'banner.*')
		 FileDelete(_GetInput($title) & 'icon.*')
	  Next
   EndIf

   For $t = 1 To $titles[0]
	  $title = StringReplace($titles[$t], '\', '')
	  _LogVerbose('')
	  _LogMessage($t & ' of ' & $titles[0] & ': ' & $title)
	  ImportROM($title)
   Next
EndFunc

Func ImportROM($title)
   If Not FileExists(_GetInput($title) & 'rominfo.xml') Then
	  _LogProgress('Get rominfo.xml ...')
	  Local $xmlData = _RunWait('tools\nsrt.exe -infoxml "*.s?c"', _GetInput($title))
	  FileDelete(_GetInput($title) & 'rominfo.xml')
	  FileWrite(_GetInput($title) & 'rominfo.xml', $xmlData)
   EndIf
   _XMLFileOpen(_GetInput($title) & 'rominfo.xml')

   $file = _XMLGetFirstValue('//File')
   $company = _XMLGetFirstValue('//Company')
   $region = _XMLGetFirstValue('//Country')
   $video = _XMLGetFirstValue('//Video')
   $code =  StringStripWS(_XMLGetFirstValue('//GameCode'), $STR_STRIPLEADING + $STR_STRIPTRAILING)

   ;; Hashes
   $filePath = _GetInput($title) & $file
   $fileSize = FileGetSize($filePath)
   $fHandle = FileOpen($filePath, $FO_BINARY)
   If Mod($fileSize, 1024) <> 0 Then
	  ;; Skip header
	  FileSetPos($fHandle, 512, $FILE_BEGIN)
   EndIf
   $data = FileRead($fHandle)
   $crc32 = Hex(_CRC32($data), 8)
   $sha1 = StringTrimLeft(_SHA1($data), 2)
   $md5 = StringTrimLeft(_MD5($data), 2)

   ;; Name
   $name = _XMLGetFirstValue('//Section[@type="Database"]/Name')
   If $name == '' Or $name == 0 Then
	  $name = $title
   EndIf

   If StringInStr($name, ', The') Then
	  $name = 'The ' & StringReplace($name, ', The', '')
   EndIf
   If StringInStr($name, ', An') Then
	  $name = 'An ' & StringReplace($name, ', An', '')
   EndIf
   $name = StringReplace($name, ' - ', ': ')

   Local $short = $name
   If StringLen($short) > 32 Then
	  ;; Try just the sub-title
	  If StringInStr($short, ': ') Then
		 Local $arr = StringSplit($short, ': ', $STR_ENTIRESPLIT)
		 $short = $arr[$arr[0]]
	  EndIf
	  ;; Try removing duplicate words
	  If StringLen($short) > 32 Then
		 Local $c = 0
		 For $s In StringSplit($short, ' ')
			$c += StringLen($s) + 1
			If StringLen($s) > 3 And StringInStr($short, $s, 0, 1, $c) Then
			   $short = StringReplace($short, ' ' & $s, '', -1)
			EndIf
		 Next
	  EndIf
	  ;; Try removing on 'The '
	  If StringLen($short) > 32 And StringLeft($short, 4) == 'The ' Then
		 $short = StringMid($short, 4)
	  EndIf

	  If StringLen($short) <= 32 Then
		 _LogMessage('Short name: ' & $short)
	  EndIf
   EndIf
   If StringLen($short) > 32 Then
	  $short = StringLeft($short, 31) & '…'
	  _LogMessage('Short name: ' & $short)
   EndIf

   Local $long = $name
   If StringLen($long) > 64 Then
	  _LogWarning('Long name greater than 64 characters')
   EndIf

   Local $serial = GetGameSerial($crc32, $region)
   If Not $serial Then
	  _LogMessage('Creating serial from game code')
	  $serial = CreateSerialFromCode($code, $region, $video)
   EndIf
   If Not $serial Then
	  _LogWarning('Media serial not found')
	  $serial = $crc32
   EndIf

   ;; Game images
   _SS_GetLabelImage($title, $crc32, $sha1, $md5, $file)
   _TGDB_GetLabelImage($title, $crc32, $sha1)
   _E42_GetTitleImage($title, $crc32, $sha1, $md5, $file)
   _SS_GetTitleImage($title, $crc32, $sha1, $md5, $file)

   ;; Release year
   $release = _SS_GetGameRelease($title, $crc32, $sha1, $md5, $file)
   If $release == '' Or $release == 0 Then
	  $release = _TGDB_GetGameRelease($title, $sha1)
   EndIf
   If $release == '' Or $release == 0 Then
	  _LogWarning('Release year not found')
   EndIf

   ;; Write info.txt
   $info = _GetInput($title) & 'info.txt'
   FileDelete($info)
   FileWriteLine($info,'short=' & $short)
   FileWriteLine($info,'long=' & $long)
   FileWriteLine($info,'author=' & $company)
   FileWriteLine($info,'release=' & $release)
   FileWriteLine($info,'id=' & $crc32)
   FileWriteLine($info,'serial=' & $serial)

   _LogProgress('Done')
EndFunc

Func ParseOpts()
   Local $sMsg
   Local $sOpt, $sOper
   Local $aOpts[5][3] = [ _
	  ['-c', '--clean', True], _
	  ['-v', '--verbose', True], _
	  ['-u', '--userid', True], _
	  ['-p', '--password', True], _
	  ['-h', '--help', True] _
   ]
   _GetOpt_Set($aOpts)
   If 0 < $GetOpt_Opts[0] Then
	  While 1
		 $sOpt = _GetOpt('cvu:p:h')
		 If Not $sOpt Then ExitLoop
		 Switch $sOpt
		 Case '?'
			_LogMessage('Unknown option: ' & $GetOpt_Opt & @CRLF)
			Help()
		 Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
		 Case 'c'
			$optClean = $GetOpt_Arg
		 Case 'v'
			$optVerbose = $GetOpt_Arg
		 Case 'u'
			$ssUserid = $GetOpt_Arg
		 Case 'p'
			$ssPassword = $GetOpt_Arg
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
   _LogMessage('Usage: ' & @ScriptName & ' [-h] [-c] [-v] [-u=<userid> -p=<password>] [<folder>]')
   _LogMessage(@TAB & '-h --help' & @TAB & 'Show this help message')
   _LogMessage(@TAB & '-c --clean' & @TAB & 'Recreate output')
   _LogMessage(@TAB & '-v --verbose' & @TAB & 'Verbose output')
   _LogMessage(@TAB & '-u --userid' & @TAB & 'ScreenScraper userid')
   _LogMessage(@TAB & '-p --password' & @TAB & 'ScreenScraper password')
   _LogMessage(@TAB & '<folder>' & @TAB & 'Set the working folder where "input" folder resides')
   Exit
EndFunc
