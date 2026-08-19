#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'assets/3d/manifest.json'
PROVENANCE = ROOT / 'assets/3d/provenance/catalog.json'
PUBSPEC = ROOT / 'pubspec.yaml'
WORK = ROOT / 'docs/work/AST-007-batch01.md'

WIDTH = HEIGHT = 384
QUALITY = 86
GENERATOR = 'CARGame AST-007 procedural cargo batch renderer v1'
CREATION_DATE = '2026-08-19'

BATCH = (
    ('cargo.accessory_box', 'Accessory Box', 'fashion'),
    ('cargo.accessory_carton', 'Accessory Carton', 'special'),
    ('cargo.action_figure_box', 'Action Figure Box', 'toys'),
    ('cargo.apparel_box', 'Apparel Box', 'fashion'),
    ('cargo.apple_crate', 'Apple Crate', 'food'),
    ('cargo.archive_box', 'Archive Box', 'office'),
    ('cargo.auto_part_crate', 'Auto Part Crate', 'special'),
    ('cargo.bakery_box', 'Bakery Box', 'food'),
    ('cargo.basketball_bag', 'Basketball Bag', 'sports'),
    ('cargo.battery_pack', 'Battery Pack', 'special'),
    ('cargo.board_game_box', 'Board Game Box', 'toys'),
    ('cargo.boot_carton', 'Boot Carton', 'fashion'),
)

PALETTES = {
    'fashion': ((122, 76, 168, 255), (167, 119, 207, 255), (82, 48, 123, 255)),
    'special': ((58, 112, 164, 255), (102, 167, 211, 255), (35, 72, 112, 255)),
    'toys': ((203, 80, 62, 255), (239, 134, 82, 255), (139, 45, 42, 255)),
    'food': ((81, 145, 87, 255), (139, 190, 104, 255), (47, 96, 56, 255)),
    'office': ((143, 107, 72, 255), (196, 158, 111, 255), (91, 65, 47, 255)),
    'sports': ((214, 120, 45, 255), (243, 169, 77, 255), (151, 75, 27, 255)),
}

INK = (42, 44, 49, 255)
WHITE = (247, 244, 232, 255)


def descriptor_map() -> dict[str, dict]:
    data = json.loads(MANIFEST.read_text(encoding='utf-8'))
    return {asset['id']: asset for asset in data['assets']}


def rounded_polygon(draw: ImageDraw.ImageDraw, points, fill):
    draw.polygon(points, fill=fill)


def draw_package(draw: ImageDraw.ImageDraw, category: str, bag: bool = False) -> tuple[int, int, int, int]:
    body, light, dark = PALETTES[category]
    draw.ellipse((72, 296, 320, 334), fill=(20, 25, 30, 47))
    if bag:
        draw.rounded_rectangle((86, 110, 302, 304), radius=38, fill=body, outline=dark, width=7)
        draw.arc((135, 62, 255, 164), 188, 352, fill=dark, width=12)
        draw.arc((143, 72, 247, 154), 188, 352, fill=light, width=5)
        draw.polygon([(302, 136), (332, 118), (332, 272), (302, 304)], fill=dark)
        draw.line((101, 130, 285, 130), fill=light, width=7)
        return (112, 158, 278, 278)
    rounded_polygon(draw, [(70, 132), (114, 96), (304, 114), (266, 154)], light)
    rounded_polygon(draw, [(266, 154), (304, 114), (304, 278), (266, 310)], dark)
    draw.rounded_rectangle((70, 132, 266, 310), radius=18, fill=body, outline=dark, width=6)
    draw.line((74, 151, 261, 151), fill=light, width=7)
    draw.line((99, 115, 284, 133), fill=WHITE, width=4)
    return (103, 176, 236, 276)


def icon_accessory(draw, box):
    x1, y1, x2, y2 = box
    cx = (x1+x2)//2
    draw.ellipse((cx-38, y1+22, cx+38, y1+98), outline=WHITE, width=10)
    draw.ellipse((cx-13, y1+87, cx+13, y1+113), fill=WHITE)


def icon_carton(draw, box):
    x1, y1, x2, y2 = box
    cx, cy = (x1+x2)//2, (y1+y2)//2
    pts = [(cx, cy-48), (cx+43, cy-24), (cx+43, cy+24), (cx, cy+48), (cx-43, cy+24), (cx-43, cy-24)]
    draw.polygon(pts, outline=WHITE)
    draw.line(pts + [pts[0]], fill=WHITE, width=9, joint='curve')


def icon_figure(draw, box):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1+18, y1+7, x2-18, y2-5), radius=15, outline=WHITE, width=8)
    cx = (x1+x2)//2
    draw.ellipse((cx-19, y1+28, cx+19, y1+66), fill=WHITE)
    draw.line((cx, y1+67, cx, y1+120), fill=WHITE, width=12)
    draw.line((cx-34, y1+87, cx+34, y1+87), fill=WHITE, width=10)
    draw.line((cx, y1+119, cx-27, y1+146), fill=WHITE, width=10)
    draw.line((cx, y1+119, cx+27, y1+146), fill=WHITE, width=10)


