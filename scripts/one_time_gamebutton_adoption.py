from pathlib import Path


def add_import(path: str, anchor: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    game_button_import = "import '../../core/widgets/game_button.dart';\n"
    if game_button_import not in text:
        if anchor not in text:
            raise SystemExit(f"Import anchor missing in {path}")
        text = text.replace(anchor, anchor + game_button_import, 1)
    target.write_text(text, encoding="utf-8")


def replace_class_to_eof(path: str, marker: str, replacement: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"Class marker missing in {path}: {marker}")
    target.write_text(text[:start] + replacement.rstrip() + "\n", encoding="utf-8")


add_import(
    "lib/features/home/home_screen.dart",
    "import '../../core/theme/three_d_game_icon.dart';\n",
)
replace_class_to_eof(
    "lib/features/home/home_screen.dart",
    "class _StartJourneyButton extends StatelessWidget",
    r'''class _StartJourneyButton extends StatelessWidget {
  const _StartJourneyButton({
    required this.ar,
    required this.compact,
    required this.busy,
    required this.enabled,
    required this.cityName,
    required this.onPressed,
  });

  final bool ar;
  final bool compact;
  final bool busy;
  final bool enabled;
  final String cityName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: GameButton(
            semanticLabel: enabled
                ? (ar
                    ? 'ابدأ المرحلة التالية: $cityName'
                    : 'Start next city: $cityName')
                : (ar ? 'لا توجد قلوب' : 'No hearts'),
            onPressed: enabled ? onPressed : null,
            enabled: enabled,
            loading: busy,
            expand: true,
            height: compact ? 70 : 78,
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFFFFB62E), Color(0xFFF06419)]
                  : const [Color(0xFFB8BEC7), Color(0xFF8C939D)],
            ),
            shadowColor: const Color(0x66E76B17),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enabled
                            ? (ar
                                ? 'ابدأ المرحلة التالية'
                                : 'START NEXT CITY')
                            : (ar ? 'لا توجد قلوب' : 'NO HEARTS'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 17 : 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),
                      Text(
                        cityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const ThreeDGameIcon(
                  type: ThreeDIconType.chest,
                  size: 52,
                ),
              ],
            ),
          ),
        ),
      );
}''',
)

add_import(
    "lib/features/levels/city_briefing_screen.dart",
    "import '../../core/theme/three_d_game_icon.dart';\n",
)
replace_class_to_eof(
    "lib/features/levels/city_briefing_screen.dart",
    "class _StartMissionButton extends StatelessWidget",
    r'''class _StartMissionButton extends StatelessWidget {
  const _StartMissionButton({
    required this.enabled,
    required this.loading,
    required this.skinColor,
    required this.isArabic,
    required this.cityName,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final Color skinColor;
  final bool isArabic;
  final String cityName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GameButton(
        semanticLabel: enabled
            ? (isArabic
                ? 'ابدأ مهمة $cityName'
                : 'Start mission $cityName')
            : (isArabic ? 'لا توجد قلوب' : 'No hearts'),
        onPressed: enabled ? onPressed : null,
        enabled: enabled,
        loading: loading,
        expand: true,
        height: 68,
        borderRadius: BorderRadius.circular(24),
        backgroundColor: skinColor,
        disabledColor: skinColor.withValues(alpha: .35),
        shadowColor: skinColor.withValues(alpha: .42),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              size: 34,
              color: Colors.white,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    enabled
                        ? (isArabic ? 'ابدأ المهمة' : 'START MISSION')
                        : (isArabic ? 'لا توجد قلوب' : 'NO HEARTS'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}''',
)

add_import(
    "lib/features/shop/shop_screen.dart",
    "import '../../core/theme/three_d_game_icon.dart';\n",
)
shop_path = Path("lib/features/shop/shop_screen.dart")
shop_text = shop_path.read_text(encoding="utf-8")
old_shop = """          trailing: FilledButton(
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThreeDGameIcon(
                  type: ThreeDIconType.coin,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text('$price'),
              ],
            ),
          ),"""
new_shop = """          trailing: GameButton(
            semanticLabel: 'Buy $title for $price coins',
            onPressed: onTap,
            height: 46,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            borderRadius: BorderRadius.circular(16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThreeDGameIcon(
                  type: ThreeDIconType.coin,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  '$price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),"""
if old_shop not in shop_text:
    raise SystemExit("Shop booster button target missing")
shop_path.write_text(shop_text.replace(old_shop, new_shop, 1), encoding="utf-8")

status_path = Path("docs/STATUS.md")
status = status_path.read_text(encoding="utf-8")
status = status.replace(
    "| Integrated screen | Settings |",
    "| Integrated screens | Settings, Home Start, Mission Start, Shop booster purchase |",
)
status = status.replace(
    "| Next checkpoint | Adopt `GameButton` in Home Start, mission launch, result Next/Retry, and shop purchase flows after the current CI run passes. |",
    "| Next checkpoint | Adopt `GameButton` in result Next/Retry and remaining theme/heart purchase flows, then close MOT-003 after device verification. |",
)
marker = "- Settings language, privacy, and about actions now use the shared component.\n"
addition = marker + (
    "- Home Start, Mission Start, and booster purchase CTAs now use the shared "
    "motion, loading, semantics, and async guard.\n"
)
if marker in status and addition not in status:
    status = status.replace(marker, addition, 1)
status_path.write_text(status, encoding="utf-8")

Path("scripts/one_time_gamebutton_adoption.py").unlink()
Path(".github/workflows/one_time_gamebutton_adoption.yml").unlink()
