# LostInTranslationViewtModel
The world's slowest race car, now available as a rolling roadblock in Assetto Corsa

## The cars

There are four cars in this repo. In Content Manager the three race cars are listed under the road car (their `ui_car.json` has `"parent": "mitsuoka_viewt"`). Each car has its own 3D model:

| Car folder | Name in game | Model | What it is |
| --- | --- | --- | --- |
| `mitsuoka_viewt` | Mitsuoka Viewt | `source/viewt_base.blend` | The road car, in six period colours (skins). Made from the 2023 model with the roll cage, race stickers, window decals and race kit removed, plain paint, 14" steel wheels with 185/60R14 road tyres and a factory interior (cream leather seats front and rear, burl wood dash and centre stack, carpet, pleated door cards and headliner). Physics as the 2023 car. |
| `mitsuoka_viewt_lemons_2023` | Mitsuoka Viewt Lemons 2023 | `source/viewt_2023.blend` | The road car's 14" steel wheels and 185/60R14 tyres; no Humphris Rallysport sticker |
| `mitsuoka_viewt_lemons_2024` | Mitsuoka Viewt Lemons 2024 | `source/viewt_2024.blend` | 195/50R15 tyres modelled at full width. Bilstein B4 dampers, HOL 60 mm lowering springs in front and front and rear sway bars (estimated figures). Holds the shared data (see below). |
| `mitsuoka_viewt_lemons_2026` | Mitsuoka Viewt Lemons 2026 | `source/viewt_2026.blend` | As 2024 (including the suspension upgrades), with the QG18 engine and 5-speed gearbox |

Some cars use their own copies of textures, named after the model: `source/texture/CarpaintExterior_*_2023.png` (2023, without the Humphris sticker) and `source/texture/*_base.png` (road car: plain paint and clean glass). The road car and the 2023 car share one wheel design (`steelwheel_`, `wheelcap_` and `roadtyre_base_color.png`): a 14" steel wheel (5.5J) with a 185/60R14 tyre, 0.576 m overall, the same overall radius as `RADIUS` in `tyres.ini`. The road car's interior has its own textures too: `burlwood_`, `carpet_`, `leather_cream_`, `doorcard_`, `headliner_`, `dashplastic_` and `dashstack_base_color.png` (the centre stack face is painted in one piece: vents, switches, radio, climate dials and A/C slider).

The road car's paint colours are skins in `mitsuoka_viewt/skins/`. Each one is a copy of `CarpaintExterior_Base_color_base.png` with the body painted in that colour, which replaces the texture of the same name in the kn5. The colours are Cream Ivory, Silver, Burgundy, Bottle Green, Slate Blue and Pale Blue, picked from photos of real first-generation (K11) Viewts, since Mitsuoka sold them in a wide custom palette and no official colour chart for the early cars turned up. The skin textures are deliberately warmer and darker than the colour they should look: the Content Manager showroom lights the paint with a strong blue ambient, so cream, silver and slate are pre-tinted to read correctly in the previews. The paint material (`CarpaintExterior` in `source/viewt_base.fbx.ini`) is `ksAmbient` 0.4, `ksDiffuse` 0.5, `ksSpecular` 0.55; higher values washed the colours out to near-white.

## Building

Run `build.bat`. It:

1. Exports each `source/viewt_<model>.blend` to `source/viewt_<model>.fbx`, if the .blend has changed since the last export
2. Checks each car's `viewt.kn5` is newer than its `source/viewt_<model>.fbx` and `source/viewt_<model>.fbx.ini`. If one isn't, it shows step-by-step instructions for re-saving it in ksEditor, then waits until you've done that so the new kn5 goes into the zip.
3. Checks every skin's `preview.jpg` in the road car and the 2024 car is newer than that car's `viewt.kn5`. If one isn't, it shows how to remake the previews in Content Manager (Skins tab > Update previews), then waits.
4. Copies the shared data from the 2024 car over the other cars (including its skins and previews)
5. Zips all four cars into `dist/mitsuoka_viewt_<version>.zip`, laid out as `content/cars/...` so it can be dropped onto Content Manager or extracted into the Assetto Corsa folder. The version comes from `mitsuoka_viewt/ui/ui_car.json`.

It needs:

