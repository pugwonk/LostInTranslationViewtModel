# Working on the Mitsuoka Viewt cars

Notes on how the four cars in this repository are put together, built and changed. The README is only for people downloading the car.

## Previews

Each skin's `preview.jpg` is a Content Manager showroom preview, shown in the README. They're remade in Content Manager whenever a car's kn5 changes (see Building), so commit them with the model. They use the Content Manager preview preset `Viewt` (`source/viewt_previews.cmpreset`), which is the stock Kunos preset (same camera angle as most Assetto Corsa cars) with two changes: `Reflectiveness` is 25% (stock 66%) and `SSLR (local reflections)` is off. The stage model reflects in the paint, and on the Viewt's curved front wings that showed up as a crinkled white patch; these two settings leave it as a faint soft shading while the chrome still shines (the paint looks a little less glossy). Nothing else differs from Kunos. To use it, copy the file to `%LOCALAPPDATA%\AcTools Content Manager\Presets\Custom Previews` and pick `Viewt` in Update previews > Options.

## The cars

There are four cars in this repo. In Content Manager the three race cars are listed under the road car (their `ui_car.json` has `"parent": "mitsuoka_viewt"`). Each car has its own 3D model:

| Car folder | Name in game | Model | What it is |
| --- | --- | --- | --- |
| `mitsuoka_viewt` | Mitsuoka Viewt | `source/viewt_base.blend` | The road car, in six period colours (skins). Made from the 2023 model with the roll cage, race stickers, window decals and race kit removed, plain paint, 14" steel wheels with 185/60R14 road tyres and a factory interior (cream leather seats front and rear, burl wood dash and centre stack, carpet, pleated door cards and headliner). Physics as the 2023 car. |
| `mitsuoka_viewt_lemons_2023` | Mitsuoka Viewt Lemons 2023 | `source/viewt_2023.blend` | The road car's 14" steel wheels and 185/60R14 tyres; no Humphris Rallysport sticker; no rear-view screen on the dash |
| `mitsuoka_viewt_lemons_2024` | Mitsuoka Viewt Lemons 2024 | `source/viewt_2024.blend` | 195/50R15 tyres modelled at full width. Bilstein B4 dampers, HOL 60 mm lowering springs (front and rear) and front and rear sway bars (estimated figures). |
| `mitsuoka_viewt_lemons_2026` | Mitsuoka Viewt Lemons 2026 | `source/viewt_2026.blend` | As 2024 (including the suspension upgrades), with the QG18 engine and 5-speed gearbox. Its cabin differs from the 2024 car in three ways: the yellow 3D-printed switch panel (cooling, fuel, PC, charge, ignition and start) hangs from the cage's dash bar in place of the old toggle panel, the steering column is bare (no shroud), and an H-pattern gear lever in the stock oval boot replaces the sequential shifter. The wood-grain dash pad, its gauges and the rear-view screen are kept |

Some cars use their own copies of textures, named after the model: `source/texture/CarpaintExterior_*_2023.png` (2023, without the Humphris sticker), `source/texture/Logos_2026.png` (2026: the stickers atlas with the newer DRIVER and TEAM cards on the dash), `source/texture/Glass_*_2026.png` (2026: the glass with the longer lists of names on the rear windows, see below) and `source/texture/*_base.png` (road car: plain paint and clean glass). The road car and the 2023 car share one wheel design (`steelwheel_`, `wheelcap_` and `roadtyre_base_color.png`): a 14" steel wheel (5.5J) with a 185/60R14 tyre, 0.576 m overall, the same overall radius as `RADIUS` in `tyres.ini`. The road car's interior has its own textures too: `burlwood_`, `carpet_`, `leather_cream_`, `doorcard_`, `headliner_`, `dashplastic_` and `dashstack_base_color.png` (the centre stack face is painted in one piece: vents, switches, radio, climate dials and A/C slider).

The 2026 car's switch panel is textured from a clean redrawn atlas of the real one (flat yellow, black insets, crisp labels), and its gear knob pattern ("1 3 5 / 2 4 R") sits in the same image: `switchpanel_base_color.png` (the 2026 `.fbx.ini` has its `SwitchPanel` material).

The DRIVER and TEAM cards on the dash are one quad each in the `Logos` mesh, and the atlas patches their UVs cover are not the shape of the quads, so a new card is stretched to fill its whole patch, not fitted into it at its own shape, and the quad is made the card's shape instead:

