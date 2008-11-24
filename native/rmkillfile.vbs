REM This file will be overwritten by remote-poller.nsi
REM function WriteCustomVbsKillScript.

Call DeleteAFile("C:\Windows\Temp\testfile.txt")

Sub DeleteAFile(filespec)
   Dim fso
   Set fso = CreateObject("Scripting.FileSystemObject")
   fso.DeleteFile(filespec)
End Sub