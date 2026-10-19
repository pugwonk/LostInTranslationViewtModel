@echo off
setlocal
cd /d "%~dp0"

rem There are four cars, each with its own model (source\viewt_<model>.blend):
rem   mitsuoka_viewt             - model "base": the road car in its factory colours
rem   mitsuoka_viewt_lemons_2023 - model "2023", listed under the road car in Content Manager
rem   mitsuoka_viewt_lemons_2024 - model "2024", ditto
rem   mitsuoka_viewt_lemons_2026 - model "2026", ditto
rem mitsuoka_viewt_lemons_2024 holds the shared data: everything except each car's own files is copied from it in step 3.
set "MODELS=base 2023 2024 2026"
set "DATA=mitsuoka_viewt_lemons_2024"

echo ============================================================
echo  Mitsuoka Viewt build
echo ============================================================
echo.

rem 1. Export each source\viewt_<model>.blend to source\viewt_<model>.fbx, if the .blend has changed since the last export.
rem    Set BLENDER to blender.exe to override; otherwise use the newest Blender in Dropbox\programs.
echo [1/5] Exporting the Blender models to FBX
for %%m in (%MODELS%) do (
  call :export %%m
  if errorlevel 1 goto fail
)
echo.

rem 2. The kn5s have to be made in ksEditor by hand. If a car's FBX or its material settings (viewt_<model>.fbx.ini)
rem    have changed since its viewt.kn5 was saved, say how, then wait so the new kn5 goes into the zip.
rem    Set KSEDITOR to the folder with ksEditor.exe to override the Steam lookup.
echo [2/5] Checking the game models (viewt.kn5) are up to date
for %%m in (%MODELS%) do call :kn5 %%m
echo.

rem 3. The skin previews are made in Content Manager by hand, from the finished kn5. Every car needs its own, as each
rem    has its own model (step 4 leaves the lemons cars' preview.jpg alone when it copies %DATA%'s skins over them).
rem    If a preview is missing or older than its car's viewt.kn5, say how to remake them, then wait.
echo [3/5] Checking the skin previews (preview.jpg) are up to date
for %%m in (%MODELS%) do call :previews_model %%m
echo.

rem 4. Copy the shared data over the other cars, keeping each car's own files:
rem      road car - its model, ui_car.json, upgrade.png (it has no parent, so no icon), skins (factory colours), extension (its own ext_config.ini with just the clock; clock.lua is copied in, see :clock_script), mirrors.ini and digital_instruments.ini (no
rem                 rear-view screen or temperature display in the road car), suspensions.ini (stock, as the 2023 car); tyres.ini gets the 185/60R14 tyre
rem      2023     - its model, ui_car.json, upgrade.png (STD), preview.jpg and suspensions.ini (stock springs, dampers and sway bar); tyres.ini gets the 185/60R14 tyre;
rem                 extension (its own ext_config.ini with just the clock, as it has no rear-view screen for the camera to draw on; clock.lua is copied in, see :clock_script)
rem      2026     - its model, ui_car.json, upgrade.png (S2) and preview.jpg, the QG18 engine and gearbox, digital_instruments.ini (no E/T temperature display) and
rem                 animations\shift.ksanim (the left hand holds the H-pattern gear knob; the other cars' animation works the old sequential lever)
rem      The 2024 car's own upgrade.png (S1) is the shared one, so only 2023 and 2026 need to keep theirs.
rem    The sound bank is the same for all of them but has to be named after the car folder, so it's copied
rem    under the right name and GUIDs.txt is rewritten to match.
echo [4/5] Copying %DATA% over the other cars
call :mirror mitsuoka_viewt viewt.kn5 ui_car.json upgrade.png suspensions.ini mirrors.ini digital_instruments.ini /XD "skins extension"
if errorlevel 1 goto fail
call :road_tyres mitsuoka_viewt
call :clock_script mitsuoka_viewt
if errorlevel 1 goto fail
call :mirror mitsuoka_viewt_lemons_2023 viewt.kn5 ui_car.json upgrade.png preview.jpg suspensions.ini /XD extension
if errorlevel 1 goto fail
call :road_tyres mitsuoka_viewt_lemons_2023
call :clock_script mitsuoka_viewt_lemons_2023
if errorlevel 1 goto fail
call :mirror mitsuoka_viewt_lemons_2026 viewt.kn5 ui_car.json upgrade.png preview.jpg drivetrain.ini power.lut digital_instruments.ini x.tuned shift.ksanim
if errorlevel 1 goto fail
echo.

rem 5. Zip all the cars as content\cars\... so the zip can be dropped on Content Manager or extracted into the AC folder
echo [5/5] Creating the distribution zip
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Get-Content -Raw mitsuoka_viewt\ui\ui_car.json | ConvertFrom-Json).version"`) do set "VERSION=%%v"
set "ZIP=dist\mitsuoka_viewt_%VERSION%.zip"
echo       Version %VERSION% (from mitsuoka_viewt\ui\ui_car.json)
if exist dist\stage rmdir /s /q dist\stage
for %%m in (%MODELS%) do (
  call :car %%m
  call :stage
  if errorlevel 1 goto fail
)
if exist "%ZIP%" del "%ZIP%"
echo       Compressing...
"%SystemRoot%\System32\tar.exe" -a -c -f "%ZIP%" -C dist\stage content
set "TARERR=%errorlevel%"
rmdir /s /q dist\stage
if not "%TARERR%"=="0" (
  echo       ERROR: Creating the zip failed.
  goto fail
)
for %%z in ("%ZIP%") do echo       Wrote %ZIP% (%%~zz bytes)
echo.
echo ============================================================
echo  Build finished
echo ============================================================
pause
exit /b 0