| Card | Atlas pixels (1920 px atlas) | Quad on the dash |
| --- | --- | --- |
| DRIVER (face 84) | x 797 to 1304, y 767 to 1065 (508 by 299) | 93.4 by 49.6 mm |
| TEAM (face 85) | x 799 to 1303, y 1142 to 1358 (505 by 217) | 93.4 by 41.6 mm (was 38.4 mm) |

These are the 2026 model's figures.

The 2026 TEAM quad was made 3.2 mm taller (1.6 mm at each edge, along the dash) to match its card, which is 476 by 212 px like the old one; the DRIVER quad already fitted its new card to within 2 %. In `Logos_2026.png` each card fills its patch exactly, with a navy border of 1 or 2 px around it for filtering; the shared `Logos.png` has the older cards, slightly inside their patches.

The road car's paint colours are skins in `mitsuoka_viewt/skins/`. Each one is a copy of `CarpaintExterior_Base_color_base.png` with the body painted in that colour, which replaces the texture of the same name in the kn5. The colours are Cream Ivory, Silver, Burgundy, Bottle Green, Slate Blue and Pale Blue, picked from photos of real first-generation (K11) Viewts, since Mitsuoka sold them in a wide custom palette and no official colour chart for the early cars turned up. The skin textures are deliberately warmer and darker than the colour they should look: the Content Manager showroom lights the paint with a strong blue ambient, so cream, silver and slate are pre-tinted to read correctly in the previews. The paint material (`CarpaintExterior` in `source/viewt_base.fbx.ini`) is `ksAmbient` 0.4, `ksDiffuse` 0.5, `ksSpecular` 0.55; higher values washed the colours out to near-white.

## Building

Run `build.bat`. It:

1. Exports each `source/viewt_<model>.blend` to `source/viewt_<model>.fbx`, if the .blend has changed since the last export
2. Checks each car's `viewt.kn5` is newer than its `source/viewt_<model>.fbx` and `source/viewt_<model>.fbx.ini`. If one isn't, it shows step-by-step instructions for re-saving it in ksEditor, then waits until you've done that so the new kn5 goes into the zip.
3. Checks every skin's `preview.jpg` in each car is newer than that car's `viewt.kn5`. If one isn't, it shows how to remake the previews in Content Manager (Skins tab > Update previews, with the `Viewt` preset), then waits.
4. Zips all four cars into `dist/mitsuoka_viewt_<version>.zip`, laid out as `content/cars/...` so it can be dropped onto Content Manager or extracted into the Assetto Corsa folder. The version comes from `mitsuoka_viewt/ui/ui_car.json`.

It needs:

- **Blender** - it uses the newest one in `%USERPROFILE%\Dropbox\programs`. To use a different one, set `BLENDER` to the path of `blender.exe`.
- **ksEditor** - it comes with Assetto Corsa (`assettocorsa\sdk\editor`). The build finds it through Steam to show you its path. If it can't, set `KSEDITOR` to the folder containing `ksEditor.exe`.

The export and ksEditor steps are skipped for any car whose inputs haven't changed, and the window stays open at the end so you can read the output.

## Making changes

Each car folder is complete and stands on its own: the build copies nothing between them, so any one can be dropped into `content/cars` and tried as it is. The price is that a change to data the cars have in common (most of `data/`: `car.ini`, `cameras.ini`, `colliders.ini`, `damage.ini`, `engine.ini`, `lights.ini` and so on, plus `collider.kn5`, `logo.png` and the driver files) has to be made in each car's folder. To see where two cars have drifted apart, compare them in Git Bash:

```
diff -rq mitsuoka_viewt_lemons_2024 mitsuoka_viewt_lemons_2026 -x '*.kn5' -x preview.jpg -x '*.bank'
```

These are the files that are meant to differ, and the only ones that should:

