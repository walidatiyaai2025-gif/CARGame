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
        actions: [
          GameButton(
            onPressed: onToggleLanguage,
            semanticLabel: ar ? 'تغيير اللغة' : 'Change language',
            hapticsEnabled: settings.vibrationEnabled,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            borderRadius: BorderRadius.circular(14),
            backgroundColor: Colors.white.withValues(alpha: .12),
            shadowColor: Colors.transparent,
            child: Text(
              ar ? 'EN' : 'ع',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          settings,
          adConsentController?.state,
        ]),
        builder: (context, _) => GameFitView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroHeader(ar: ar),
                const SizedBox(height: 18),
                _SettingCard(
                  title: ar ? 'الصوت والموسيقى' : 'Audio & Music',
                  icon: Icons.volume_up_rounded,
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: ar ? 'المؤثرات الصوتية' : 'Sound effects',
                        value: settings.soundEnabled,
                        onChanged: settings.setSound,
                      ),
                      _ToggleRow(
                        title: ar ? 'الموسيقى' : 'Music',
                        value: settings.musicEnabled,
                        onChanged: settings.setMusic,
                      ),
                      _ToggleRow(
                        title: ar ? 'الاهتزاز' : 'Haptics',
                        value: settings.vibrationEnabled,
                        onChanged: settings.setVibration,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SettingCard(
                  title: ar ? 'اللعبة' : 'Gameplay',
                  icon: Icons.sports_esports_rounded,
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: ar ? 'التلميحات' : 'Hints',
                        value: settings.hintsEnabled,
                        onChanged: settings.setHints,
                      ),
                      _ToggleRow(
                        title: ar ? 'تأكيد الشراء' : 'Confirm purchases',
                        value: settings.confirmPurchases,
                        onChanged: settings.setConfirmPurchases,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SettingCard(
                  title: ar ? 'المعلومات' : 'Information',
                  icon: Icons.info_rounded,
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.privacy_tip_rounded,
                        title: ar ? 'الخصوصية' : 'Privacy',
                        subtitle: _privacySubtitle(ar),
                        onTap: () => _showPrivacyInfo(context, ar),
                        hapticsEnabled: settings.vibrationEnabled,
                      ),
                      _ActionTile(
                        icon: Icons.description_rounded,
                        title: ar ? 'السجلات' : 'Diagnostics',
                        subtitle: ar
                            ? 'سجلات محلية قابلة للنسخ'
                            : 'Copyable local diagnostic logs',
                        onTap: () => _showDiagnostics(context, ar),
                        hapticsEnabled: settings.vibrationEnabled,
                      ),
                    ],
                  ),
                ),
              ],
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
      return ar
          ? 'جارٍ تحديث خيارات الخصوصية…'
          : 'Updating privacy choices…';
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
      builder: (context) => _PrivacySheet(
        ar: ar,
        controller: adConsentController,
      ),
    );
  }

  void _showDiagnostics(BuildContext context, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_rounded, size: 54, color: AppTheme.blue),
            const SizedBox(height: 12),
            Text(
              ar ? 'السجلات' : 'Diagnostics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              ar
                  ? 'يمكن نسخ سجلات التشخيص المحلية عند الحاجة للدعم.'
                  : 'Local diagnostic logs can be copied when support needs them.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
        colors: [Color(0xFF1A2942), Color(0xFF0E1627)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'اضبط تجربتك' : 'Tune your run',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ar
                    ? 'الصوت، اللعب، اللغة، والخصوصية في مكان واحد.'
                    : 'Audio, gameplay, language, and privacy in one place.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        child,
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    value: value,
    onChanged: onChanged,
    activeTrackColor: AppTheme.green,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: GameButton(
      onPressed: onTap,
      semanticLabel: title,
      hapticsEnabled: hapticsEnabled,
      expand: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      borderRadius: BorderRadius.circular(17),
      backgroundColor: const Color(0xFFF2F6FB),
      foregroundColor: AppTheme.ink,
      shadowColor: Colors.transparent,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.inkMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.inkMuted),
        ],
      ),
    ),
  );
}
