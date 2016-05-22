@echo off
rem ---- VC
set VCINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\
set VC_PATH=%PATH%;%VCINSTALLDIR%\bin\x86_amd64;%VCINSTALLDIR%\bin
set LIB=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib\
rem ---- DMD
rem path=C:\D\dmd.2.069.2\windows\bin;C:\D\bin;
rem path=C:\D\dmd.2.070.0\windows\bin;C:\D\bin;
path=C:\D\dmd.2.071.0\windows\bin;C:\D\bin;%VC_PATH%;

@echo on

dmd -wi FileFind.d SelectDirectoryDialog.d rfind.d dlsbuffer.d @dwtlib_normal.txt
rem dmd -wi -m64 FileFind.d SelectDirectoryDialog.d rfind.d dlsbuffer.d @dwt64lib_normal.txt

dmd -wi -g -version=use_main rfind.d dlsbuffer.d

@if ERRORLEVEL 1 goto :eof
del *.obj

rem FileFind 
rfind d$ 
rfind cmd$ C:\D\rakugaki

echo done...
goto :eof
-----------------------------------
