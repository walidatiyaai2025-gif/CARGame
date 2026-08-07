from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text(encoding='utf-8')
    if old not in text:
        raise SystemExit(f'Expected text not found in {path}')
    target.write_text(text.replace(old, new, 1), encoding='utf-8')


def add_import(path: str, anchor: str, addition: str) -> None:
    target = Path(path)
    text = target.read_text(encoding='utf-8')
    if addition in text:
        return
    if anchor not in text:
        raise SystemExit(f'Import anchor not found in {path}')
    target.write_text(text.replace(anchor, anchor + addition, 1), encoding='utf-8')


add_import(
    'lib/features/game/game_screen.dart',
    "import '../../core/theme/game_skin.dart';\n",
    "import '../../core/widgets/game_button.dart';\n",
)

old_result = '''                    if (!won) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _resultActionBusy
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  _ads.showRewarded(
                                    onReward: () {
                                      if (!mounted) return;
                                      setState(() {
                                        _finished = false;
                                        _resultVisible = false;
                                        _moves += 5;
                                      });
                                    },
                                  );
                                },
                          icon: const Icon(Icons.ondemand_video_rounded),
                          label: Text(ar ? 'شاهد إعلانًا وخذ 5 حركات' : 'Watch ad for 5 moves'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _resultActionBusy
                            ? null
                            : () async {
                                if (won) {
                                  await _closeResultAndReturnToMap(sheetContext);
                                } else {
                                  await _retryFromResult(sheetContext);
                                }
                              },
                        icon: _resultActionBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : Icon(won ? Icons.navigate_next_rounded : Icons.restart_alt_rounded),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            won
                                ? (ar ? 'التالي — العودة للخريطة' : 'NEXT — BACK TO MAP')
                                : (ar ? 'إعادة المحاولة' : 'RETRY'),
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),'''

new_result = '''                    if (!won) ...[
                      GameButton(
                        semanticLabel: ar
                            ? 'شاهد إعلانًا وخذ خمس حركات'
                            : 'Watch ad for five moves',
                        onPressed: _resultActionBusy
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                _ads.showRewarded(
                                  onReward: () {
                                    if (!mounted) return;
                                    setState(() {
                                      _finished = false;
                                      _resultVisible = false;
                                      _moves += 5;
                                    });
                                  },
                                );
                              },
                        enabled: !_resultActionBusy,
                        expand: true,
                        height: 52,
                        borderRadius: BorderRadius.circular(18),
                        backgroundColor: Colors.white,
                        foregroundColor: skin.primary,
                        border: Border.all(color: skin.primary.withValues(alpha: .35)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ondemand_video_rounded),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                ar ? 'شاهد إعلانًا وخذ 5 حركات' : 'Watch ad for 5 moves',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    GameButton(
                      semanticLabel: won
                          ? (ar ? 'التالي والعودة للخريطة' : 'Next and back to map')
                          : (ar ? 'إعادة المحاولة' : 'Retry'),
                      onPressed: _resultActionBusy
                          ? null
                          : () async {
                              if (won) {
                                await _closeResultAndReturnToMap(sheetContext);
                              } else {
                                await _retryFromResult(sheetContext);
                              }
                            },
                      enabled: !_resultActionBusy,
                      loading: _resultActionBusy,
                      expand: true,
                      height: 56,
                      borderRadius: BorderRadius.circular(20),
                      backgroundColor: skin.primary,
                      shadowColor: skin.primary.withValues(alpha: .38),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            won ? Icons.navigate_next_rounded : Icons.restart_alt_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              won
                                  ? (ar ? 'التالي — العودة للخريطة' : 'NEXT — BACK TO MAP')
                                  : (ar ? 'إعادة المحاولة' : 'RETRY'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),'''
replace_once('lib/features/game/game_screen.dart', old_result, new_result)

old_offer = '''  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ThreeDGameIcon(
              type: iconType,
              size: 54,
              animate: true,
              semanticLabel: title,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ThreeDGameIcon(type: ThreeDIconType.coin, size: 24),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle.replaceAll(' coins', ''),
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );'''

