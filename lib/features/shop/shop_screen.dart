import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _selectedThemeKey = 'selected_shop_theme';
  static const _unlockedThemesKey = 'unlocked_shop_themes';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Set<String> _unlockedThemes = {'classic'};
  String _selectedTheme = 'classic';
  bool _loading = true;

  static const _themes = <_ThemeOffer>[
    _ThemeOffer(
      id: 'classic',
      name: 'Classic Cargo',
      subtitle: 'The original blue warehouse look',
      icon: Icons.warehouse_rounded,
      start: Color(0xFF1E3A5F),
      end: Color(0xFF4F86B8),
      price: 0,
    ),
    _ThemeOffer(
      id: 'sunset',
      name: 'Sunset Express',
      subtitle: 'Warm orange logistics route',
      icon: Icons.wb_sunny_rounded,
      start: Color(0xFFD85B24),
      end: Color(0xFFFFB347),
      price: 700,
    ),
    _ThemeOffer(
      id: 'neon',
      name: 'Neon Future',
      subtitle: 'Cyber cargo command center',
      icon: Icons.auto_awesome_rounded,
      start: Color(0xFF4B2A86),
      end: Color(0xFF00A6A6),
      price: 1200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await _prefs.getStringList(_unlockedThemesKey);
    final selected = await _prefs.getString(_selectedThemeKey);
    if (!mounted) return;
    setState(() {
      _unlockedThemes = {...?unlocked, 'classic'};
      _selectedTheme = selected ?? 'classic';
      _loading = false;
    });
  }

  Future<void> _buyHearts(int amount, int price) async {
    if (widget.store.hearts >= ProgressStore.maxHearts) {
      _message('Your hearts are already full.');
      return;
    }
    final paid = await widget.store.spendCoins(price);
    if (!paid) {
      _message('Not enough coins.');
      return;
    }
    await widget.store.addHearts(amount);
    _message('Hearts added successfully.');
  }

  Future<void> _buyOrSelectTheme(_ThemeOffer offer) async {
    if (!_unlockedThemes.contains(offer.id)) {
      final paid = await widget.store.spendCoins(offer.price);
      if (!paid) {
        _message('Not enough coins.');
        return;
      }
      _unlockedThemes.add(offer.id);
      await _prefs.setStringList(_unlockedThemesKey, _unlockedThemes.toList());
    }

    _selectedTheme = offer.id;
    await _prefs.setString(_selectedThemeKey, offer.id);
    if (!mounted) return;
    setState(() {});
    _message('${offer.name} selected.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargo Shop'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: widget.store,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                children: [
                  _BalanceHeader(store: widget.store),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.favorite_rounded,
                    title: 'Heart Station',
                    subtitle: 'Continue your journey without waiting',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HeartOffer(
                          title: '+1 Heart',
                          price: 120,
                          icon: Icons.favorite_rounded,
                          onTap: () => _buyHearts(1, 120),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeartOffer(
                          title: 'Full Hearts',
                          price: 450,
                          icon: Icons.favorite_border_rounded,
                          onTap: () => _buyHearts(ProgressStore.maxHearts, 450),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    icon: Icons.palette_rounded,
                    title: 'Visual Themes',
                    subtitle: 'Unlock a new identity for your cargo empire',
                  ),
                  const SizedBox(height: 12),
                  ..._themes.map(
                    (offer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ThemeTile(
                        offer: offer,
                        unlocked: _unlockedThemes.contains(offer.id),
                        selected: _selectedTheme == offer.id,
                        onTap: () => _buyOrSelectTheme(offer),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.store});
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142A47), Color(0xFF2D5D8F)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppTheme.yellow, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available balance', style: TextStyle(color: Colors.white70)),
                Text(
                  '${store.coins} coins',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Text(
            '${store.hearts}/${ProgressStore.maxHearts}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.favorite_rounded, color: AppTheme.red),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.navy, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeartOffer extends StatelessWidget {
  const _HeartOffer({required this.title, required this.price, required this.icon, required this.onTap});
  final String title;
  final int price;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.red, size: 40),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('$price coins', style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.offer, required this.unlocked, required this.selected, required this.onTap});
  final _ThemeOffer offer;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
                    Text(offer.name, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900)),
                    Text(offer.subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.green.withValues(alpha: .13) : AppTheme.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  selected
                      ? 'Selected'
                      : unlocked
                          ? 'Use'
                          : '${offer.price}',
                  style: TextStyle(
                    color: selected ? AppTheme.green : AppTheme.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOffer {
  const _ThemeOffer({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
    required this.price,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color start;
  final Color end;
  final int price;
}
