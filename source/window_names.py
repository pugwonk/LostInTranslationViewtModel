"""Paints the supporters' names on the rear door windows of the 2026 race car.

The names are vinyl lettering on the real car: English on the right rear door (Copperplate
small caps at the front edge of the main glass, a serif list beside the bar) and katakana on
the left rear door (a bold list at the front edge, a lighter one with middle dots beside the
bar). This script lays the four lists out in metres on the visible glass, as measured off
photos of the car, warps them through the GlassDoorRL/GlassDoorRR mesh UVs into the glass
texture, and writes the 2026 car's three copies of it:

    texture/Glass_Base_color_2026.png              (what viewt_2026.blend shows)
    texture/Glass_Base_color_transparent_2026.png  (what the 2026 kn5 uses; opaque under the names)
    texture/Glass_Opacity_2026.png                 (the .blend's alpha)

It starts from the shared Glass_Base_color.png, Glass_Base_color_transparent.png and
Glass_Opacity.png (the 2023 and 2024 cars' glass, with the shorter 2024 list of names, which
stay as they are), clears both rear windows except the pugwonk3 logo, and paints the lists.
The road car's *_base.png glass has no names.

To add names, edit the four lists below and run `python source/window_names.py` from the
repository root (needs Pillow and numpy, and Blender as build.bat finds it: BLENDER, or the
newest one in %USERPROFILE%\Dropbox\programs). It runs Blender in the background on
viewt_2026.blend to read the window UVs and to render each side so it knows where the door
frame hides the glass, then repaints the names. Afterwards re-save the 2026 kn5 in ksEditor
(build.bat does not notice a texture change on its own). Pass --dry-run to only write the
previews, whose paths it prints.
"""

import glob, json, os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

# ---- The names, as on the car. Top to bottom. --------------------------------------------

# Right rear door, front column (Copperplate small caps, right-aligned to the front edge)
EN_CAPS = ['Tim Sullivan', 'Alexis Brinley', 'Peaches Gall', 'Sean Green', 'Chris Blizzard', 'Danny Khen',
           'Bret Dodson', 'David Potts', 'David Enslow', 'Doug Chase', 'Anton Lovett', 'Fred Schechter',
           'Mary Harris', 'Neal Losey', 'Jill Carrigan Britt', 'Richard Britt', 'Ed Smith', 'Trapper Bailey',
           'Kiki Rae', 'Mickey McDonough', 'Chris Rae']
# Right rear door, rear column (serif, left-aligned beside the bar)
EN_SERIF = ['Finian Bailey', 'Stef Schrader', 'Phil Greden', 'Blake Little', 'Mike Harrell', 'Dustin Bago',
            'Gregg Temkin', 'Andy Smith', 'Scott Watkins', 'Russel Pasewald', 'Larry Sanders', 'Tony Rae',
            'Daniel Schmeichler', 'Steve Summerville', 'Chris Duranti', 'Sean Windrum']
# Left rear door, front column (bold gothic, left-aligned to the front edge; a full-width space
# between the given and family names, as on the car)
JP_BOLD = ['ティム　サリバン', 'アレクシス　ブリンリー', 'ヒアケス　ギャル', 'ショーン　グリーン', 'クリス　ブリッザード',
           'ダニー　ケン', 'ブレット　ドドソン', 'デービッド　ポッツ', 'デービッド　エンスロー', 'ダグ　チェース',
           'アントン　ロブット', 'フレッド　スケクター', 'メアリー　ハリス', 'ニール　ロシー', 'ジル　カリガン　ブリット',
           'リチャード　ブリット', 'エド　スミス', 'トラッパー　ベイリー', 'キキ　レイ', 'ミッキー　ミクドナ', 'クリス　レイ']
# Left rear door, rear column (medium gothic with middle dots, right-aligned beside the bar)
JP_LIGHT = ['フィニアン・ベイリー', 'ステフ・シュレイダー', 'フィル・クレデン', 'ブレイク・リトル', 'マイク・ハレル',
            'ダスティン・バゴ', 'グレッグ・テムキン', 'アンディ・スミス', 'スコット・ワトキンス', 'ラッセル・ペイズウォルド',
            'ラリー・サンダース', 'トニー・レイ', 'ダニエル・シュマイヒラー', 'スティーブ・サマーヴィル', 'クリス・デュランティ',
            'ショーン・ウィンドラム']

