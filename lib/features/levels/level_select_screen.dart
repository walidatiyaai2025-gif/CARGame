import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../l10n/app_localizations.dart';
import '../game/game_screen.dart';
import '../game/level_data.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.store});
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.levels)),
      body: AnimatedBuilder(
        animation: store,
        builder: (_, _) => GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: levels.length,
          itemBuilder: (_, index) {
            final level = levels[index];
            final unlocked = level.number <= store.highestUnlockedLevel;
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: unlocked ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(level: level, store: store))) : null,
              child: Card(
                color: unlocked ? Theme.of(context).colorScheme.primaryContainer : Colors.black12,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(unlocked ? Icons.inventory_2_rounded : Icons.lock_rounded, size: 44),
                      const SizedBox(height: 12),
                      Text('${l10n.level} ${level.number}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(unlocked ? '${level.moves} ${l10n.moves}' : l10n.locked),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
