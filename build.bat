@ECHO OFF

set EXE=anka.exe

rd /q /s build
mkdir build

@REM copy assets and binaries
xcopy /sei assets build\assets > nul
for %%I in (bin\*) do xcopy %%I build > nul

pushd build

@REM call odin build ..\src -out=anka.exe -show-timings -no-crt
call odin build ..\src -out=anka.exe -show-timings

popd