# ---- Layout, as fractions of the main glass's visible width (W) and height (H) ------------
# glyph: height of the probe glyph; top: the first line's glyph top below the frame;
# margin: from the front edge (edge='front') or the bar (edge='rear'); pitch: line spacing;
# weight: extra stroke added round each glyph, per side (a dilation, so keep it small on fonts that are
# already bold or their counters fill in). The real lettering is thinner and smaller than this, but at the
# texture's resolution (about 1 texel per mm) that came out faint, so the lettering is drawn bigger and
# heavier, about as heavy as the 2024 block.
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
LAYOUT = {
    'R': [  # right rear door: English
        dict(names=EN_CAPS, font='COPRGTB.TTF', probe='H', glyph=0.031, edge='front', margin=0.04, top=0.06, pitch=0.0425, weight=0.002),
        dict(names=EN_SERIF, font='CENTURY.TTF', probe='H', glyph=0.034, edge='rear', margin=0.04, top=0.05, pitch=0.048, weight=0.0015),
    ],
    'L': [  # left rear door: katakana
        dict(names=JP_BOLD, font='YuGothB.ttc', probe='ア', glyph=0.036, edge='front', margin=0.03, top=0.035, pitch=0.0445, weight=0.001),
        dict(names=JP_LIGHT, font='YuGothM.ttc', probe='ア', glyph=0.040, edge='rear', margin=0.03, top=0.03, pitch=0.055, weight=0.002),
    ],
}

# ---- Fixed facts about the model ----------------------------------------------------------
SRC = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(SRC, 'texture')
BLEND = os.path.join(SRC, 'viewt_2026.blend')
TEXSIZE = 2048
REGION = {'L': (1231, 1625, 1955, 2028), 'R': (1261, 31, 1985, 434)}   # each island's box in texture px
LOGO = {'L': (1740, 1940, 1900, 2000), 'R': (1760, 60, 1910, 120)}      # the pugwonk3 logo, kept as it is
PPM = 4000                                   # canvas pixels per metre
Y0, Y1, Z0, Z1 = 0.30, 1.06, 0.92, 1.31      # canvas extent in Blender coordinates (y rearward, z up)
RPPM, RW, RH = 1600, 1600, 900               # the side renders: orthographic, 1 m across, centred on...
RCY, RCZ = 0.68, 1.11

BLENDER_SCRIPT = r'''
import bpy, json, math, sys
out = sys.argv[sys.argv.index('--') + 1]
res = []
for ob in bpy.data.objects:
    if ob.type != 'MESH' or ob.name not in ('GlassDoorRL', 'GlassDoorRR'): continue
    me = ob.data; uv = me.uv_layers.active.data; mw = ob.matrix_world
    for p in me.polygons:
        pts = []
        for li, vi in zip(p.loop_indices, p.vertices):
            co = mw @ me.vertices[vi].co
            pts.append([uv[li].uv[0], uv[li].uv[1], co.x, co.y, co.z])
        res.append({'ob': ob.name, 'pts': pts})
json.dump(res, open(out + '/uv.json', 'w'))
# Flat renders from each side with the glass in green, so the visible glass can be masked
sc = bpy.context.scene
for ob in bpy.data.objects:
    if ob.name.startswith('GlassDoor'): ob.hide_render = False
for m in bpy.data.materials: m.blend_method = 'OPAQUE'
bpy.data.materials['Glass'].diffuse_color = (0, 1, 0, 1)
sc.render.engine = 'BLENDER_WORKBENCH'
sh = sc.display.shading; sh.light = 'FLAT'; sh.color_type = 'MATERIAL'; sh.show_backface_culling = False; sh.show_xray = False
sc.render.resolution_x = %d; sc.render.resolution_y = %d; sc.render.resolution_percentage = 100
sc.render.film_transparent = False; sc.render.image_settings.file_format = 'PNG'
cd = bpy.data.cameras.new('SideCam'); cd.type = 'ORTHO'; cd.ortho_scale = 1.0
cam = bpy.data.objects.new('SideCam', cd); sc.collection.objects.link(cam); sc.camera = cam
for side, x, rz in (('L', 5.0, math.radians(90)), ('R', -5.0, math.radians(-90))):
    cam.location = (x, %r, %r); cam.rotation_euler = (math.radians(90), 0, rz)
    sc.render.filepath = out + '/mask_' + side + '.png'
    bpy.ops.render.render(write_still=True)
''' % (RW, RH, RCY, RCZ)


