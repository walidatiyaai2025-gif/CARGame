from pathlib import Path

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old = '| ADS-007 | Consent/privacy integration | P1 | IN PROGRESS | ADS-002, PRIV-001 | Issue #166: UMP consent must gate Mobile Ads initialization and every ad request; privacy options must be re-openable from Settings; first-party analytics remains disabled until ENG-012. |'
new = '| ADS-007 | Consent/privacy integration | P1 | IMPLEMENTED | ADS-002, PRIV-001 | Issue #166 / PR #167 implement Google UMP launch refresh/required forms, `canRequestAds` gating before Mobile Ads initialization and all app-owned banner/rewarded/interstitial requests, runtime revocation disposal, re-openable Settings privacy options, and no first-party analytics. Focused probe `31331329428` passed 12 consent/privacy tests plus privacy/security/Analyze checks. Flutter CI #742 / run `31331414894` passed all gates, full Flutter suite, Debug APK build, SEC-002 artifact scan and upload; artifact #9043116329 is 80,608,682 bytes with SHA-256 `60ec4df1b88a24bfe2b19e0019ba05d07b4c99a17aa6a91479151895a023840a`. PR #167 squash-merged as `865a31a8790c1b93b550f4da49f4e7d9f4720b28`. Client integration is complete; production AdMob Privacy & messaging configuration and regulated-region/device verification remain external before VERIFIED. |'
if old not in text:
    raise SystemExit('ADS-007 row mismatch')
text = text.replace(old, new, 1)
old = '- `ADS-007` Consent/privacy integration — P1; `ADS-002` and `PRIV-001` are VERIFIED. It is the first catalog-ordered dependency-ready blocker remaining before `TEST-011`; `PRIV-003` remains the other required blocker.'
new = '- `PRIV-002` Privacy policy and Play Data safety mapping — P0; `PRIV-001` is VERIFIED and ADS-007 client integration is IMPLEMENTED. It is the highest-priority dependency-ready feature, while final policy publication/store-console evidence remains external.'
if old not in text:
    raise SystemExit('NEXT READY mismatch')
text = text.replace(old, new, 1)
old = '- `PRIV-002` remains blocked on `ADS-007`; policy/store disclosures must match the final consent-aware ad SDK behavior.\n'
if old not in text:
    raise SystemExit('PRIV-002 blocked bullet mismatch')
text = text.replace(old, '', 1)
old = '- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied and SEC-002 is now VERIFIED, but acceptance remains blocked until ADS-007 consent and PRIV-003 deletion controls are complete.'
new = '- `TEST-011` has its declared PRIV-001/SEC-001 prerequisites satisfied and SEC-002 is VERIFIED, but acceptance still cannot pass until ADS-007 production UMP/privacy-message behavior is verified and PRIV-003 deletion/export controls are complete.'
if old not in text:
    raise SystemExit('TEST-011 blocked bullet mismatch')
text = text.replace(old, new, 1)
marker = '## Recently implemented\n\n'
addition = '- `ADS-007` Consent/privacy integration — issue #166 / PR #167 add UMP consent refresh, fail-closed Mobile Ads request gating, runtime privacy-option changes, responsive Settings privacy controls, and executable privacy/security source contracts. Flutter CI #742 passed full tests and Debug APK artifact scanning; production AdMob Privacy & messaging configuration and regulated-region/device evidence remain before VERIFIED.\n'
if marker not in text:
    raise SystemExit('Recently implemented marker missing')
text = text.replace(marker, marker + addition, 1)
catalog.write_text(text, encoding='utf-8')