new_offer = '''  @override
  Widget build(BuildContext context) => GameButton(
    semanticLabel: 'Buy $title, $subtitle',
    onPressed: onTap,
    expand: true,
    borderRadius: BorderRadius.circular(24),
    backgroundColor: Colors.white,
    foregroundColor: AppTheme.navy,
    shadowColor: Colors.black12,
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        ThreeDGameIcon(
          type: iconType,
          size: 54,
          animate: true,
          semanticLabel: title,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ThreeDGameIcon(type: ThreeDIconType.coin, size: 24),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                subtitle.replaceAll(' coins', ''),
                style: const TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );'''
replace_once('lib/features/shop/shop_screen.dart', old_offer, new_offer)

old_theme = '''  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [offer.start, offer.end]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(offer.icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.name,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    offer.subtitle,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.green.withValues(alpha: .13)
                    : AppTheme.orange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: selected
                  ? const Text(
                      'Selected',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : unlocked
                  ? const Text(
                      'Use',
                      style: TextStyle(
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThreeDGameIcon(
                          type: ThreeDIconType.coin,
                          size: 20,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${offer.price}',
                          style: const TextStyle(
                            color: AppTheme.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );'''

new_theme = '''  @override
  Widget build(BuildContext context) => GameButton(
    semanticLabel: selected
        ? '${offer.name}, selected'
        : unlocked
        ? 'Use ${offer.name}'
        : 'Buy ${offer.name} for ${offer.price} coins',
    onPressed: selected ? null : onTap,
    enabled: !selected,
    expand: true,
    borderRadius: BorderRadius.circular(24),
    backgroundColor: Colors.white,
    disabledColor: Colors.white,
    foregroundColor: AppTheme.navy,
    shadowColor: Colors.black12,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [offer.start, offer.end]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(offer.icon, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.name,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                offer.subtitle,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.green.withValues(alpha: .13)
                : AppTheme.orange.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: selected
              ? const Text(
                  'Selected',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : unlocked
              ? const Text(
                  'Use',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThreeDGameIcon(type: ThreeDIconType.coin, size: 20),
                    const SizedBox(width: 3),
                    Text(
                      '${offer.price}',
                      style: const TextStyle(
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );'''
replace_once('lib/features/shop/shop_screen.dart', old_theme, new_theme)

catalog = Path('docs/FEATURE_CATALOG.md')
text = catalog.read_text(encoding='utf-8')
old_catalog = '| MOT-003 | Universal Button Motion System | P0 | IN PROGRESS | UI3D-003, MOT-002 | All major Start, launch, Next, Retry, purchase, and settings actions use shared `GameButton` behavior with no duplicated button-motion implementation; Settings adoption and 5 focused tests are complete. |'
new_catalog = '| MOT-003 | Universal Button Motion System | P0 | IMPLEMENTED | UI3D-003, MOT-002 | Major Start, mission launch, Next, Retry, rewarded continuation, heart/booster/theme purchase, and settings actions use shared `GameButton`; focused tests and CI verification exist, while physical-device motion review remains. |'
if old_catalog not in text:
    raise SystemExit('MOT-003 catalog row not found')
catalog.write_text(text.replace(old_catalog, new_catalog, 1), encoding='utf-8')

status = Path('docs/STATUS.md')
text = status.read_text(encoding='utf-8')
text = text.replace(
    '| Status | IMPLEMENTED checkpoint; final CI run pending |',
    '| Status | IMPLEMENTED across major CTAs; final CI and physical-device review pending |',
)
text = text.replace(
    '| Next checkpoint | Adopt `GameButton` in result Next/Retry and remaining theme/heart purchase flows, then close MOT-003 after device verification. |',
    '| Next checkpoint | Complete CI, test motion on a physical Android device, then promote MOT-003 to VERIFIED if acceptance remains satisfied. |',
)
marker = '- Home Start, Mission Start, and booster purchase CTAs now use the same shared motion, loading, semantics, and async guard.\n'
addition = marker + '- Result Next/Retry, rewarded continuation, heart purchases, and theme selection/purchase now use the same shared component.\n'
if marker in text and addition not in text:
    text = text.replace(marker, addition, 1)
status.write_text(text, encoding='utf-8')

Path('scripts/one_time_gamebutton_finish.py').unlink()
Path('.github/workflows/one_time_gamebutton_finish.yml').unlink()
