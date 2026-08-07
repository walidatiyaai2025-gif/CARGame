import 'package:flutter/material.dart';

import '../../core/settings/app_settings_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/game_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onToggleLanguage,
  });

  final AppSettingsStore settings;
  final VoidCallback onToggleLanguage;

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
            animation: settings,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeroHeader(ar: ar),
                const SizedBox(height: 18),
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
                const SizedBox(height: 14),
                _SettingsCard(
                  padding: const EdgeInsets.all(10),
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
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.privacy_tip_rounded,
                      title: ar ? 'الخصوصية' : 'Privacy',
                      subtitle: ar
                          ? 'سياسة الخصوصية والإعلانات'
                          : 'Privacy and advertising information',
                      onTap: () => _showInfo(context, ar),
                      hapticsEnabled: settings.vibrationEnabled,
                    ),
                    const SizedBox(height: 8),
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
    );
  }

  void _showInfo(BuildContext context, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
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
                  ? 'تستخدم اللعبة التخزين المحلي لحفظ التقدم، وقد تعرض إعلانات من شبكات الإعلانات المدعومة.'
                  : 'The game uses local storage for progress and may display ads from supported advertising networks.',
              textAlign: TextAlign.center,
            ),
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
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF16375B), Color(0xFF2D6591)],
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: AppTheme.softShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppTheme.yellow,
            size: 42,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ar ? 'تجربة لعبك' : 'Your game experience',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ar
                    ? 'خصص الصوت واللغة وطريقة التفاعل'
                    : 'Customize sound, language and feedback',
                style: const TextStyle(
                  color: Colors.white70,
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
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppTheme.softShadow,
    ),
    child: Column(children: children),
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
    secondary: _TileIcon(icon: icon),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navy),
    ),
    subtitle: Text(subtitle),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    backgroundColor: const Color(0xFFF8FBFF),
    shadowColor: const Color(0x220A2945),
    borderRadius: BorderRadius.circular(20),
    child: Row(
      children: [
        _TileIcon(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.blue),
      ],
    ),
  );
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: AppTheme.blue.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: AppTheme.blue),
  );
}
