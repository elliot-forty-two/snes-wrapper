
#include-once

Global $optClean = False
Global $optUpdate = False
Global $optVerbose = False
Global $optEmulator = "snes9x_3ds.elf"
Global $optFolder = @WorkingDir

Func _GetInput($title = '')
   Local $ret = ''
   If StringLen($optFolder) > 0 Then
	  $ret &= $optFolder & '\'
   EndIf
   $ret &= 'input\'
   If StringLen($title) > 0 Then
	  $ret &= $title & '\'
   EndIf
   Return $ret
EndFunc

Func _GetOutput($title = '')
   Local $ret = ''
   If StringLen($optFolder) > 0 Then
	  $ret &= $optFolder & '\'
   EndIf
   $ret &= 'output\'
   If StringLen($title) > 0 Then
	  $ret &= $title & '\'
   EndIf
   Return $ret
EndFunc

Func _GetCiaDir()
   Local $ret = ''
   If StringLen($optFolder) > 0 Then
	  $ret &= $optFolder & '\'
   EndIf
   $ret &= 'cia\'
   Return $ret
EndFunc

Func _LogProgress($msg)
   ConsoleWrite('                                ')
   ConsoleWrite(@CR)
   ConsoleWrite($msg)
   ConsoleWrite(@CR)
EndFunc

Func _Error($msg)
   ConsoleWriteError($msg & @CRLF)
EndFunc

Func _RunWait($program, $workingdir = @Workingdir, $show_flag = @SW_HIDE, $opt_flag = $STDERR_CHILD + $STDOUT_CHILD)
   Local $pid = Run($program, $workingdir, $show_flag, $opt_flag)
   ProcessWaitClose($pid)

   Local $sOut = StdoutRead($pid)
   Local $sErr = StderrRead($pid)
   If @extended <> 0 Then
;~ 	  ConsoleWriteError('Return code: ' & @extended & @CRLF)
;~ 	  ConsoleWriteError($sErr)
   Else
;~ 	  ConsoleWrite($sOut)
   EndIf
   Return $sOut
EndFunc

Func _InfoGet($title, $key)
   Local $sInfo = FileRead(_GetInput($title) & 'info.txt')
   Local $arr = StringRegExp($sInfo, $key & '=(.*)', 1)
   If UBound($arr) == 1 Then
	  Return $arr[0]
   EndIf
   Return ""
EndFunc

Func _FileExistsArr($files, $dir = '')
   If Not IsArray($files) Then
	  $files = StringSplit($files, '|')
   EndIf
   For $i = 1 to $files[0]
	  Local $file = $files[$i]
	  If FileExists($dir & '/' & $file) Then
		 Return $dir & '/' & $file
	  EndIf
   Next
   Return Null
EndFunc