def find_blender():
    b = os.environ.get('BLENDER')
    if b: return b
    found = sorted(glob.glob(os.path.join(os.path.expanduser('~'), 'Dropbox', 'programs', 'blender-*', 'blender.exe')))
    if not found: sys.exit('Blender not found. Set BLENDER to the path of blender.exe.')
    return found[-1]


def run_blender(work):
    script = os.path.join(work, 'dump.py')
    open(script, 'w').write(BLENDER_SCRIPT)
    r = subprocess.run([find_blender(), '-b', BLEND, '--python', script, '--', work.replace('\\', '/')],
                       capture_output=True, text=True)
    if r.returncode or not os.path.exists(os.path.join(work, 'mask_R.png')):
        sys.exit('Blender failed:\n' + r.stdout[-3000:] + r.stderr[-3000:])


def font_for(path, height_px, probe):
    """A font whose glyph `probe` is height_px tall."""
    f = ImageFont.truetype(path, 100)
    b = f.getbbox(probe)
    return ImageFont.truetype(path, int(round(100 * height_px / (b[3] - b[1]))))


def draw_column(dr, names, font, x, top, pitch, align, probe):
    asc = font.getbbox(probe)[1]   # from the drawing origin down to the glyph top
    for i, n in enumerate(names):
        w = font.getlength(n)
        dr.text((x if align == 'left' else x - w, top + i * pitch - asc), n, font=font, fill=255)


def side_frames(work, side):
    """The visible main glass (dict of y0, y1, z0, z1 in Blender coordinates) and the glass mask."""
    a = np.asarray(Image.open(os.path.join(work, f'mask_{side}.png')).convert('RGB')).astype(int)
    g = (a[:, :, 1] > 150) & (a[:, :, 0] < 150) & (a[:, :, 2] < 150)
    cols = g.any(axis=0)
    runs, start = [], None
    for x in range(len(cols) + 1):
        c = cols[x] if x < len(cols) else False
        if c and start is None: start = x
        if not c and start is not None: runs.append((start, x - 1)); start = None
    runs = sorted(sorted(runs, key=lambda r: r[0] - r[1])[:2])   # the two widest panes, left to right
    boxes = []
    for x0, x1 in runs:
        ys = np.nonzero(g[:, x0:x1 + 1].any(axis=1))[0]
        if side == 'L': ya, yb = RCY + (x0 - RW / 2) / RPPM, RCY + (x1 - RW / 2) / RPPM
        else:           ya, yb = RCY - (x1 - RW / 2) / RPPM, RCY - (x0 - RW / 2) / RPPM
        boxes.append(dict(y0=ya, y1=yb, z0=RCZ - (ys.max() - RH / 2) / RPPM, z1=RCZ - (ys.min() - RH / 2) / RPPM))
    main = max(boxes, key=lambda b: b['y1'] - b['y0'])
    return main, g


def canvas_for(work, side):
    """The names drawn in a world-space canvas as seen from outside the car."""
    img = Image.new('L', (int((Y1 - Y0) * PPM), int((Z1 - Z0) * PPM)), 0)
    main, _ = side_frames(work, side)
    Hm, Wm = (main['z1'] - main['z0']) * PPM, (main['y1'] - main['y0']) * PPM
    cx = (lambda y: (y - Y0) * PPM) if side == 'L' else (lambda y: (Y1 - y) * PPM)
    front, rear = cx(main['y0']), cx(main['y1'])   # y0 is the front edge; y runs rearward
    inward = 1 if front < rear else -1
    top = (Z1 - main['z1']) * PPM
    print(f'{side}: main glass {Wm / PPM:.3f} x {Hm / PPM:.3f} m visible')
    for col in LAYOUT[side]:
        f = font_for(os.path.join(FONTS, col['font']), col['glyph'] * Hm, col['probe'])
        if col['edge'] == 'front':
            x, align = front + inward * col['margin'] * Wm, 'left' if inward > 0 else 'right'
        else:
            x, align = rear - inward * col['margin'] * Wm, 'right' if inward > 0 else 'left'
        layer = Image.new('L', img.size, 0)
        draw_column(ImageDraw.Draw(layer), col['names'], f, x, top + col['top'] * Hm, col['pitch'] * Hm, align, col['probe'])
        # Thicken the glyphs by `weight` on each side (a dilation; PIL's own stroker mis-draws the Japanese fonts)
        s = int(round(col.get('weight', 0) * Hm))
        if s: layer = layer.filter(ImageFilter.MaxFilter(2 * s + 1))
        img = ImageChops.lighter(img, layer)
    return img


