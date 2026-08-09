import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ads/ad_consent_controller.dart';
import '../../core/privacy/local_data_controller.dart';
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
    this.localDataController,
    this.onLocalDataDeleted,
  });

  final AppSettingsStore settings;
  final VoidCallback onToggleLanguage;
  final AdConsentController? adConsentController;
  final LocalDataController? localDataController;
  final Future<void> Function()? onLocalDataDeleted;

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
          ? 'سياسة الخصوصية والبيانات المحلية'
          : 'Privacy, ads and local data controls';
    }
    if (state.refreshing) {
      return ar ? 'جارٍ تحديث خيارات الخصوصية…' : 'Updating privacy choices…';
    }
    if (state.privacyOptionsRequired) {
      return ar
          ? 'خيارات الخصوصية والبيانات المحلية'
          : 'Privacy choices and local data';
    }
    return ar
        ? 'الخصوصية والإعلانات والبيانات المحلية'
        : 'Privacy, ads and local data controls';
  }

  void _showPrivacyInfo(BuildContext context, bool ar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: _PrivacySheet(
            ar: ar,
            consentController: adConsentController,
            localDataController: localDataController,
            onLocalDataDeleted: onLocalDataDeleted,
          ),
        ),
      ),
    );
  }
}

class _PrivacySheet extends StatefulWidget {
  const _PrivacySheet({
    required this.ar,
    required this.consentController,
    required this.localDataController,
    required this.onLocalDataDeleted,
  });

  final bool ar;
  final AdConsentController? consentController;
  final LocalDataController? localDataController;
  final Future<void> Function()? onLocalDataDeleted;

  @override
  State<_PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<_PrivacySheet> {
  bool _dataActionBusy = false;

  @override
  Widget build(BuildContext context) {
    final animation = widget.consentController?.state;
    if (animation == null) return _content(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final ar = widget.ar;
    final consentController = widget.consentController;
    final state = consentController?.state;
    final dataController = widget.localDataController;

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
              onPressed: state!.refreshing || _dataActionBusy
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
          if (dataController != null) ...[
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                ar ? 'بياناتك المحلية' : 'Your local data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ar
                  ? 'يمكنك نسخ تصدير JSON لبيانات اللعبة المحلية أو حذف التقدم والإعدادات وسجل التشخيص المحلي. لا يحذف هذا بيانات تحتفظ بها Google؛ استخدم خيارات الخصوصية أعلاه لإدارة اختيارات الإعلانات.'
                  : 'You can copy a JSON export of local game data or delete local progress, settings and diagnostic logs. This does not delete processor-side Google data; use the privacy choices above for ad privacy controls.',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('privacy-export-data-button'),
                onPressed: _dataActionBusy ? null : _exportLocalData,
                icon: const Icon(Icons.content_copy_rounded),
                label: Text(ar ? 'نسخ تصدير البيانات' : 'Copy data export'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('privacy-delete-data-button'),
                onPressed: _dataActionBusy ? null : _confirmDeleteLocalData,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(
                  ar
                      ? 'حذف وإعادة ضبط البيانات المحلية'
                      : 'Delete & reset local data',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportLocalData() async {
    final controller = widget.localDataController;
    if (controller == null || _dataActionBusy) return;

    setState(() => _dataActionBusy = true);
    try {
      final json = await controller.exportJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ar
                ? 'تم نسخ تصدير البيانات المحلية بصيغة JSON.'
                : 'Local data export copied as JSON.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ar
                ? 'تعذر إنشاء تصدير البيانات الآن.'
                : 'Could not create the local data export right now.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _dataActionBusy = false);
    }
  }

  Future<void> _confirmDeleteLocalData() async {
    final controller = widget.localDataController;
    if (controller == null || _dataActionBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
        title: Text(widget.ar ? 'حذف البيانات المحلية؟' : 'Delete local data?'),
        content: Text(
          widget.ar
              ? 'سيتم حذف التقدم والعملات والقلوب والجوائز والإعدادات وبيانات الاسترداد وسجل التشخيص المحلي. ستبدأ اللعبة من الحالة الافتراضية، ولا يمكن التراجع عن ذلك.'
              : 'This deletes progress, coins, hearts, rewards, settings, recovery data and local diagnostic logs. The game returns to default state and this cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('privacy-delete-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(widget.ar ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            key: const ValueKey('privacy-delete-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(widget.ar ? 'حذف البيانات' : 'Delete data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _dataActionBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.deleteAllLocalData();
      await widget.onLocalDataDeleted?.call();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.ar
                ? 'تم حذف البيانات المحلية وإعادة ضبط اللعبة.'
                : 'Local data deleted and the game was reset.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.ar
                ? 'تعذر إكمال حذف البيانات المحلية.'
                : 'Could not complete local data deletion.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _dataActionBusy = false);
    }
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
