@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo  Mitsuoka Viewt build
echo ============================================================
echo.

rem 1. Export source\viewt.blend to source\model.fbx, if the .blend has changed since the last export.
rem    Set BLENDER to blender.exe to override; otherwise use the newest Blender in Dropbox\programs.
echo [1/4] Exporting the Blender model to FBX
call :newer source\viewt.blend source\model.fbx
if not errorlevel 1 (
  echo       source\viewt.blend hasn't changed since source\model.fbx was exported - skipping.
  goto fbx_done
)
if not defined BLENDER for /d %%d in ("%USERPROFILE%\Dropbox\programs\blender-*") do if exist "%%d\blender.exe" set "BLENDER=%%d\blender.exe"
if not defined BLENDER (
  echo       ERROR: Blender not found. Set BLENDER to the path of blender.exe.
  goto fail
)
echo       Using %BLENDER%
echo       Exporting source\viewt.blend to source\model.fbx...
rem Leaves out the driver (AC adds its own) and hidden leftover objects; scale matches what ksEditor expects
"%BLENDER%" -b source\viewt.blend --python-expr "import bpy, os; [o.select_set(not o.name.startswith('DRIVER:') and o.visible_get()) for o in bpy.data.objects]; bpy.ops.export_scene.fbx(filepath=os.path.join(os.path.dirname(bpy.data.filepath), 'model.fbx'), use_selection=True, apply_scale_options='FBX_SCALE_NONE', global_scale=0.01)" >nul
if errorlevel 1 (
  echo       ERROR: FBX export failed.
  goto fail
)
echo       Done.
:fbx_done
echo.

rem 2. The kn5 has to be made in ksEditor by hand. If the FBX or its material settings (model.fbx.ini) have
rem    changed since viewt.kn5 was saved, say how, then wait so the new kn5 goes into the QG18 car and the zip.
rem    Set KSEDITOR to the folder with ksEditor.exe to override the Steam lookup.
echo [2/4] Checking the game model (viewt.kn5) is up to date
call :kn5_stale
if not errorlevel 1 (
  echo       source\model.fbx and model.fbx.ini haven't changed since viewt.kn5 was saved - OK.
  goto kn5_done
)
if not defined KSEDITOR for /f "usebackq delims=" %%d in (`powershell -NoProfile -Command "$s = (Get-ItemProperty HKCU:\Software\Valve\Steam -ErrorAction SilentlyContinue).SteamPath; if ($s) { $libs = @($s) + (Select-String -Path (Join-Path $s 'steamapps\libraryfolders.vdf') -Pattern '^\s*.path.\s+.(.+).\s*$' | ForEach-Object { $_.Matches[0].Groups[1].Value -replace '\\\\', '\' }); $libs | ForEach-Object { Join-Path $_ 'steamapps\common\assettocorsa\sdk\editor' } | Where-Object { Test-Path (Join-Path $_ 'ksEditor.exe') } | Select-Object -First 1 }"`) do set "KSEDITOR=%%d"
if not defined KSEDITOR set "KSEDITOR=assettocorsa\sdk\editor in your Steam library"
echo       source\model.fbx or model.fbx.ini is newer than mitsuoka_viewt\viewt.kn5,
echo       so the game model needs re-saving in ksEditor:
echo.
echo         1. Open ksEditor:
echo              %KSEDITOR%\ksEditor.exe
echo         2. File ^> Open FBX, and pick:
echo              %CD%\source\model.fbx
echo            It loads the materials from model.fbx.ini automatically.
echo         3. File ^> Save KN5 ^> Car, and save over:
echo              %CD%\mitsuoka_viewt\viewt.kn5
echo         4. Close ksEditor and come back here.
echo.
echo       Press any key once you've saved the kn5 to carry on with the build,
echo       or close this window to stop.
pause >nul
call :kn5_stale
if errorlevel 1 (
  echo       WARNING: viewt.kn5 still looks out of date - carrying on with it anyway.
) else (
  echo       Got the new viewt.kn5.
)
:kn5_done
echo.

rem 3. Copy the base car over the QG18 car, keeping the QG18-specific files
echo [3/4] Copying mitsuoka_viewt over mitsuoka_viewt_qg18_sentra_engine
robocopy mitsuoka_viewt mitsuoka_viewt_qg18_sentra_engine /MIR /XF mitsuoka_viewt.bank drivetrain.ini power.lut ui_car.json GUIDs.txt x.tuned mitsuoka_viewt_QG18_B15_Sentra_Engine_Swap.bank mitsuoka_viewt_QG18_B15_Sentra_Engine_Swap_lost_in_translation.bank mitsuoka_viewt_qg18_sentra_engine.bank upgrade.png /XJD /R:3 /W:5 /NDL /NJH /NJS /NP
if errorlevel 8 (
  echo       ERROR: Copying to the QG18 car failed.
  goto fail
)
if errorlevel 1 (echo       Done.) else (echo       Already up to date - nothing to copy.)
echo.

rem 4. Zip both cars as content\cars\... so the zip can be dropped on Content Manager or extracted into the AC folder
echo [4/4] Creating the distribution zip
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "(Get-Content -Raw mitsuoka_viewt\ui\ui_car.json | ConvertFrom-Json).version"`) do set "VERSION=%%v"
set "ZIP=dist\mitsuoka_viewt_v%VERSION%.zip"
echo       Version %VERSION% (from mitsuoka_viewt\ui\ui_car.json)
if exist dist\stage rmdir /s /q dist\stage
for %%c in (mitsuoka_viewt mitsuoka_viewt_qg18_sentra_engine) do (
  echo       Adding content\cars\%%c
  robocopy %%c dist\stage\content\cars\%%c /E /XF data.acd /NFL /NDL /NJH /NJS /NP >nul
  if errorlevel 8 (
    echo       ERROR: Staging %%c for the zip failed.
    goto fail
  )
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

rem Sets errorlevel 1 if source\model.fbx or model.fbx.ini is newer than mitsuoka_viewt\viewt.kn5, else 0
:kn5_stale
call :newer source\model.fbx mitsuoka_viewt\viewt.kn5
if errorlevel 1 exit /b 1
call :newer source\model.fbx.ini mitsuoka_viewt\viewt.kn5
exit /b

rem Sets errorlevel 1 if %1 is newer than %2 (or %2 doesn't exist), else 0
:newer
powershell -NoProfile -Command "if (!(Test-Path '%~2') -or (Get-Item '%~1').LastWriteTime -gt (Get-Item '%~2').LastWriteTime) { exit 1 } else { exit 0 }"
exit /b
