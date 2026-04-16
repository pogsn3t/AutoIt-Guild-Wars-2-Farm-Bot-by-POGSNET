@echo off
set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2Exe.exe"
set INPUT="C:\autoscript\gd2.au3"
set OUTPUT="C:\autoscript\gd2.exe"

echo Compiling AutoIt script...
%AUT2EXE% /in %INPUT% /out %OUTPUT%

echo Done!