- Every car: `viewt.kn5` (its own model - see below), `ui/ui_car.json` (name, description and specs), each skin's `preview.jpg`, `data/proview_nodes.ini` (lists the nodes of that car's own model), and `sfx/GUIDs.txt` and `sfx/<car folder>.bank` (see below)
- Race cars: `ui/upgrade.png`, the 64x64 icon Content Manager's car dropdown shows for a car listed under another. Each race car has its own, drawn in the style of Content Manager's built-in "STD" badge (a white ring round a small orange and red gauge, with the tier under it): 2023 is "STD", 2024 is "S1" and 2026 is "S2". The road car has none, so Content Manager gives it its own "STD" badge. Content Manager only reads these when it starts, so restart it after changing one
- Road car and 2023: `data/suspensions.ini` (stock springs, dampers and sway bar; the 2024 file has the race upgrades, which 2026 shares), `data/tyres.ini` (see below), and `extension/ext_config.ini`, which has just the dash clock and gauge backlight (see below) because neither has the rear-view screen's camera, so they have no `rear_camera.lua` either
- Road car: `skins/` (the six factory colours; the race cars have the Lost in Translation livery)
- Road car and 2026: no `data/digital_instruments.ini`, as they have no E/T temperature display
- 2026: `data/drivetrain.ini` and `data/power.lut` (engine and gearbox), `x.tuned`, and `animations/shift.ksanim` (see the driver section below)

`data/tyres.ini` - the 2024 and 2026 cars have the 195/50R15 Hankook Ventus R-S4 XL (`WIDTH` 0.195, `RADIUS` 0.288, `RIM_RADIUS` 0.1905 for the 15" rim). The road car and 2023 have the Vredestein Quatrac 5 185/60R14 instead (`NAME`, `WIDTH` 0.185 and `RIM_RADIUS` 0.1778 for the 14" rim; `RADIUS` stays 0.288, as 185/60R14 comes to 0.2888 and 195/50R15 to 0.288, so one value fits both). Being an all-season tyre it also grips less: `DY0` 1.10 and `DX0` 1.11 (the Ventus has 1.3053 and 1.3142) and `FRICTION_LIMIT_ANGLE` 8.5 (7.52), as its softer 60-series carcass peaks at a bigger slip angle. The temperature curve is already broad, so the thermals are the same. Other tyre changes go in all four files.

The sound bank is the same for all the cars, but has to be named after the car folder, so each car has its own copy as `sfx/<car folder>.bank`, and `sfx/GUIDs.txt` refers to it by that name (`bank:/<car folder>`). If the bank changes, replace it in all four folders under each folder's name.

## The names on the rear windows

The race cars' rear door windows carry the supporters' names, as vinyl lettering on the real car. The 2023 and 2024 cars have the 2024 list (one column per side, in the shared `source/texture/Glass_Base_color*.png`). The 2026 car has the 2026 list, which is longer: English on the right rear door (Copperplate small caps right-aligned to the front edge of the main glass, a serif list beside the bar) and katakana on the left (a bold list at the front edge, a lighter one with middle dots beside the bar). These are painted by `source/window_names.py`, which holds the four lists at the top of the file. It lays them out in metres on the visible glass (proportions measured off photos of the car) and warps them through the `GlassDoorRL`/`GlassDoorRR` UVs, so the right side comes out rotated in the texture as its island is. It starts from the shared glass textures, clears both rear windows but for the pugwonk3 logo, and writes the 2026 car's own copies: `source/texture/Glass_Base_color_2026.png` (what `viewt_2026.blend` shows), `Glass_Base_color_transparent_2026.png` (what the 2026 kn5 uses, through the `Glass` material in `viewt_2026.fbx.ini`; opaque under the names) and `Glass_Opacity_2026.png`. The road car's `*_base.png` glass has no names.

To add names, edit the lists and run `python source/window_names.py` from the repository root. It needs Pillow, numpy and Blender (found as `build.bat` finds it), which it runs in the background on `viewt_2026.blend` to read the window UVs and to render each door so it knows where the frame hides the glass; `--dry-run` only writes previews of both doors and prints where they are. Then re-save the 2026 kn5 in ksEditor: `build.bat` compares the kn5 against the FBX and the .ini, not the textures, so it won't ask for it by itself. The fonts are Windows' Copperplate Gothic Bold, Century, Yu Gothic Bold and Yu Gothic Medium.

## The driver and the steering wheel

The model has no driver (the build leaves out the `DRIVER:` objects); AC supplies its own and positions it from three files: `driver_base_pos.knh` (its skeleton), `animations/steer.ksanim` (its arms follow the wheel through 100 frames, frame 50 being straight ahead) and `animations/shift.ksanim` (the left arm going to the gear lever). The skeleton's root bone, `DRIVER:DRIVER`, is what places the driver in the car, in the same coordinates as the kn5 (y up, z forward; the driver sits at negative x). The wheel is centred on x -0.329, y 0.8485, z 0.459 (the `STEER_HR` empty in the .blend), with a rim 0.169 m in outer radius.