:fail
echo.
echo ============================================================
echo  Build FAILED
echo ============================================================
pause
exit /b 1

rem Sets CAR to the car folder for model %1
:car
if "%1"=="base" (set "CAR=mitsuoka_viewt") else (set "CAR=mitsuoka_viewt_lemons_%1")
exit /b 0

rem Copies %CAR% into the zip staging folder. Sets errorlevel 1 on failure.
:stage
echo       Adding content\cars\%CAR%
robocopy %CAR% dist\stage\content\cars\%CAR% /E /XF data.acd /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
  echo       ERROR: Staging %CAR% for the zip failed.
  exit /b 1
)
exit /b 0

rem Exports source\viewt_%1.blend to source\viewt_%1.fbx if it's changed. Sets errorlevel 1 on failure.
:export
call :newer source\viewt_%1.blend source\viewt_%1.fbx
if not errorlevel 1 (
  echo       %1: source\viewt_%1.blend hasn't changed since it was exported - skipping.
  exit /b 0
)
if not defined BLENDER for /d %%d in ("%USERPROFILE%\Dropbox\programs\blender-*") do if exist "%%d\blender.exe" set "BLENDER=%%d\blender.exe"
if not defined BLENDER (
  echo       ERROR: Blender not found. Set BLENDER to the path of blender.exe.
  exit /b 1
)
echo       %1: exporting source\viewt_%1.blend to source\viewt_%1.fbx using %BLENDER%...
rem Leaves out the driver (AC adds its own) and hidden leftover objects; scale matches what ksEditor expects
"%BLENDER%" -b source\viewt_%1.blend --python-expr "import bpy, os; [o.select_set(not o.name.startswith('DRIVER:') and o.visible_get()) for o in bpy.data.objects]; bpy.ops.export_scene.fbx(filepath=os.path.join(os.path.dirname(bpy.data.filepath), 'viewt_%1.fbx'), use_selection=True, apply_scale_options='FBX_SCALE_NONE', global_scale=0.01)" >nul
if errorlevel 1 (
  echo       ERROR: FBX export failed.
  exit /b 1
)
exit /b 0