- **Blender** - it uses the newest one in `%USERPROFILE%\Dropbox\programs`. To use a different one, set `BLENDER` to the path of `blender.exe`.
- **ksEditor** - it comes with Assetto Corsa (`assettocorsa\sdk\editor`). The build finds it through Steam to show you its path. If it can't, set `KSEDITOR` to the folder containing `ksEditor.exe`.

The export and ksEditor steps are skipped for any car whose inputs haven't changed, and the window stays open at the end so you can read the output.

## Making changes

**Make all physics and data changes to `mitsuoka_viewt_lemons_2024`, then run `build.bat`** to copy them across to the other cars. Don't edit the other car folders directly - the build mirrors the 2024 car over them, so anything changed only there will be overwritten or deleted.

The only exceptions are the files that are specific to each car, which the build leaves alone. Edit these in that car's folder directly:

- Road car and 2023: `data/suspensions.ini` (stock springs, dampers and sway bar; the 2024 file has the race upgrades, which 2026 shares)
- All cars: `viewt.kn5` (the model - see below) and `ui/ui_car.json` (name, description and specs)
- Race cars: `ui/upgrade.png` (the icon Content Manager shows for a car listed under another)
- Road car: `skins/` (the factory colours), and `data/mirrors.ini` and `data/digital_instruments.ini` (it has no rear-view camera screen or temperature display, so `mirrors.ini` leaves out `REAR_VIEW_DISPLAY` and there is no `digital_instruments.ini`)
- 2026: `data/drivetrain.ini` and `data/power.lut` (engine and gearbox), and `x.tuned`

The build also makes these, so don't edit them in the other cars:

- `data/tyres.ini` - the 2024 car's file is the 195/50R15 Hankook Ventus R-S4 XL (`WIDTH` 0.195, `RADIUS` 0.288, `RIM_RADIUS` 0.1905 for the 15" rim), and 2026 gets it unchanged. The road car and 2023 get it with the tyre changed to the Vredestein Quatrac 5 185/60R14 (`NAME`, `WIDTH` 0.185 and `RIM_RADIUS` 0.1778 for the 14" rim; `RADIUS` stays 0.288, as 185/60R14 comes to 0.2888). Being an all-season tyre it also grips less: `DY0` 1.10 and `DX0` 1.11 (the Ventus has 1.3053 and 1.3142) and `FRICTION_LIMIT_ANGLE` 8.5 (7.52). All set in `build.bat`
- `sfx/GUIDs.txt` and `sfx/<car folder>.bank` - the sound bank is the same for all the cars, but has to be named after the car folder, so the build copies it under the right name and rewrites `GUIDs.txt` to match

If you add another file that should differ between the cars, add it to that car's `call :mirror` line in `build.bat`.

## Updating the 3D models

Each car's model goes `source/viewt_<model>.blend` → `source/viewt_<model>.fbx` → `<car folder>/viewt.kn5`, where the model is `base`, `2023`, `2024` or `2026`. The three .blend files are separate, so a change that should apply to all of them has to be made in each one.

1. Edit `source/viewt_<model>.blend` in Blender and save it.
2. Run `build.bat`. It exports the .blend to `source/viewt_<model>.fbx`, leaving out the `DRIVER:` objects (AC supplies its own driver) and any hidden objects, and using the scale settings ksEditor expects.
3. The build then tells you to convert the FBX in ksEditor. Use a freshly opened ksEditor for each one, because File > Open FBX adds to whatever is already loaded and Save KN5 then saves the first model. File > Open FBX `source/viewt_<model>.fbx`, then File > Save KN5 > Car over `<car folder>/viewt.kn5`. Press a key when you're done, and it carries on to the next car and then makes the zip.

Material and per-object settings (shaders, textures, transparency, shadows, LODs) live in `source/viewt_<model>.fbx.ini`, not in the .blend - again one per car. To change them, open `source/viewt_<model>.fbx` in ksEditor (`assettocorsa\sdk\editor\ksEditor.exe`), which loads the .ini automatically. Make your changes, save them with File > Save Persistence over `source/viewt_<model>.fbx.ini`, then run `build.bat`. Commit the .ini along with the model.

The per-object sections in each .ini are keyed by the FBX file name (`[model_FBX: viewt_2023.fbx_...]`). If an FBX is ever renamed, rename those keys to match, or ksEditor will silently drop the per-object settings. Materials still load, because they're keyed by material name. To copy material changes from one car's .ini to another, copy the file and replace `viewt_<model>.fbx` with the other car's FBX name throughout.
