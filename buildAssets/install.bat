@echo off
setlocal

rem Définit le dossier cible où copier les fichiers
set TARGET_FOLDER=%LOCALAPPDATA%\mobinsa

rem Création du dossier cible
if not exist "%TARGET_FOLDER%" mkdir "%TARGET_FOLDER%"

rem Copie des fichiers
copy "mobinsa.exe" "%TARGET_FOLDER%"
xcopy /E /I /Y "data" "%TARGET_FOLDER%\data"
copy "flutter_windows.dll" "%TARGET_FOLDER%"

rem Chemin du raccourci à créer dans le menu démarrer utilisateur
set SHORTCUT_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\MobInsa
if not exist "%SHORTCUT_FOLDER%" mkdir "%SHORTCUT_FOLDER%"

rem Nom du raccourci
set SHORTCUT_PATH=%SHORTCUT_FOLDER%\MobInsa.lnk

rem Crée le raccourci avec PowerShell
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%TARGET_FOLDER%\mobinsa.exe'; $Shortcut.WorkingDirectory = '%TARGET_FOLDER%'; $Shortcut.Save()"


echo Fichiers copiés et raccourci créé avec succès.
pause
