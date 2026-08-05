import 'package:flutter/material.dart';

import '../../core/logging/log_viewer_screen.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final welcomeText = isArabic ? 'مرحبًا أيها المستخدم' : 'Welcome, user';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedBuilder(
                    animation: store,
                    builder: (_, _) => Chip(
                      avatar: const Icon(
                        Icons.monetization_on_rounded,
                        color: AppTheme.orange,
                      ),
                      label: Text('${l10n.coins}: ${store.coins}'),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Application logs',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LogViewerScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.article_outlined),
                      ),
                      TextButton.icon(
                        onPressed: onToggleLanguage,
                        icon: const Icon(Icons.language_rounded),
                        label: Text(l10n.language),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: isArabic
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  welcomeText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: store,
                builder: (context, _) {
                  const totalLevels = 5;
                  final unlocked = store.highestUnlockedLevel.clamp(1, totalLevels);
                  final completed = (unlocked - 1).clamp(0, totalLevels);
                  final progress = completed / totalLevels;
                  final progressLabel = isArabic
                      ? 'تم إنجاز $completed من $totalLevels مراحل'
                      : '$completed of $totalLevels levels completed';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF162A43), Color(0xFF294D73)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33223344),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0x22FFFFFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.route_rounded,
                                color: AppTheme.orange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic
                                        ? 'تقدمك في اللعبة'
                                        : 'Your game progress',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    progressLabel,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: AppTheme.orange,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Container(
                width: 152,
                height: 152,
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(42),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 26,
                      offset: Offset(0, 14),
                      color: Color(0x33223344),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.warehouse_rounded, size: 94, color: Colors.white),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: 42,
                        color: AppTheme.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                    ),
              ),
              Text(
                l10n.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LevelSelectScreen(store: store),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.play),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.testAds,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.privacyNote,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