def triangles(work, side):
    tris = []
    for r in json.load(open(os.path.join(work, 'uv.json'))):
        if r['ob'] != 'GlassDoorR' + side: continue
        p = r['pts']
        for i in range(1, len(p) - 1):
            tris.append((p[0], p[i], p[i + 1]))
    return tris


def bary_raster(tris, w, h):
    """tris: triples of (sx, sy, dx, dy) corners. For every pixel centre of a w x h grid, the
    barycentric interpolation of (dx, dy) over the triangle covering it (NaN where none does)."""
    out = np.full((h, w, 2), np.nan, np.float32)
    for t in tris:
        P = np.array([[p[0], p[1]] for p in t], np.float64)
        D = np.array([[p[2], p[3]] for p in t], np.float64)
        x0, x1 = max(int(np.floor(P[:, 0].min())), 0), min(int(np.ceil(P[:, 0].max())), w - 1)
        y0, y1 = max(int(np.floor(P[:, 1].min())), 0), min(int(np.ceil(P[:, 1].max())), h - 1)
        if x1 < x0 or y1 < y0: continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = P
        det = (bx - ax) * (cy - ay) - (cx - ax) * (by - ay)
        if abs(det) < 1e-12: continue
        wa = ((bx - xs) * (cy - ys) - (cx - xs) * (by - ys)) / det
        wb = ((cx - xs) * (ay - ys) - (ax - xs) * (cy - ys)) / det
        wc = 1 - wa - wb
        inside = (wa >= -1e-3) & (wb >= -1e-3) & (wc >= -1e-3)
        for k in range(2):
            val = wa * D[0, k] + wb * D[1, k] + wc * D[2, k]
            out[y0:y1 + 1, x0:x1 + 1, k][inside] = val[inside]
    return out


def coverage(work, side, canvas):
    """Per-texture-pixel coverage (0..1) of the text over the island's box, 4x supersampled."""
    x0, y0, x1, y1 = REGION[side]; SS = 4
    w, h = (x1 - x0) * SS, (y1 - y0) * SS
    tris = [tuple(((p[0] * TEXSIZE - x0) * SS, ((1 - p[1]) * TEXSIZE - y0) * SS, p[3], p[4]) for p in t)
            for t in triangles(work, side)]
    yz = bary_raster(tris, w, h)
    ok = ~np.isnan(yz[:, :, 0])
    yy, zz = yz[:, :, 0][ok], yz[:, :, 1][ok]
    sx = ((yy - Y0) * PPM if side == 'L' else (Y1 - yy) * PPM).astype(int)
    sy = ((Z1 - zz) * PPM).astype(int)
    arr = np.asarray(canvas, np.float32) / 255
    good = (sx >= 0) & (sx < canvas.width) & (sy >= 0) & (sy < canvas.height)
    vals = np.zeros(ok.sum(), np.float32); vals[good] = arr[sy[good], sx[good]]
    cov = np.zeros((h, w), np.float32); cov[ok] = vals
    return cov.reshape(y1 - y0, SS, x1 - x0, SS).mean(axis=(1, 3))


