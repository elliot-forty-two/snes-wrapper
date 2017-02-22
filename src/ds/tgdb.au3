
#include-once

#include <File.au3>
#include '../lib/LibCsv2.au3'
#include '../lib/WinHttp.au3'
#include '../options.au3'
#include '../functions.au3'

Global $dataDir = 'game-data\'
Global $hashesCsv = $dataDir & 'thegamesdb-hashes.csv'
Global $tgdbInfoXml = 'tgdbinfo.xml'

Func _TGDB_OpenInfoXml($title, $sha1)
   If Not FileExists(_GetInput($title) & $tgdbInfoXml) Then
	  _LogProgress('Get ' & $tgdbInfoXml & ' ...')

	  If Not FileExists($hashesCsv) Then
		 Local $data = HttpGet('https://github.com/elliot-forty-two/game-data/raw/master/snes/thegamesdb-hashes.csv')
		 FileWrite($hashesCsv, $data)
	  EndIf

	  Local $csv = _CSVReadFile($hashesCsv)
	  Local $gameId
	  For $i=1 To UBound($csv) - 1
		 If StringLower($sha1) == StringLower($csv[$i][0]) Then
			$gameId =  $csv[$i][1]
		 EndIf
	  Next

	  Local $url = 'http://thegamesdb.net/api/GetGame.php?id=' & $gameId
	  _LogVerbose('Request: ' & $url)

	  Local $xmlData = HttpGet($url)
	  FileDelete(_GetInput($title) & $tgdbInfoXml)
	  FileWrite(_GetInput($title) & $tgdbInfoXml, $xmlData)
   EndIf

   Return _XMLFileOpen(_GetInput($title) & $tgdbInfoXml)
EndFunc

Func _TGDB_GetLabelImage($title, $crc32, $sha1)
   _FileListToArray(_GetInput($title), 'label.*', $FLTA_FILES)
   If @error <> 0 Then
	  DirCreate(_GetInput($title))
	  _TGDB_OpenInfoXml($title, $sha1)

	  _LogProgress('Get label image ...')
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
		 _LogVerbose('Request: ' & $baseImgUrl & $src)
		 Local $labelData = HttpGetBinary($baseImgUrl & $src)
		 Local $ext = StringRight($src, 4)
		 FileDelete(_GetInput($title) & 'label' & $ext)
		 FileWrite(_GetInput($title) & 'label' & $ext, $labelData)
	  Else
		 _LogError('Label image not found')
	  EndIf
   EndIf
EndFunc

Func _TGDB_GetGameRelease($title, $sha1)
   _TGDB_OpenInfoXml($title, $sha1)
   Return StringRight(_XMLGetFirstValue('//ReleaseDate'), 4)
EndFunc

