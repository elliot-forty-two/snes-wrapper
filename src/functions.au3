
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
   If $optVerbose Then
	  _LogMessage($msg)
   Else
	  ConsoleWrite('                                ')
	  ConsoleWrite(@CR)
	  ConsoleWrite($msg)
	  ConsoleWrite(@CR)
   EndIf
EndFunc

Func _LogVerbose($msg)
   If $optVerbose Then
	  _LogMessage($msg)
   EndIf
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
   _LogVerbose('Run: ' & $program)
   Local $pid = Run($program, $workingdir, $show_flag, $opt_flag)
   ProcessWaitClose($pid)
   Local $result = @extended
   Local $sOut = StdoutRead($pid)
   Local $sErr = StderrRead($pid)
   If $result <> 0 Then
	  _LogError('Command failed: ' & $program)
	  _LogError('Return code: ' & $result)
	  _LogVerbose($sErr)
   EndIf
   Return $sOut
EndFunc

Func _GetInfoValue($title, $key)
   Local $sInfo = FileRead(_GetInput($title) & 'info.txt')
   Local $arr = StringRegExp($sInfo, $key & '=(.*)', 1)
   If UBound($arr) == 1 Then
	  Return $arr[0]
   EndIf
   Return Null
EndFunc

Func _FileExistsArr($files, $dir = '')
   If StringLen($dir) > 0 And StringRight($dir, 1) <> '\' Then
	  $dir &= '\'
   EndIf
   For $i = 0 to UBound($files)
	  Local $file = $files[$i]
	  If FileExists($dir & $file) Then
		 Return $dir & $file
	  EndIf
   Next
   Return Null
EndFunc

Func _FileExists($sFilePath , $sFilter = "*", $iFlag = $FLTA_FILES)
   _FileListToArray($sFilePath, $sFilter, $iFlag)
   Return @error <> 0
EndFunc

Func _XMLGetFirstValue($xpath)
   Local $nodes = _XMLGetValue($xpath)
   If @error == 0 Then
	  Return $nodes[1]
   EndIf
   Return Null
EndFunc
