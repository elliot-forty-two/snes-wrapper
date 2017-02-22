
#include-once

#include <File.au3>
#include '../lib/WinHttp.au3'
#include '../options.au3'
#include '../functions.au3'

Func _SS_OpenInfoXml($title, $crc32, $sha1, $md5, $file)
   If Not FileExists(_GetInput($title) & 'ssinfo.xml') Then
	  _LogProgress('Get ssinfo.xml ...')
	  Local $url = 'https://www.screenscraper.fr/api/jeuInfos.php?output=xml' _
		 & '&devid=' & $ssDevId _
		 & '&devpassword=' & $ssDevPassword _
		 & '&ssid=' & $ssUserId _
		 & '&sspassword=' & $ssPassword _
		 & '&systemeid=4&romtype=rom' _
		 & '&crc=' & $crc32 _
		 & '&md5=' & $md5 _
		 & '&sha1=' & $sha1 ;_
;~ 		 & '&romnom=' & $file
	  _LogVerbose('Request: ' & $url)
	  Local $xmlData = HttpGet($url)
	  Local $result = @error
	  Local $status = @extended
	  If $result == 0 And StringLeft($xmlData, 5) == '<?xml' Then
		 FileDelete(_GetInput($title) & 'ssinfo.xml')
		 FileWrite(_GetInput($title) & 'ssinfo.xml', $xmlData)
	  Else
		 _LogError('HTTP status ' & $status & ': ' & $xmlData)
	  EndIf
   EndIf

   Return _XMLFileOpen(_GetInput($title) & 'ssinfo.xml')
EndFunc

Func _SS_GetRegions($title, $crc32, $sha1, $md5, $file)
   Local $regions[4] = ['', 'us', 'eu', 'jp']
   Local $nodes = _XMLGetValue('//rom[romcrc/text()="' & $crc32 & '"]/romregions/text()')
   If @error == 0 Then
	  $regions[0] = StringSplit($nodes[1], ',')[1]
   EndIf
   Return $regions
EndFunc

Func _SS_GetLabelImage($title, $crc32, $sha1, $md5, $file)
   DirCreate(_GetInput($title))

   ;; Label image
   _FileListToArray(_GetInput($title), 'label.*', $FLTA_FILES)
   If @error <> 0 Then
	  _LogProgress('Get label image ...')

	  _SS_OpenInfoXml($title, $crc32, $sha1, $md5, $file)

	  ;; Region
	  Local $regions = _SS_GetRegions($title, $crc32, $sha1, $md5, $file)

	  Local $imgSrc = ''
	  For $i = 0 To UBound($regions) - 1
		 Local $nodes = _XMLGetValue('//media_supporttexture_' & $regions[$i])
		 If @error == 0 Then
			$imgSrc = $nodes[1]
			ExitLoop
		 EndIf
	  Next
	  If $imgSrc == '' Then
		 For $i = 0 To UBound($regions) - 1
			Local $nodes = _XMLGetValue('//media_wheel_' & $regions[$i])
			If @error == 0 Then
			   $imgSrc = $nodes[1]
			   ExitLoop
			EndIf
		 Next
	  EndIf

	  If ($imgSrc) Then
		 _LogVerbose('Request: ' & $imgSrc)
		 Local $labelData = HttpGetBinary($imgSrc)
		 Local $ext = StringRight($imgSrc, 3)
		 FileDelete(_GetInput($title) & 'label.' & $ext)
		 FileWrite(_GetInput($title) & 'label.' & $ext, $labelData)
	  Else
		 _LogError('Label image not found')
	  EndIf
   EndIf
EndFunc

Func _SS_GetTitleImage($title, $crc32, $sha1, $md5, $file)
   DirCreate(_GetInput($title))

   Local $getBanner = _FileExists(_GetInput($title), 'banner.*', $FLTA_FILES)
   Local $getIcon = _FileExists(_GetInput($title), 'icon.*', $FLTA_FILES)

   If $getBanner Or $getIcon Then
	  _LogProgress('Get title image ...')

	  _SS_OpenInfoXml($title, $crc32, $sha1, $md5, $file)

	  ;; Region
	  Local $regions = _SS_GetRegions($title, $crc32, $sha1, $md5, $file)

	  ;; Try ScreenScraper
	  Local $imgSrc = ''
	  Local $nodes = _XMLGetValue('//media_screenshot')
	  If @error == 0 Then
;~ 			$imgSrc = $nodes[1]
	  EndIf
	  If $imgSrc == '' Then
		 For $i = 0 To UBound($regions) - 1
			Local $nodes = _XMLGetValue('//media_box2d_' & $regions[$i])
			If @error == 0 Then
			   $imgSrc = $nodes[1]
			   ExitLoop
			EndIf
		 Next
	  EndIf

	  If ($imgSrc) Then
		 _LogVerbose('Request: ' & $imgSrc)
		 Local $imgData = HttpGetBinary($imgSrc)
		 If $getBanner Then
			FileDelete(_GetInput($title) & 'banner.png')
			FileWrite(_GetInput($title) & 'banner.png', $imgData)
		 EndIf
		 If $getIcon Then
			FileDelete(_GetInput($title) & 'icon.png')
			FileWrite(_GetInput($title) & 'icon.png', $imgData)
		 EndIf
	  Else
		 _LogError('Screen image not found')
	  EndIf
   EndIf
EndFunc

Func _SS_GetGameRelease($title, $crc32, $sha1, $md5, $file)
   _SS_OpenInfoXml($title, $crc32, $sha1, $md5, $file)

   ;; Region
   Local $regions = _SS_GetRegions($title, $crc32, $sha1, $md5, $file)
   For $i = 0 To UBound($regions) - 1
	  Local $nodes = _XMLGetValue('//date_' & $regions[$i])
	  If @error == 0 Then
		 Return StringLeft($nodes[1], 4)
	  EndIf
   Next
EndFunc