status = Path('docs/STATUS.md')
text = status.read_text(encoding='utf-8')
replacements = {
    '| Primary feature | `ADS-007` Consent/privacy integration — Issue #166 / branch `agent/ads-007-consent-privacy`. |': '| Primary feature | None — ADS-007 client integration is IMPLEMENTED; PRIV-002 is the next highest-priority dependency-ready feature. |',
    '| Completed checkpoint | `SEC-002` dependency, secret, and artifact security scans — PR #164 merged as `5b96ee94f1d82a36bb6bbffd53b7719b64c175d3` after green Flutter CI #738 and Release Packaging Smoke #7. |': '| Completed checkpoint | `ADS-007` consent/privacy client integration — PR #167 merged as `865a31a8790c1b93b550f4da49f4e7d9f4720b28` after green Flutter CI #742. |',
    '| Status | ADS-007 is IN PROGRESS: implement UMP consent before Mobile Ads initialization/requests, runtime fail-closed ad eligibility, and re-openable privacy options from Settings. |': '| Status | ADS-007 is IMPLEMENTED: UMP gates Mobile Ads initialization and app-owned ad requests and Settings can re-open required privacy options. Production AdMob Privacy & messaging configuration plus regulated-region/device verification remain external before VERIFIED. |',
    '| Next recommended feature | Complete `ADS-007` first. `TEST-011` remains blocked by ADS-007 and PRIV-003; PRIV-003 is the next remaining dependency-ready blocker after consent integration. |': '| Next recommended feature | `PRIV-002` Privacy policy and Play Data safety mapping — P0, now dependency-ready after ADS-007 client integration. `TEST-011` remains an acceptance target but still waits on production consent verification and PRIV-003 deletion/export readiness. |',
}
for old_value, new_value in replacements.items():
    if old_value not in text:
        raise SystemExit(f'STATUS mismatch: {old_value[:60]}')
    text = text.replace(old_value, new_value, 1)
marker = '## SEC-002 security scan verification — 2026-08-09\n'
section = '''## ADS-007 consent/privacy client integration — 2026-08-09\n\n- Issue #166 / PR #167 add Google UMP as the runtime privacy source of truth without persisting a duplicate app-side consent-granted value.\n- Launch refreshes consent info and shows required UMP forms before Mobile Ads initialization; `canRequestAds` gates SDK startup plus banner/rewarded/interstitial app-owned request/load/show paths.\n- Loaded app-owned ads are disposed when eligibility is revoked, and Settings exposes a publisher privacy entry that re-opens Google privacy options when required; choices update request eligibility without restart.\n- First-party analytics remains absent/disabled; ENG-012 remains the owner of any future analytics event collection and privacy gate.\n- Focused implementation/UI probe `31331329428` passed 12 consent/request/composition/Settings tests, privacy inventory validation (6 flows, 2 processors, 33 persisted key families), security baseline validation, Analyze and whitespace checks.\n- Flutter CI #742 / run `31331414894` passed privacy/security/dependency/dashboard/assets/format/Analyze gates, the full Flutter suite, Debug APK build, SEC-002 packaged-artifact security scan and upload on head `af3edcba29919151e83a3d59f614faa41eb06a7c`.\n- Debug artifact #9043116329 is 80,608,682 bytes with SHA-256 `60ec4df1b88a24bfe2b19e0019ba05d07b4c99a17aa6a91479151895a023840a`.\n- PR #167 squash-merged to main as `865a31a8790c1b93b550f4da49f4e7d9f4720b28`.\n- ADS-007 remains IMPLEMENTED rather than VERIFIED because actual production AdMob Privacy & messaging configuration and regulated-region/device behavior are external to this repository; Issue #166 remains open for that evidence.\n- Post-merge dependency audit `31331857275` identifies PRIV-002 as the next P0 dependency-ready feature. TEST-011 is not selected despite its declared dependencies because its acceptance still requires production consent verification and PRIV-003 deletion/export controls.\n\n'''
if marker not in text:
    raise SystemExit('STATUS insertion marker missing')
text = text.replace(marker, section + marker, 1)
status.write_text(text, encoding='utf-8')

work = Path('docs/work/ADS-007.md')
text = work.read_text(encoding='utf-8')
text = text.replace('State: IN PROGRESS', 'State: IMPLEMENTED', 1)
text += '''\n## Verification evidence\n\n- Focused implementation/UI probe `31331329428`: 12/12 consent/request/composition/Settings tests GREEN; privacy inventory, security baseline, Analyze and whitespace GREEN.\n- Flutter CI #742 / run `31331414894`: full pipeline, full Flutter suite, Debug APK build, SEC-002 artifact scan and upload GREEN.\n- Debug artifact #9043116329: 80,608,682 bytes; SHA-256 `60ec4df1b88a24bfe2b19e0019ba05d07b4c99a17aa6a91479151895a023840a`.\n- Implementation PR #167 squash-merged as `865a31a8790c1b93b550f4da49f4e7d9f4720b28`.\n- Client acceptance is implemented and CI-verified. Production AdMob Privacy & messaging configuration and regulated-region/device behavior remain external release evidence, so ADS-007 is not marked VERIFIED yet and Issue #166 remains open.\n- Next queue audit `31331857275`: PRIV-002 is the next P0 dependency-ready feature; TEST-011 remains acceptance-blocked by production consent verification plus PRIV-003.\n'''
work.write_text(text, encoding='utf-8')
