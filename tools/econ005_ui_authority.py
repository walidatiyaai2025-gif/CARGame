from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f"Missing {label} anchor")
    return text.replace(old, new, 1)


# Config copyWith: expose the values used by UI regression injection.
path = Path('lib/core/economy/economy_config.dart')
text = path.read_text()
text = replace_once(
    text,
    """    int? playerLevelXpStep,
    int? dailyRewardCoins,
    int? dailyMissionRewardCoins,
""",
    """    int? playerLevelXpStep,
    int? dailyMissionRequiredWins,
    int? dailyMissionRequiredStars,
    int? dailyMissionRequiredCoins,
    int? dailyRewardCoins,
    int? dailyMissionRewardCoins,
""",
    'copyWith args',
)
text = replace_once(
    text,
    """    playerLevelXpStep: playerLevelXpStep ?? this.playerLevelXpStep,
    dailyMissionRequiredWins: dailyMissionRequiredWins,
    dailyMissionRequiredStars: dailyMissionRequiredStars,
    dailyMissionRequiredCoins: dailyMissionRequiredCoins,
""",
    """    playerLevelXpStep: playerLevelXpStep ?? this.playerLevelXpStep,
    dailyMissionRequiredWins:
        dailyMissionRequiredWins ?? this.dailyMissionRequiredWins,
    dailyMissionRequiredStars:
        dailyMissionRequiredStars ?? this.dailyMissionRequiredStars,
    dailyMissionRequiredCoins:
        dailyMissionRequiredCoins ?? this.dailyMissionRequiredCoins,
""",
    'copyWith targets',
)
path.write_text(text)

# Store-derived world completion should use the configured world boundary.
path = Path('lib/core/storage/progress_store.dart')
text = path.read_text()
text = replace_once(
    text,
    '  int get worldsCompleted => completedLevels ~/ 25;',
    '  int get worldsCompleted => completedLevels ~/ economy.worldInterval;',
    'world completion interval',
)
path.write_text(text)

# ProgressHub renders the same authoritative config that drives the domain.
path = Path('lib/features/progress/progress_hub_screen.dart')
text = path.read_text()
text = replace_once(
    text,
    """              label: ar ? 'اربح 3 مدن' : 'Win 3 cities',
              value: store.missionWins,
              target: 3,
""",
    """              label: ar
                  ? 'اربح ${store.economy.dailyMissionRequiredWins} مدن'
                  : 'Win ${store.economy.dailyMissionRequiredWins} cities',
              value: store.missionWins,
              target: store.economy.dailyMissionRequiredWins,
""",
    'mission wins display',
)
text = replace_once(
    text,
    """              label: ar ? 'اجمع 6 نجوم' : 'Earn 6 stars',
              value: store.missionStars,
              target: 6,
""",
    """              label: ar
                  ? 'اجمع ${store.economy.dailyMissionRequiredStars} نجوم'
                  : 'Earn ${store.economy.dailyMissionRequiredStars} stars',
              value: store.missionStars,
              target: store.economy.dailyMissionRequiredStars,
""",
    'mission stars display',
)
text = replace_once(
    text,
    """              label: ar ? 'اجمع 150 عملة' : 'Earn 150 coins',
              value: store.missionCoins,
              target: 150,
""",
    """              label: ar
                  ? 'اجمع ${store.economy.dailyMissionRequiredCoins} عملة'
                  : 'Earn ${store.economy.dailyMissionRequiredCoins} coins',
              value: store.missionCoins,
              target: store.economy.dailyMissionRequiredCoins,
""",
    'mission coins display',
)
text = replace_once(
    text,
    """                  : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins'),
""",
    """                  : (ar
                        ? 'استلم ${store.economy.dailyMissionRewardCoins} عملة'
                        : 'Claim ${store.economy.dailyMissionRewardCoins} Coins'),
""",
    'mission semantic reward',
)
text = replace_once(
    text,
    """                          : (ar ? 'استلم 200 عملة' : 'Claim 200 Coins'),
""",
    """                          : (ar
                                ? 'استلم ${store.economy.dailyMissionRewardCoins} عملة'
                                : 'Claim ${store.economy.dailyMissionRewardCoins} Coins'),
""",
    'mission button reward',
)
text = replace_once(
    text,
    "    subtitle: '${store.xpIntoCurrentLevel}/500 XP',",
    "    subtitle: '${store.xpIntoCurrentLevel}/${store.economy.playerLevelXpStep} XP',",
    'player XP display',
)
text = text.replace('ProgressStore.maxHearts', 'store.economy.maxHearts')
path.write_text(text)

