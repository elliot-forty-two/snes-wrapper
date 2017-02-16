
#include-once

#include 'lib/_XMLDomWrapper.au3'

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

Func _GetCiaOutput()
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

Func _LogError($msg)
   ConsoleWriteError('ERROR: ' & $msg & @CRLF)
EndFunc

Func _LogWarning($msg)
   ConsoleWriteError('WARNING: ' & $msg & @CRLF)
EndFunc

Func _LogMessage($msg)
   ConsoleWrite($msg & @CRLF)
EndFunc

Func _RunWait($program, $workingdir = @Workingdir, $show_flag = @SW_HIDE, $opt_flag = $STDERR_CHILD + $STDOUT_CHILD)
   Local $pid = Run($program, $workingdir, $show_flag, $opt_flag)
   ProcessWaitClose($pid)
   Local $result = @extended
   Local $sOut = StdoutRead($pid)
   Local $sErr = StderrRead($pid)
   If $result <> 0 Then
	  _LogError('Program failed: ' & $program)
	  _LogError('Return code: ' & $result)
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

Func _XMLGetFirstValue($xpath)
   Local $nodes = _XMLGetValue($xpath)
   If @error == 0 Then
	  Return $nodes[1]
   EndIf
EndFunc