def icon_shirt(draw, box):
    x1, y1, x2, y2 = box
    cx = (x1+x2)//2
    pts = [(cx-31,y1+20),(cx-65,y1+42),(cx-48,y1+75),(cx-29,y1+62),(cx-29,y1+137),(cx+29,y1+137),(cx+29,y1+62),(cx+48,y1+75),(cx+65,y1+42),(cx+31,y1+20),(cx+18,y1+38),(cx-18,y1+38)]
    draw.polygon(pts, fill=WHITE)


def icon_apples(draw, box):
    x1, y1, x2, y2 = box
    for dx, dy in ((-34,19),(28,25),(-3,65)):
        cx=(x1+x2)//2+dx; cy=y1+52+dy
        draw.ellipse((cx-25,cy-22,cx+25,cy+26), fill=WHITE)
        draw.line((cx,cy-25,cx+8,cy-40), fill=INK, width=6)


def icon_archive(draw, box):
    x1, y1, x2, y2 = box
    draw.rounded_rectangle((x1+12,y1+31,x2-12,y1+120), radius=10, fill=WHITE)
    draw.rectangle((x1+30,y1+48,x2-30,y1+71), fill=INK)
    for yy in (y1+133,y1+148):
        draw.line((x1+18,yy,x2-18,yy), fill=WHITE, width=6)


def icon_gear(draw, box):
    x1, y1, x2, y2 = box
    cx=(x1+x2)//2; cy=(y1+y2)//2
    draw.ellipse((cx-43,cy-43,cx+43,cy+43), outline=WHITE, width=16)
    draw.ellipse((cx-14,cy-14,cx+14,cy+14), fill=WHITE)
    for dx,dy in ((0,-55),(0,55),(-55,0),(55,0),(-39,-39),(39,39),(-39,39),(39,-39)):
        draw.rounded_rectangle((cx+dx-8,cy+dy-8,cx+dx+8,cy+dy+8), radius=3, fill=WHITE)


def icon_bread(draw, box):
    x1,y1,x2,y2=box
    draw.rounded_rectangle((x1+9,y1+44,x2-9,y1+121), radius=34, fill=WHITE)
    for xx in (x1+52,x1+80,x1+108):
        draw.line((xx,y1+56,xx-12,y1+82), fill=INK, width=6)


def icon_ball(draw, box):
    x1,y1,x2,y2=box
    cx=(x1+x2)//2; cy=(y1+y2)//2
    draw.ellipse((cx-55,cy-55,cx+55,cy+55), fill=WHITE)
    draw.arc((cx-55,cy-55,cx+55,cy+55), 65, 245, fill=INK, width=7)
    draw.arc((cx-55,cy-55,cx+55,cy+55), 245, 425, fill=INK, width=7)
    draw.line((cx,cy-53,cx,cy+53), fill=INK, width=7)


def icon_battery(draw, box):
    x1,y1,x2,y2=box
    draw.rounded_rectangle((x1+16,y1+40,x2-17,y1+120), radius=12, outline=WHITE, width=9)
    draw.rectangle((x2-17,y1+65,x2-5,y1+95), fill=WHITE)
    cx=(x1+x2)//2
    draw.polygon([(cx+5,y1+51),(cx-23,y1+87),(cx-2,y1+87),(cx-10,y1+111),(cx+26,y1+73),(cx+5,y1+73)], fill=WHITE)


def icon_board_game(draw, box):
    x1,y1,x2,y2=box
    draw.rounded_rectangle((x1+13,y1+15,x2-13,y2-10), radius=15, outline=WHITE, width=8)
    draw.ellipse((x1+32,y1+37,x1+66,y1+71), fill=WHITE)
    draw.rectangle((x2-70,y1+38,x2-37,y1+71), fill=WHITE)
    draw.polygon([(x1+49,y2-42),(x1+67,y2-78),(x1+85,y2-42)], fill=WHITE)


def icon_boot(draw, box):
    x1,y1,x2,y2=box
    cx=(x1+x2)//2
    pts=[(cx-37,y1+18),(cx+8,y1+18),(cx+6,y1+91),(cx+54,y1+116),(cx+54,y1+139),(cx-42,y1+139),(cx-51,y1+113),(cx-37,y1+94)]
    draw.polygon(pts, fill=WHITE)
    draw.line((cx-31,y1+73,cx+2,y1+73), fill=INK, width=6)


ICON_DRAWERS = {
    'cargo.accessory_box': icon_accessory,
    'cargo.accessory_carton': icon_carton,
    'cargo.action_figure_box': icon_figure,
    'cargo.apparel_box': icon_shirt,
    'cargo.apple_crate': icon_apples,
    'cargo.archive_box': icon_archive,
    'cargo.auto_part_crate': icon_gear,
    'cargo.bakery_box': icon_bread,
    'cargo.basketball_bag': icon_ball,
    'cargo.battery_pack': icon_battery,
    'cargo.board_game_box': icon_board_game,
    'cargo.boot_carton': icon_boot,
}


