"""Puts another car's engine sound into the 2026 race car, to try it out in AC.

    python source/try_sound.py <donor car folder>     e.g. bmw_m3_e30, mx5_2005_track
    python source/try_sound.py --restore              back to the stock (Miata) bank

The donor's bank is copied in as sfx/mitsuoka_viewt_lemons_2026.bank, and sfx/GUIDs.txt is
rewritten with the donor's event and bank GUIDs under this car's name. Mod cars keep their
GUIDs in their own sfx/GUIDs.txt; Kunos cars have theirs in content/sfx/GUIDs.txt. The
buses, VCAs and common banks are the same in every car, so they're kept from this car's file.
The AC cars folder links to this repository, so the swap is live as soon as AC loads the car.
"""

import os, re, shutil, subprocess, sys

CAR = 'mitsuoka_viewt_lemons_2026'
AC = r'G:\SteamLibrary\steamapps\common\assettocorsa\content'
SFX = os.path.join(CAR, 'sfx')


def main():
    donor = sys.argv[1]
    if donor == '--restore':
        subprocess.run(['git', 'checkout', '--', SFX], check=True)
        print('Restored the stock bank')
        return
    src = os.path.join(AC, 'cars', donor, 'sfx')
    own = os.path.join(src, 'GUIDs.txt')
    lines = open(own if os.path.exists(own) else os.path.join(AC, 'sfx', 'GUIDs.txt')).read().splitlines()
    donor_lines = [l for l in lines if f'/cars/{donor}/' in l or l.endswith(f'bank:/{donor}')]
    assert any('engine_ext' in l for l in donor_lines), f'no engine events for {donor}'
    keep = [l for l in open(os.path.join(SFX, 'GUIDs.txt')).read().splitlines()
            if l.strip() and '/cars/' not in l and not l.endswith(f'bank:/{CAR}')]
    renamed = [re.sub(rf'(/cars/|bank:/){re.escape(donor)}\b', rf'\g<1>{CAR}', l) for l in donor_lines]
    open(os.path.join(SFX, 'GUIDs.txt'), 'w', newline='\r\n').write('\n'.join(keep + renamed) + '\n')
    shutil.copyfile(os.path.join(src, f'{donor}.bank'), os.path.join(SFX, f'{CAR}.bank'))
    print(f'{CAR} now has the {donor} sound ({len(renamed)} events and banks)')


if __name__ == '__main__':
    main()
