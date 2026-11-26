@'
@echo off
cd /d "%~dp0"

echo Checking repository status...
git status -s

git diff --quiet && git diff --cached --quiet
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('git ls-files --others --exclude-standard') do set "has_untracked=1"
    if not defined has_untracked (
        echo.
        echo Nothing new to publish. Everything is already up to date.
        pause
        exit /b 0
    )
)

echo.
set /p "msg=Enter a short commit message (or press Enter for auto-timestamp): "
if "%msg%"=="" set "msg=Update build and scripts (%date% %time:~0,5%)"

git add -A
git commit -m "%msg%"
git push -u origin main

echo.
if %errorlevel% equ 0 (
    echo Successfully published to GitHub!
) else (
    echo Push failed. Check the error message above.
)
pause
'@ | Set-Content -Path "I:\gta-vi-github-data-mine-avatarmanz\git-builds\VIctory-Winty-9070XT-avatarmanz\publish-git.bat" -Encoding ASCII