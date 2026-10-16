# LostInTranslationViewtModel
The world's slowest race car, now available as a rolling roadblock in Assetto Corsa

## Building

Run `build.bat`. It:

1. Exports `source/viewt.blend` to `source/model.fbx`, if the .blend has changed since the last export
2. Checks `mitsuoka_viewt/viewt.kn5` is newer than `source/model.fbx` and `source/model.fbx.ini`. If it isn't, it shows step-by-step instructions for re-saving it in ksEditor, then waits until you've done that so the new kn5 goes into the QG18 car and the zip.
3. Copies the base car over the QG18 car
4. Zips both cars into `dist/mitsuoka_viewt_v<version>.zip`, laid out as `content/cars/...` so it can be dropped onto Content Manager or extracted into the Assetto Corsa folder. The version comes from `mitsuoka_viewt/ui/ui_car.json`.

It needs:

- **Blender** - it uses the newest one in `%USERPROFILE%\Dropbox\programs`. To use a different one, set `BLENDER` to the path of `blender.exe`.
- **ksEditor** - it comes with Assetto Corsa (`assettocorsa\sdk\editor`). The build finds it through Steam to show you its path. If it can't, set `KSEDITOR` to the folder containing `ksEditor.exe`.

The export and ksEditor steps are skipped if their inputs haven't changed, and the window stays open at the end so you can read the output.

## Making changes

There are two cars in this repo:

- `mitsuoka_viewt` - the base car
- `mitsuoka_viewt_qg18_sentra_engine` - the QG18 engine swap, a copy of the base car with a different engine and gearbox

**Make all changes to the base car (`mitsuoka_viewt`), then run `build.bat`** to copy them across to the QG18 car. Don't edit the QG18 folder directly - the build mirrors the base car over it, so anything changed only there will be overwritten or deleted.

The only exceptions are the files that are specific to the QG18 car, which the build leaves alone:

- `data/drivetrain.ini` and `data/power.lut` - engine and gearbox
- `ui/ui_car.json` and `ui/upgrade.png` - name, description and specs
- `sfx/GUIDs.txt` and `sfx/mitsuoka_viewt_qg18_sentra_engine.bank` - the sound bank, which has to be named after the car folder (it's the same sound as the base car)
- `x.tuned`

Edit those in the QG18 folder directly. If you add another file that should differ between the two cars, add it to the `/XF` list on the `robocopy ... /MIR` line in `build.bat`.

## Updating the 3D model

The model goes `source/viewt.blend` → `source/model.fbx` → `mitsuoka_viewt/viewt.kn5`:

1. Edit `source/viewt.blend` in Blender and save it.
2. Run `build.bat`. It exports the .blend to `source/model.fbx`, leaving out the `DRIVER:` objects (AC supplies its own driver) and any hidden objects, and using the scale settings ksEditor expects.
3. The build then tells you to convert the FBX in ksEditor: File > Open FBX `source/model.fbx`, then File > Save KN5 > Car over `mitsuoka_viewt/viewt.kn5`. Press a key when you're done, and it copies the new model to the QG18 car and makes the zip.

Material and per-object settings (shaders, textures, transparency, shadows, LODs) live in `source/model.fbx.ini`, not in the .blend. To change them, open `source/model.fbx` in ksEditor (`assettocorsa\sdk\editor\ksEditor.exe`), which loads the .ini automatically. Make your changes, save them with File > Save Persistence over `source/model.fbx.ini`, then run `build.bat`. Commit `model.fbx.ini` along with the model.

The per-object sections in `model.fbx.ini` are keyed by the FBX file name (`[model_FBX: model.fbx_...]`). If the FBX is ever renamed, rename those keys to match, or ksEditor will silently drop the per-object settings. Materials still load, because they're keyed by material name.