def render(asset_id: str, category: str, output: Path) -> str:
    image = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, 'RGBA')
    bag = asset_id == 'cargo.basketball_bag'
    icon_box = draw_package(draw, category, bag=bag)
    ICON_DRAWERS[asset_id](draw, icon_box)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, format='WEBP', quality=QUALITY, method=6, exact=True)
    return hashlib.sha256(output.read_bytes()).hexdigest()


def update_pubspec(paths: list[str]) -> None:
    text = PUBSPEC.read_text(encoding='utf-8')
    marker = '    - assets/maps/world_continents_ai.svg\n'
    if marker not in text:
        raise RuntimeError('pubspec asset insertion marker is missing')
    additions = ''.join(f'    - {path}\n' for path in paths if f'    - {path}\n' not in text)
    if additions:
        text = text.replace(marker, additions + marker)
        PUBSPEC.write_text(text, encoding='utf-8')


def main() -> int:
    descriptors = descriptor_map()
    source_sha = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    records = []
    paths = []
    evidence = []

    for asset_id, concept, category in BATCH:
        descriptor = descriptors.get(asset_id)
        if descriptor is None:
            raise RuntimeError(f'missing manifest descriptor: {asset_id}')
        if descriptor['profile'] != 'pcargo' or descriptor['dimensions'] != {'width': 384, 'height': 384}:
            raise RuntimeError(f'pcargo contract drift: {asset_id}')
        path = descriptor['path']
        if not path.endswith('_v01.webp'):
            raise RuntimeError(f'revision/path contract drift: {asset_id}')
        output = ROOT / path
        export_sha = render(asset_id, category, output)
        paths.append(path)
        evidence.append((asset_id, path, export_sha, output.stat().st_size))
        records.append({
            'assetId': asset_id,
            'runtimePath': path,
            'sourceType': 'generated',
            'creatorVendorTool': 'CARGame deterministic Python/Pillow procedural renderer',
            'creationDate': CREATION_DATE,
            'commercialUseReference': 'Project-original procedural artwork authored specifically for CARGame using only source-controlled geometric drawing instructions; no third-party images, logos, trademarks, or licensed visual material are incorporated.',
            'generation': {
                'prompt': f"Create an original generic 3D-styled cargo package icon for '{concept}' using deterministic geometric primitives, transparent background, upper-left highlight, soft grounded shadow, no logos, no brands, 384x384.",
                'referenceFileIds': [],
            },
            'sourceSha256': source_sha,
            'exportSha256': export_sha,
            'profile': 'pcargo',
            'revision': 1,
            'dimensions': {'width': 384, 'height': 384},
            'encoder': 'Pillow WebP encoder',
            'quality': str(QUALITY),
            'reviewer': 'CARGame source-controlled asset admission review',
            'approvalDate': CREATION_DATE,
            'attribution': '',
            'prohibitedUse': 'Do not present this generic package artwork as a real-world brand, licensed product, or third-party endorsement.',
        })

    PROVENANCE.write_text(json.dumps({'schemaVersion': 1, 'records': records}, indent=2) + '\n', encoding='utf-8')
    update_pubspec(paths)

    lines = [
        '# AST-007 Batch 01 — project-original procedural cargo art',
        '',
        'Issue: #210',
        '',
        f'Generator SHA-256: `{source_sha}`',
        f'Encoder: Pillow WebP, quality {QUALITY}, exact RGBA, 384x384.',
        '',
        'The batch is generated only from source-controlled geometric drawing primitives. No third-party image, logo, trademark, model, or licensed visual source is incorporated.',
        '',
        '| Asset | Runtime path | Bytes | SHA-256 |',
        '|---|---|---:|---|',
    ]
    lines.extend(f'| `{asset_id}` | `{path}` | {size} | `{digest}` |' for asset_id, path, digest, size in evidence)
    lines.extend([
        '',
        '## Acceptance boundary',
        '',
        '- Gameplay archetype IDs, level generation, moves, difficulty, rewards, persistence and matching remain unchanged.',
        '- These 12 assets are the first runtime-binary admission checkpoint; AST-007 remains IN PROGRESS until the full production pack is admitted.',
        '- No physical-device visual/performance acceptance is claimed by this source-controlled batch.',
    ])
    WORK.parent.mkdir(parents=True, exist_ok=True)
    WORK.write_text('\n'.join(lines) + '\n', encoding='utf-8')

    print(f'AST-007 batch 01 generated: {len(records)} assets')
    print(f'generator sha256: {source_sha}')
    for asset_id, path, digest, size in evidence:
        print(f'{asset_id}: {size} bytes sha256={digest} path={path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
