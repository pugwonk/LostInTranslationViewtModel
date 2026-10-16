# LostInTranslationViewtModel
The world's slowest race car, now available as a rolling roadblock in Assetto Corsa

## Making changes

There are two cars in this repo:

- `mitsuoka_viewt` - the base car
- `mitsuoka_viewt_qg18_sentra_engine` - the QG18 engine swap, a copy of the base car with a different engine and gearbox

**Make all changes to the base car (`mitsuoka_viewt`), then run `build_qg18.bat`** to copy them across to the QG18 car. Don't edit the QG18 folder directly - the script mirrors the base car over it, so anything changed only there will be overwritten or deleted.

The only exceptions are the files that are specific to the QG18 car, which the script leaves alone:

- `data/drivetrain.ini` and `data/power.lut` - engine and gearbox
- `ui/ui_car.json` and `ui/upgrade.png` - name, description and specs
- `sfx/GUIDs.txt` and `sfx/mitsuoka_viewt_qg18_sentra_engine.bank` - the sound bank, which has to be named after the car folder (it's the same sound as the base car)
- `x.tuned`

Edit those in the QG18 folder directly. If you add another file that should differ between the two cars, add it to the `/XF` list in `build_qg18.bat`.