rem If model %1's kn5 is out of date, shows how to re-save it in ksEditor and waits
:kn5
call :car %1
call :kn5_stale %1
if not errorlevel 1 (
  echo       %1: source\viewt_%1.fbx and its .ini haven't changed since %CAR%\viewt.kn5 was saved - OK.
  exit /b 0
)
if not defined KSEDITOR for /f "usebackq delims=" %%d in (`powershell -NoProfile -Command "$s = (Get-ItemProperty HKCU:\Software\Valve\Steam -ErrorAction SilentlyContinue).SteamPath; if ($s) { $libs = @($s) + (Select-String -Path (Join-Path $s 'steamapps\libraryfolders.vdf') -Pattern '^\s*.path.\s+.(.+).\s*$' | ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' }); $libs | ForEach-Object { Join-Path $_ 'steamapps\common\assettocorsa\sdk\editor' } | Where-Object { Test-Path (Join-Path $_ 'ksEditor.exe') } | Select-Object -First 1 }"`) do set "KSEDITOR=%%d"
if not defined KSEDITOR set "KSEDITOR=assettocorsa\sdk\editor in your Steam library"
echo       %1: source\viewt_%1.fbx or viewt_%1.fbx.ini is newer than %CAR%\viewt.kn5,
echo       so the game model needs re-saving in ksEditor:
echo.
echo         1. Open ksEditor - a fresh copy, as File ^> Open FBX adds to whatever is already loaded:
echo              %KSEDITOR%\ksEditor.exe
echo         2. File ^> Open FBX, and pick:
echo              %CD%\source\viewt_%1.fbx
echo            It loads the materials from viewt_%1.fbx.ini automatically.
echo         3. File ^> Save KN5 ^> Car, and save over:
echo              %CD%\%CAR%\viewt.kn5
echo         4. Close ksEditor and come back here.
echo.
echo       Press any key once you've saved the kn5 to carry on with the build,
echo       or close this window to stop.
pause >nul
call :kn5_stale %1
if errorlevel 1 (
  echo       WARNING: %CAR%\viewt.kn5 still looks out of date - carrying on with it anyway.
) else (
  echo       Got the new %CAR%\viewt.kn5.
)
exit /b 0

rem Sets errorlevel 1 if source\viewt_%1.fbx or its .ini is newer than model %1's viewt.kn5, else 0
:kn5_stale
call :car %1
call :newer source\viewt_%1.fbx %CAR%\viewt.kn5
if errorlevel 1 exit /b 1
call :newer source\viewt_%1.fbx.ini %CAR%\viewt.kn5
exit /b

rem Checks the skin previews of the car for model %1
:previews_model
call :car %1
call :previews %CAR%
exit /b 0

rem If any of car folder %1's skin previews is out of date, shows how to remake them in Content Manager and waits
:previews
call :previews_stale %1
if not errorlevel 1 (
  echo       %1: every skin's preview.jpg is newer than viewt.kn5 - OK.
  exit /b 0
)
echo       %1: a skin's preview.jpg is missing or older than %1\viewt.kn5,
echo       so the previews need remaking in Content Manager:
echo.
echo         1. Open Content Manager and go to Cars ^> pick the car "%1".
echo         2. Open its Skins tab and select all the skins.
echo         3. Click "Update previews" (or open the Showroom and use Update preview for each skin),
echo            and wait for it to finish. If the car comes out bigger or smaller than the other cars' previews,
echo            open Update previews ^> Options and pick the plain Kunos preset first (a moved camera shows in italics).
echo         4. Close the dialog and come back here.
echo.
echo       Press any key once the previews are updated to carry on with the build,
echo       or close this window to stop.
pause >nul
call :previews_stale %1
if errorlevel 1 (
  echo       WARNING: %1's previews still look out of date - carrying on with them anyway.
) else (
  echo       Got the new previews.
)
exit /b 0

