
#include-once

#include <File.au3>
#include '../lib/WinHttp.au3'
#include '../options.au3'
#include '../functions.au3'

Func _E42_GetTitleImage($title, $crc32, $sha1, $md5, $file)
   DirCreate(_GetInput($title))

   Local $getBanner = _FileExists(_GetInput($title), 'banner.*', $FLTA_FILES)
   Local $getIcon = _FileExists(_GetInput($title), 'icon.*', $FLTA_FILES)

   If $getBanner Or $getIcon Then
	  _LogProgress('Get title image ...')

	  Local $url = 'https://raw.githubusercontent.com/elliot-forty-two/game-data/master/snes/title/' & $crc32 & '.png'
	  _LogVerbose('Request: ' & $url)

	  Local $titleData = HttpGetBinary($url)
	  If @error == 0 Then
		 If $getBanner Then
			FileDelete(_GetInput($title) & 'banner.png')
			FileWrite(_GetInput($title) & 'banner.png', $titleData)
		 EndIf
		 If $getIcon Then
			FileDelete(_GetInput($title) & 'icon.png')
			FileWrite(_GetInput($title) & 'icon.png', $titleData)
		 EndIf
	  Else
		 _LogError('Screen image not found')
	  EndIf
   EndIf
EndFunc