# HomeScreen removes the remaining economy literals from the summary surface.
path = Path('lib/features/home/home_screen.dart')
text = path.read_text()
text = replace_once(
    text,
    '          final worldNumber = ((unlocked - 1) ~/ 25 + 1).clamp(',
    '          final worldNumber =\n              ((unlocked - 1) ~/ store.economy.worldInterval + 1).clamp(',
    'home world interval',
)
text = replace_once(
    text,
    """                              hearts:
                                  '${store.hearts}/${ProgressStore.maxHearts}',
""",
    """                              hearts:
                                  '${store.hearts}/${store.economy.maxHearts}',
""",
    'home heart cap',
)
text = replace_once(
    text,
    """                              missionText:
                                  '${store.missionWins}/3 • ${store.missionStars}/6',
                              onDaily: _claimDailyReward,
""",
    """                              missionText:
                                  '${store.missionWins}/${store.economy.dailyMissionRequiredWins} • ${store.missionStars}/${store.economy.dailyMissionRequiredStars}',
                              dailyRewardCoins: store.economy.dailyRewardCoins,
                              onDaily: _claimDailyReward,
""",
    'home mission summary',
)
text = replace_once(
    text,
    """    required this.missionClaimed,
    required this.missionText,
    required this.onDaily,
""",
    """    required this.missionClaimed,
    required this.missionText,
    required this.dailyRewardCoins,
    required this.onDaily,
""",
    'quick actions ctor',
)
text = replace_once(
    text,
    """  final bool missionClaimed;
  final String missionText;
  final VoidCallback onDaily;
""",
    """  final bool missionClaimed;
  final String missionText;
  final int dailyRewardCoins;
  final VoidCallback onDaily;
""",
    'quick actions field',
)
text = replace_once(
    text,
    "        subtitle: dailyClaimed ? (ar ? 'تم الاستلام' : 'Claimed') : '+50',",
    """        subtitle: dailyClaimed
            ? (ar ? 'تم الاستلام' : 'Claimed')
            : '+$dailyRewardCoins',""",
    'daily reward display',
)
path.write_text(text)

# Widget regression injects non-v1 values to prove display is config-bound.
path = Path('test/features/progress/progress_hub_game_panel_test.dart')
text = path.read_text()
text = replace_once(
    text,
    "import 'package:cargo_sort_game/core/storage/progress_store.dart';",
    "import 'package:cargo_sort_game/core/economy/economy_config.dart';\nimport 'package:cargo_sort_game/core/storage/progress_store.dart';",
    'progress widget economy import',
)
text = replace_once(
    text,
    """      final store = ProgressStore();

      await tester.pumpWidget(
""",
    """      final economy = EconomyConfig.current.copyWith(
        maxHearts: 7,
        playerLevelXpStep: 750,
        dailyMissionRequiredWins: 4,
        dailyMissionRequiredStars: 8,
        dailyMissionRequiredCoins: 240,
        dailyMissionRewardCoins: 333,
      );
      final store = ProgressStore(economy: economy);

      await tester.pumpWidget(
""",
    'progress widget custom config',
)
text = replace_once(text, "      expect(find.text('Win 3 cities'), findsOneWidget);", "      expect(find.text('Win 4 cities'), findsOneWidget);", 'wins assertion')
text = text.replace("find.text('Earn 150 coins')", "find.text('Earn 240 coins')")
text = replace_once(
    text,
    "      expect(find.text('Performance Summary'), findsOneWidget);",
    """      expect(find.text('Performance Summary'), findsOneWidget);
      expect(find.text('0/750 XP'), findsOneWidget);""",
    'XP assertion',
)
text = replace_once(
    text,
    """      expect(
        find.ancestor(
          of: find.text('Earn 240 coins'),
          matching: find.byType(GamePanel),
        ),
        findsOneWidget,
      );
""",
    """      expect(
        find.ancestor(
          of: find.text('Earn 240 coins'),
          matching: find.byType(GamePanel),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Claim 333 Coins'),
        250,
        scrollable: scrollable,
      );
      await tester.pump();
      expect(find.text('Claim 333 Coins'), findsOneWidget);
""",
    'mission reward assertion',
)
path.write_text(text)
