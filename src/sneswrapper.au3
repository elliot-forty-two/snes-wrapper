
#include "functions.au3"
#include "wrapper.au3"

If @ScriptName == 'sneswrapper.au3' Or @ScriptName == 'sneswrapper.exe' Then
   ConsoleWrite("OldSNES -- SNES VC for Old 3DS users" & @CRLF)

   ConsoleWrite("Currently using: Snes9x for 3DS" & @CRLF)

   Global $emuelf = "snes9x_3ds.elf"
   ;~ Global $emuelf = "blargSnes.elf"

   $titles = _FileListToArray("input", "*", $FLTA_FOLDERS)
   For $t = 1 To $titles[0]
	  $title = $titles[$t]
	  ConsoleWrite($t & " of " & $titles[0] & ": " & $title & @CRLF)
	  ProcessTitle($title)
   Next
EndIf