def apply(side, cov, rgb, alpha, opac):
    """Clear the island (but for the logo) and paint the names white and opaque."""
    x0, y0, x1, y1 = REGION[side]; lx0, ly0, lx1, ly1 = LOGO[side]
    keep = np.zeros((y1 - y0, x1 - x0), bool); keep[ly0 - y0:ly1 - y0, lx0 - x0:lx1 - x0] = True
    r, a, o = rgb[y0:y1, x0:x1], alpha[y0:y1, x0:x1], opac[y0:y1, x0:x1]
    r[~keep] = 0
    a[~keep & (a > 75)] = 64; o[~keep & (o > 75)] = 64    # plain glass is 64..75
    # A texel covered c by opaque white over glass of alpha ag and colour rg, as straight alpha:
    # alpha = c + (1 - c) ag, colour = (c white + (1 - c) ag rg) / alpha. The glass is black here, so
    # a half-covered texel is 80% white at alpha 0.625, not 50% white (which would look dark and thin).
    ag = a.astype(np.float32) / 255
    A = cov + (1 - cov) * ag
    col = (cov * 255 + (1 - cov) * ag * r[:, :, 0].astype(np.float32)) / np.maximum(A, 1e-6)
    r[:] = (col + 0.5).astype(np.uint8)[:, :, None]
    a8 = (A * 255 + 0.5).astype(np.uint8)
    a[:] = a8; o[:] = np.where(cov > 0, a8, o)


def preview(work, side, rgb, alpha):
    """The side render with the glass textured, as seen from outside, cropped to the door."""
    base = np.asarray(Image.open(os.path.join(work, f'mask_{side}.png')).convert('RGB')).astype(np.float32)
    _, g = side_frames(work, side)
    def src(p):   # Blender y, z -> render px
        x = RW / 2 + (p[3] - RCY) * RPPM if side == 'L' else RW / 2 - (p[3] - RCY) * RPPM
        return (x, RH / 2 - (p[4] - RCZ) * RPPM)
    tris = [tuple(src(p) + (p[0], p[1]) for p in t) for t in triangles(work, side)]
    uv = bary_raster(tris, RW, RH)
    ok = g & ~np.isnan(uv[:, :, 0])
    tx = np.clip((uv[:, :, 0][ok] * TEXSIZE).astype(int), 0, TEXSIZE - 1)
    ty = np.clip(((1 - uv[:, :, 1][ok]) * TEXSIZE).astype(int), 0, TEXSIZE - 1)
    col = rgb[ty, tx].astype(np.float32); al = alpha[ty, tx].astype(np.float32)[:, None] / 255
    base[ok] = col * al + np.array([70, 75, 80], np.float32) * (1 - al)
    base[g & ~ok] = (255, 0, 255)   # visible glass the island does not cover (there should be none)
    x0, x1 = (200, 1420) if side == 'L' else (180, 1400)
    return Image.fromarray(base.astype(np.uint8)).crop((x0, 130, x1, 770)).resize(((x1 - x0) * 2, 1280), Image.LANCZOS)


def main():
    dry = '--dry-run' in sys.argv
    work = tempfile.mkdtemp(prefix='viewt_window_names_')
    print('Reading the window UVs and rendering the doors in Blender...')
    run_blender(work)
    src = {k: os.path.join(TEX, k + '.png') for k in ('Glass_Base_color', 'Glass_Base_color_transparent', 'Glass_Opacity')}
    out = {k: os.path.join(TEX, k + '_2026.png') for k in src}
    rgb = np.array(Image.open(src['Glass_Base_color']).convert('RGB'))
    tr = np.array(Image.open(src['Glass_Base_color_transparent']).convert('RGBA'))
    op = np.array(Image.open(src['Glass_Opacity']).convert('L'))
    alpha = tr[:, :, 3].copy()
    for side in 'LR':
        cov = coverage(work, side, canvas_for(work, side))
        apply(side, cov, rgb, alpha, op)
        p = os.path.join(work, f'preview_{side}.png')
        preview(work, side, rgb, alpha).save(p)
        print(f'{side}: preview {p}')
    if dry:
        print('Dry run: textures not written.')
        return
    Image.fromarray(rgb).save(out['Glass_Base_color'])
    Image.fromarray(np.dstack([rgb, alpha])).save(out['Glass_Base_color_transparent'])
    Image.fromarray(op).save(out['Glass_Opacity'])
    print('Written:', *out.values(), sep='\n  ')
    print('Now re-save the 2026 kn5 in ksEditor (see README, Updating the 3D models).')


if __name__ == '__main__':
    main()
