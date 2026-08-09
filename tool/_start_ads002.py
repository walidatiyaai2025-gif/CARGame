from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| ADS-002 | Debug test IDs and release configuration | P0 | PLANNED | ADS-001, ENG-009 | Test ads run in debug and production IDs are injected safely in release. |'
new = '| ADS-002 | Debug test IDs and release configuration | P0 | IN PROGRESS | ADS-001, ENG-009 | Issue #116 audits debug Google test IDs, runtime AdService wiring, Android manifest/Gradle injection, and release fail-closed validation. Current gap: typed Dart release configuration rejects empty/Google-test IDs but does not reject malformed non-test ad-unit IDs when builds bypass the RC preflight. |'
if old not in text:
    raise SystemExit('ADS-002 catalog row not found')
catalog.write_text(text.replace(old, new), encoding='utf-8')

status = Path('docs/STATUS.md')
s = status.read_text(encoding='utf-8')
s = s.replace('| Primary feature | None after `ENG-010` verification; next RC P0 audit is `ADS-002` debug/release ad configuration. |', '| Primary feature | `ADS-002` debug test IDs and release ad configuration — issue #116. |')
s = s.replace('| Next recommended feature | Audit `ADS-002` against the existing ENG-009 release configuration so debug uses only public test IDs and release requires injected production IDs without fallback. |', '| Next recommended feature | Finish `ADS-002` typed release ad-unit format validation and configuration regression coverage, then reconcile the existing Android manifest/Gradle/preflight evidence. |')
status.write_text(s, encoding='utf-8')
