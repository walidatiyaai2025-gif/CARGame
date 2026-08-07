from pathlib import Path

catalog_path = Path('docs/FEATURE_CATALOG.md')
catalog = catalog_path.read_text(encoding='utf-8')
catalog = catalog.replace(
    '| HOME-002 | Responsive Start button | P0 | IMPLEMENTED | HOME-001 | No overflow and repeated navigation is guarded; device matrix test remains. |',
    '| HOME-002 | Responsive Start button | P0 | IMPLEMENTED | HOME-001 | Home is fit-to-screen without a scroll container on 360x640 and 412x915 regression sizes; compact resources/hero preserve the guarded Start action; physical-device matrix remains. |',
)
ads_anchor = '| ADS-009 | Ad-free failure and fallback UX | P1 | PLANNED | ADS-001 | Unavailable/no-fill/network errors return immediately to a valid non-blocking UI state. |'
ads_new = ads_anchor + '\n| ADS-010 | Home banner ad footer | P1 | IMPLEMENTED | ADS-001, ENG-014 | Home uses a Google banner footer with official debug test ID; it reserves no space until loaded and no-fill/offline leaves core play usable. Production ID injection remains governed by ADS-002. |'
if '| ADS-010 |' not in catalog:
    if ads_anchor not in catalog:
        raise SystemExit('ADS-009 anchor missing')
    catalog = catalog.replace(ads_anchor, ads_new, 1)
catalog_path.write_text(catalog, encoding='utf-8')

status_path = Path('docs/STATUS.md')
status = status_path.read_text(encoding='utf-8')
summary = '''\n## Fullscreen home + banner checkpoint — 2026-08-07\n\n- Android/iOS app shell requests immersive-sticky fullscreen at startup while retaining portrait orientation policy.\n- Home no longer uses a ListView/scroll container; content scales down as one bounded composition and compact resource/hero cards reclaim vertical space.\n- Google Mobile Ads banner footer is isolated from offline core play, uses official debug test IDs, and occupies no footer space until an ad actually loads.\n- Full checkpoint verification passed in GitHub Actions: Dart format, Flutter Analyze with no issues, full Flutter tests, and Debug APK build.\n- Added regression coverage for 360x640 and 412x915 home layouts with no ListView/SingleChildScrollView and no captured Flutter layout exception.\n- Release ad unit injection/consent remain separate ADS-002/ADS-007 work and are not claimed complete.\n'''
if '## Fullscreen home + banner checkpoint — 2026-08-07' not in status:
    status = status.rstrip() + '\n' + summary
status_path.write_text(status, encoding='utf-8')
