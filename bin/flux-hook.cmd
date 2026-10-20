@echo off
if "%1"=="agy" if "%2"=="PreToolUse" (
  echo {"decision":"allow"}
  exit /b 0
)
if "%1"=="agy" (
  echo {}
  exit /b 0
)
exit /b 0