To move the driver, add the same offset to that root bone's translation in the .knh and in every frame of `steer.ksanim` (a frame is 10 floats: rotation quaternion, position, scale). To bring the hands in towards the rim without moving the body, move the clavicle bones `DRIVER:RIG_Clave_L` and `_R` (their translation is constant, in chest coordinates) towards each other in all three files, including `shift.ksanim`, which otherwise only animates the left arm (its root is an identity placeholder, so leave that alone). Every car has its own copy of these files, so make the same change in all four; the 2026 car's `shift.ksanim` is a different animation (see below), so check its hand still sits on the knob. `DRIVEREYES` in `car.ini` is in the same coordinates, so move it with the head.

The wheel is raked about 20 degrees (its axis is about (0, -0.34, 0.94)), so judge the hands in the wheel's own plane, not in x and y: a vertical shift also moves the hands along the wheel's axis, in or out of the rim. Stock Kunos cars put the middle-finger knuckle bone (`HAND_Middle1`/`HAND_Middle4`) about 0.01 to 0.03 m outside the rim's outer radius in that plane, with the straight-ahead frame (50) as the reference. The Viewt's wheel is small (outer radius 0.168 m, against 0.18 to 0.2 for the stock ones) and the stock arms are wider than it, so the hands are brought in. As of 2026-10-18 the root is moved by (+0.010, +0.011, +0.015) and each clavicle by 0.021 towards the middle, which puts both knuckles about 0.01 m outside the rim and on its plane at frame 50 (before: 0.019 and 0.037 m outside, the right hand worst). A first attempt that moved the driver by (+0.017, +0.05) judged the wheel as vertical and made it worse. `DRIVEREYES` x went from -0.36 to -0.335.

The 2026 car's gear lever is a fixed H-pattern knob, so it has its own `animations/shift.ksanim` (the other cars' file moves the hand along the old sequential lever, which would slide the hand off the knob). It holds a single pose for all 100 frames: every bone is taken from `steer.ksanim` frame 50 (the 2024 shift file's body sits about 0.12 m from the steering pose) except the left arm and fingers, which hold the knob. The grip was solved numerically against the knob (in Blender coordinates its axis is x 0.006, y -0.430 and it spans z 0.633 to 0.713): the fingers wrap its car-left side from behind with the thumb on the driver's side, every finger joint within about 0.01 m of the surface, the wrist at (-0.041, -0.336, 0.653), elbow bent 86 degrees (89 at the wheel). If the knob moves, the grip needs solving again. Not yet checked in AC itself.

## The rear-view screen

The dash screen is the `REAR_VIEW_DISPLAY` mesh, and it is left out of `data/mirrors.ini` on purpose: AC draws a mirror's picture over a mirror mesh, which would hide the camera. With Custom Shaders Patch (CSP), `extension/ext_config.ini` puts a real camera on the roof, where `CAMERA_5` in `data/cameras.ini` is, looking back (`[RENDERING_CAMERA_0]`, 150 degrees), squeezes its very wide picture through a fisheye pass (`[TEXTURE_PREPROCESSING_0]`) and `extension/rear_camera.lua` draws the result on the screen through a `[SCRIPTABLE_DISPLAY_0]`. Without CSP the screen is just black. For this to work the mesh's UVs cover the whole 0 to 1 square (they used to be a tiny patch of the shared texture), upright and unmirrored as seen from the driver's seat; the 2024 and 2026 models have this; the road car and the 2023 car (the real 2023 car had no screen) have none, so their `extension/` has only the clock and the gauge backlight. Positions in `ext_config.ini` are in the model's coordinates, which are the physics ones in `cameras.ini` minus `GRAPHICS_OFFSET` from `car.ini`, so move the camera by the same amount if `GRAPHICS_OFFSET` changes. The picture is a mirror image, like a backup camera's; set `MIRROR_IMAGE` to `false` at the top of the Lua script to turn that off.

## The dash clock

The round dial in the middle of the dash is a clock, like the real car's (black face, chrome ring, thin silver hands). The face is the `Clock face` mesh, which takes its picture from a small patch of the shared interior texture, `source/texture/CarpaintInterior_Base_color.png` (it used to be a fuel gauge). The patch holds the twelve markers, which look stretched there on purpose: the mesh is a tilted fan of triangles whose UVs are turned about 22 degrees from the dial's own up and which Subdivision then reshapes, so the markers were painted through the mesh's real UV-to-dial mapping to come out round. Redo it that way if the markers ever need changing. The hands are not in the texture.

The two hands are real meshes (`Clock hour hand` and `Clock minute hand`, in the `Gauges` collection, both using the `Chrome` material), each parented to an empty at the middle of the dial: `CLOCK_HOUR_HAND` and `CLOCK_MINUTE_HAND`. The empties are top-level and unscaled, which keeps their node matrices plain, and their local Z axis points out of the dial towards the driver. They are modelled at 10:08, so without CSP the clock is a still one at that time.

With CSP, `[SCRIPT_0]` in `extension/ext_config.ini` runs `extension/clock.lua`, which turns the two nodes to the PC's clock (set `USE_GAME_TIME` to `true` at the top of the script for the session's time of day instead, which follows the sun and the time multiplier and starts at whatever time the session was set to). It works on the nodes' matrices as the kn5 stores them, which include Blender's axis change, by rotating each axis in the dial's own plane from the modelled pose; `UP` (12 o'clock) and `RIGHT` (3 o'clock) at the top of the script are the dial's directions in model coordinates, so work them out again from the dial's plane if the dial is moved or retilted. The real car's clock has no second hand, so there is none. The script was tested against a stand-in for CSP's API (it matched Blender's own poses at six times of day), and in AC with the session's time it ran with no errors and showed 12:00 at a noon start.

