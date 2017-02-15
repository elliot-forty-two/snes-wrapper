
@echo on
set AUT2EXE="C:\Program Files (x86)\AutoIt3\Aut2Exe\Aut2exe.exe"

pushd %~dp0

mkdir build
%AUT2EXE% /in src\banner.au3 /out build\banner.exe /console
%AUT2EXE% /in src\snesscraper.au3 /out build\snesscraper.exe /console
%AUT2EXE% /in src\sneswrapper.au3 /out build\sneswrapper.exe /console

xcopy /Q /E /Y template build\template
xcopy /Q /E /Y tools build\tools

popd
