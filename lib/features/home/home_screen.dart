import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../levels/level_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onToggleLanguage,
  });

  final ProgressStore store;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedBuilder(
                    animation: store,
                    builder: (_, __) => Chip(
                      avatar: const Icon(Icons.monetization_on_rounded, color: AppTheme.orange),
                      label: Text('${l10n.coins}: ${store.coins}'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onToggleLanguage,
                    icon: const Icon(Icons.language_rounded),
                    label: Text(l10n.language),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: const [
                    BoxShadow(blurRadius: 30, offset: Offset(0, 16), color: Color(0x33223344)),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.warehouse_rounded, size: 110, color: Colors.white),
                    Positioned(right: 24, bottom: 24, child: Icon(Icons.inventory_2_rounded, size: 48, color: AppTheme.orange)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.appTitle, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: AppTheme.navy)),
              Text(l10n.subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelSelectScreen(store: store))),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.play),
              ),
              const SizedBox(height: 12),
              Text(l10n.testAds, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(l10n.privacyNote, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}