`clock.lua` is the same in all four cars. The 2024 and 2026 cars have the same `extension/` (the clock, the gauge backlight and the rear-view screen); the road car and 2023 have only the clock and the backlight, so their `ext_config.ini` is shorter and they have no `rear_camera.lua`.

## Gauge lighting at night

With the headlights on, the three needles glow amber through `data/lights.ini` (`LIGHT_6` to `LIGHT_8`), which works without CSP because the needles have their own material, `Instrument needle`. The four dial faces (`Speedometer face`, `Fuel gauge face`, `Temp gauge face`, `Clock face`) share `CarpaintInterior` with most of the dash, and `lights.ini` lights a whole material, so they are lit by CSP instead: a `[CustomEmissive]` section in each car's `extension/ext_config.ini` lights just those meshes, and on them just the texels brighter than about 0.25 (the white numbers, ticks and clock dots), in white, whenever the headlights are on; a second section lights the clock's two hands (`Clock hour hand`, `Clock minute hand`, which share the `Chrome` material) white all over. Without CSP the dials stay dark at night. The fuel, temp and speedometer faces are flat quads whose corners pick up the light grey around each dial in the texture, so those corners glow too; they should be hidden behind the bezels (they would show light grey by day otherwise), but if a lit square edge shows at night, add a `CustomEmissive_Circle` mask instead of `CustomEmissive_CoverAll`.

## Updating the 3D models

Each car's model goes `source/viewt_<model>.blend` → `source/viewt_<model>.fbx` → `<car folder>/viewt.kn5`, where the model is `base`, `2023`, `2024` or `2026`. The three .blend files are separate, so a change that should apply to all of them has to be made in each one.

1. Edit `source/viewt_<model>.blend` in Blender and save it.
2. Run `build.bat`. It exports the .blend to `source/viewt_<model>.fbx`, leaving out the `DRIVER:` objects (AC supplies its own driver) and any hidden objects, and using the scale settings ksEditor expects.
3. The build then tells you to convert the FBX in ksEditor. Use a freshly opened ksEditor for each one, because File > Open FBX adds to whatever is already loaded and Save KN5 then saves the first model. File > Open FBX `source/viewt_<model>.fbx`, then File > Save KN5 > Car over `<car folder>/viewt.kn5`. Press a key when you're done, and it carries on to the next car and then makes the zip.

Material and per-object settings (shaders, textures, transparency, shadows, LODs) live in `source/viewt_<model>.fbx.ini`, not in the .blend - again one per car. To change them, open `source/viewt_<model>.fbx` in ksEditor (`assettocorsa\sdk\editor\ksEditor.exe`), which loads the .ini automatically. Make your changes, save them with File > Save Persistence over `source/viewt_<model>.fbx.ini`, then run `build.bat`. Commit the .ini along with the model.

The per-object sections in each .ini are keyed by the FBX file name (`[model_FBX: viewt_2023.fbx_...]`). If an FBX is ever renamed, rename those keys to match, or ksEditor will silently drop the per-object settings. Materials still load, because they're keyed by material name. To copy material changes from one car's .ini to another, copy the file and replace `viewt_<model>.fbx` with the other car's FBX name throughout.

