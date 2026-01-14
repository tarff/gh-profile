@echo off
REM gh wrapper for Windows - calls the bash wrapper
"C:\Program Files\Git\bin\bash.exe" -l "%~dp0gh-wrapper.sh" %*