rem Sets errorlevel 1 if any skin of car folder %1 has no preview.jpg or one older than the car's viewt.kn5, else 0
:previews_stale
powershell -NoProfile -Command "$k = (Get-Item '%1\viewt.kn5').LastWriteTime; $p = @(Get-ChildItem '%1\skins' -Directory | ForEach-Object { Join-Path $_.FullName 'preview.jpg' }); if ($p | Where-Object { !(Test-Path $_) -or (Get-Item $_).LastWriteTime -lt $k }) { exit 1 } else { exit 0 }"
exit /b

rem Gives car %1 the tyre its model has: Vredestein Quatrac 5 185/60R14 (section width 0.185, 14" rim = rim radius 0.1778).
rem RADIUS stays the shared 0.288: 185/60R14 comes to 0.2888 and 195/50R15 to 0.288, so both fit the one value.
rem It's an all-season tyre, so it grips less than the Ventus R-S4: DY0/DX0 (peak lateral/longitudinal grip) drop from
rem 1.3053/1.3142 to 1.10/1.11, and the softer 60-series carcass peaks at a bigger slip angle (FRICTION_LIMIT_ANGLE 7.52 to 8.5).
rem The temperature curve is already broad, so thermals are left alone.
:road_tyres
powershell -NoProfile -Command "$f = '%1\data\tyres.ini'; (Get-Content $f) -replace '^NAME=.*', 'NAME=Vredestein Quatrac 5' -replace '^WIDTH=.*', 'WIDTH=0.185' -replace '^RIM_RADIUS=.*', 'RIM_RADIUS=0.1778' -replace '^DY0=.*', 'DY0=1.10' -replace '^DX0=.*', 'DX0=1.11' -replace '^FRICTION_LIMIT_ANGLE=.*', 'FRICTION_LIMIT_ANGLE=8.5' | Set-Content $f"
exit /b 0

rem Gives car %1 the dash clock's script. The cars without the rear-view screen keep their own extension\ext_config.ini (just the
rem clock), so the mirror leaves extension alone and the shared clock.lua is copied over from %DATA% here instead.
rem Sets errorlevel 1 on failure.
:clock_script
if not exist %1\extension mkdir %1\extension
copy /y %DATA%\extension\clock.lua %1\extension\clock.lua >nul
if errorlevel 1 (
  echo       ERROR: Copying clock.lua to %1 failed.
  exit /b 1
)
exit /b 0

rem Mirrors the shared data over car %1, leaving alone the files named in the other arguments (and any
rem robocopy options among them, such as /XD skins), then gives it the sound bank under its own name.
rem Sets errorlevel 1 on failure.
:mirror
set "DEST=%~1"
set "KEEP="
set "OPTS="
:mirror_args
shift
if "%~1"=="" goto mirror_run
if "%~1"=="/XD" (
  set "OPTS=%OPTS% /XD %~2"
  shift
) else (
  set "KEEP=%KEEP% %~1"
)
goto mirror_args
:mirror_run
robocopy %DATA% %DEST% /MIR /XF *.bank GUIDs.txt data.acd%KEEP%%OPTS% /XJD /R:3 /W:5 /NDL /NJH /NJS /NP
if errorlevel 8 (
  echo       ERROR: Copying to %DEST% failed.
  exit /b 1
)
del /q %DEST%\sfx\*.bank 2>nul
copy /y %DATA%\sfx\%DATA%.bank %DEST%\sfx\%DEST%.bank >nul
powershell -NoProfile -Command "(Get-Content %DATA%\sfx\GUIDs.txt) -replace '%DATA%', '%DEST%' | Set-Content %DEST%\sfx\GUIDs.txt"
if errorlevel 1 (
  echo       ERROR: Copying the sound bank to %DEST% failed.
  exit /b 1
)
echo       %DEST% done.
exit /b 0

rem Sets errorlevel 1 if %1 is newer than %2 (or %2 doesn't exist), else 0
:newer
powershell -NoProfile -Command "if (!(Test-Path '%~2') -or (Get-Item '%~1').LastWriteTime -gt (Get-Item '%~2').LastWriteTime) { exit 1 } else { exit 0 }"
exit /b
