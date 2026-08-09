import 'package:flutter/material.dart';

import '../../core/ads/ad_consent_controller.dart';
import '../../core/settings/app_settings_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/game_button.dart';
import '../../core/widgets/game_fit_view.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onToggleLanguage,
    this.adConsentController,
  });

  final AppSettingsStore settings;
  final VoidCallback onToggleLanguage;
  final AdConsentController? adConsentController;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'الإعدادات' : 'Settings'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4FF), AppTheme.cream],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([settings, adConsentController?.state]),
            builder: (context, _) => GameFitView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeroHeader(ar: ar),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        icon: Icons.volume_up_rounded,
                        title: ar ? 'المؤثرات الصوتية' : 'Sound effects',
                        subtitle: ar
                            ? 'أصوات الضغط والفوز والعملات'
                            : 'Buttons, rewards and win sounds',
                        value: settings.soundEnabled,
                        onChanged: settings.setSound,
                      ),
                      _SwitchTile(
                        icon: Icons.music_note_rounded,
                        title: ar ? 'الموسيقى' : 'Music',
                        subtitle: ar
                            ? 'موسيقى الخلفية داخل اللعبة'
                            : 'Background game music',
                        value: settings.musicEnabled,
                        onChanged: settings.setMusic,
                      ),
                      _SwitchTile(
                        icon: Icons.vibration_rounded,
                        title: ar ? 'الاهتزاز' : 'Vibration',
                        subtitle: ar
                            ? 'اهتزاز خفيف عند التفاعل'
                            : 'Light haptic feedback',
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    padding: const EdgeInsets.all(8),
                    children: [
                      _ActionTile(
                        icon: Icons.language_rounded,
                        title: ar ? 'اللغة' : 'Language',
                        subtitle: ar
                            ? 'التبديل إلى الإنجليزية'
                            : 'Switch to Arabic',
                        onTap: onToggleLanguage,
                        hapticsEnabled: settings.vibrationEnabled,
                      ),
                      const SizedBox(height: 6),
                      _ActionTile(
                        icon: Icons.privacy_tip_rounded,
                        title: ar ? 'الخصوصية' : 'Privacy',
                        subtitle: _privacySubtitle(ar),
                        onTap: () => _showPrivacyInfo(context, ar),
                        hapticsEnabled: settings.vibrationEnabled,
                      ),
                      const SizedBox(height: 6),
                      _ActionTile(
                        icon: Icons.info_rounded,
                        title: ar ? 'حول اللعبة' : 'About',
                        subtitle: 'Cargo Sort • Version 1.0.1 (2)',
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'Cargo Sort',
                          applicationVersion: '1.0.1 (2)',
                          applicationLegalese: 'Walid Atiya Ata - PMP',
                        ),
                        hapticsEnabled: settings.vibrationEnabled,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _privacySubtitle(bool ar) {
    final state = adConsentController?.state;
    if (state == null) {
      return ar
          ? 'سياسة الخصوصية والإعلانات'
          : 'Privacy and advertising information';
    }
    if (state.refreshing) {
      return ar ? 'جارٍ تحديث خيارات الخصوصية…' : 'Updating privacy choices…';
    }
    if (state.privacyOptionsRequired) {
      return ar
          ? 'مراجعة أو تغيير خيارات الخصوصية'
          : 'Review or change privacy choices';
    }
    return ar
        ? 'معلومات الخصوصية والإعلانات'
        : 'Privacy and advertising information';
  }

  void _showPrivacyInfo(BuildContext context, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _PrivacySheet(ar: ar, controller: adConsentController),
    );
  }
}

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet({required this.ar, required this.controller});

  final bool ar;
  final AdConsentController? controller;

  @override
  Widget build(BuildContext context) {
    final consentController = controller;
    final animation = consentController?.state;
    if (animation == null) return _content(context, null);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => _content(context, consentController),
    );
  }

  Widget _content(
    BuildContext context,
    AdConsentController? consentController,
  ) {
    final state = consentController?.state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 54, color: AppTheme.green),
          const SizedBox(height: 12),
          Text(
            ar ? 'الخصوصية والإعلانات' : 'Privacy & Ads',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            ar
                ? 'تستخدم اللعبة التخزين المحلي لحفظ التقدم. يتم طلب الإعلانات فقط عندما تسمح حالة الخصوصية الحالية بذلك، ولا تجمع اللعبة تحليلات خاصة بها حاليًا.'
                : 'The game stores progress locally. Ad requests are made only when the current privacy state permits them, and the game does not currently collect first-party analytics.',
            textAlign: TextAlign.center,
          ),
          if (state?.lastError != null) ...[
            const SizedBox(height: 10),
            Text(
              ar
                  ? 'تعذر تحديث حالة الخصوصية الآن. ستظل اللعبة متاحة بدون إعلانات.'
                  : 'Privacy status could not be refreshed right now. The game remains available without ads.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          if (state?.privacyOptionsRequired == true) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('privacy-options-button'),
              onPressed: state!.refreshing
                  ? null
                  : () async {
                      final shown = await consentController!
                          .showPrivacyOptions();
                      if (!context.mounted || shown) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ar
                                ? 'تعذر فتح خيارات الخصوصية الآن.'
                                : 'Privacy options are unavailable right now.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.manage_accounts_rounded),
              label: Text(
                ar ? 'إدارة خيارات الخصوصية' : 'Manage privacy choices',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.ar});

  final bool ar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF16375B), Color(0xFF2D6591)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: AppTheme.softShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppTheme.yellow,
            size: 32,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'تجربة لعبك' : 'Your game experience',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ar
                    ? 'خصص الصوت واللغة وطريقة التفاعل'
                    : 'Customize sound, language and feedback',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 6,
    shadowColor: const Color(0x220A2945),
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: Column(children: children),
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    dense: true,
    visualDensity: const VisualDensity(vertical: -2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
    secondary: _TileIcon(icon: icon),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppTheme.navy,
      ),
    ),
    subtitle: Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11),
    ),
    value: value,
    onChanged: onChanged,
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.hapticsEnabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) => GameButton(
    semanticLabel: title,
    onPressed: onTap,
    hapticsEnabled: hapticsEnabled,
    expand: true,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    backgroundColor: const Color(0xFFF8FBFF),
    shadowColor: const Color(0x220A2945),
    borderRadius: BorderRadius.circular(18),
    child: Row(
      children: [
        _TileIcon(icon: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.blue, size: 20),
      ],
    ),
  );
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: AppTheme.blue, size: 21),
  );
}
