
#include-once

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
	  ConsoleWriteError($sErr)
   Else
;~ 	  ConsoleWrite($sOut)
   EndIf
   Return $sOut
EndFunc

Func _InfoGet($title, $key)
   Local $sInfo = FileRead("input\" & $title & "\info.txt")
   Local $arr = StringRegExp($sInfo, $key & '=(.*)', 1)
   If UBound($arr) == 1 Then
	  Return $arr[0]
   EndIf
   Return ""
EndFunc

Func _FileExistsArr($files, $dir = "")
   If Not IsArray($files) Then
	  $files = StringSplit($files, "|")
   EndIf
   For $i = 1 to $files[0]
	  Local $file = $files[$i]
	  If FileExists($dir & "/" & $file) Then
		 Return $dir & "/" & $file
	  EndIf
   Next
   Return Null
EndFunc
