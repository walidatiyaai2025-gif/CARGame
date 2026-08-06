import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.store});

  final ProgressStore store;

  Future<void> _buyHearts(BuildContext context, int amount, int price) async {
    final messenger = ScaffoldMessenger.of(context);
    if (store.hearts >= ProgressStore.maxHearts) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Your hearts are already full.')),
      );
      return;
    }
    final paid = await store.spendCoins(price);
    if (!paid) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough coins.')),
      );
      return;
    }
    await store.addHearts(amount);
    messenger.showSnackBar(
      const SnackBar(content: Text('Hearts added successfully.')),
    );
  }

  Future<void> _buyBooster(
    BuildContext context,
    String id,
    int amount,
    int price,
    String name,
  ) async {
    final paid = await store.purchaseBooster(id, amount, price);
    if (!context.mounted) return;
    _message(context, paid ? '$name added.' : 'Not enough coins.');
  }

  Future<void> _buyOrSelectTheme(
    BuildContext context,
    _ThemeOffer offer,
  ) async {
    final success = await store.purchaseTheme(offer.id, offer.price);
    if (!context.mounted) return;
    _message(
      context,
      success ? '${offer.name} selected.' : 'Not enough coins.',
    );
  }

  void _message(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final skin = gameSkinById(store.selectedTheme);
    return Scaffold(
      appBar: AppBar(title: const Text('Cargo Shop'), centerTitle: true),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) => Container(
          decoration: BoxDecoration(gradient: skin.backgroundGradient),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _BalanceHeader(store: store, skin: skin),
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
                    child: _OfferCard(
                      icon: Icons.favorite_rounded,
                      title: '+1 Heart',
                      subtitle: '120 coins',
                      color: AppTheme.red,
                      onTap: () => _buyHearts(context, 1, 120),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OfferCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Full Hearts',
                      subtitle: '450 coins',
                      color: AppTheme.red,
                      onTap: () => _buyHearts(
                        context,
                        ProgressStore.maxHearts,
                        450,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                icon: Icons.rocket_launch_rounded,
                title: 'Boosters',
                subtitle: 'Power tools for difficult cities',
              ),
              const SizedBox(height: 12),
              _BoosterTile(
                icon: Icons.lightbulb_rounded,
                title: 'Smart Hint Pack',
                description: '3 free hints without spending coins',
                inventory: store.freeHints,
                price: 180,
                color: const Color(0xFFFFB300),
                onTap: () => _buyBooster(
                  context,
                  'hint',
                  3,
                  180,
                  'Smart hints',
                ),
              ),
              _BoosterTile(
                icon: Icons.add_circle_rounded,
                title: 'Extra Moves Pack',
                description: 'Adds 5 moves during a city mission',
                inventory: store.extraMovesBoosters,
                price: 260,
                color: const Color(0xFF3D6FD8),
                onTap: () => _buyBooster(
                  context,
                  'moves',
                  1,
                  260,
                  'Extra moves booster',
                ),
              ),
              _BoosterTile(
                icon: Icons.shield_rounded,
                title: 'Combo Shield',
                description: 'Protects one combo from a wrong match',
                inventory: store.comboShields,
                price: 220,
                color: const Color(0xFF7B43C6),
                onTap: () => _buyBooster(
                  context,
                  'shield',
                  1,
                  220,
                  'Combo shield',
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                icon: Icons.palette_rounded,
                title: 'Visual Themes',
                subtitle: 'Apply a new identity across the game',
              ),
              const SizedBox(height: 12),
              ..._themeOffers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ThemeTile(
                    offer: offer,
                    unlocked: store.isThemeUnlocked(offer.id),
                    selected: store.selectedTheme == offer.id,
                    onTap: () => _buyOrSelectTheme(context, offer),
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

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.store, required this.skin});

  final ProgressStore store;
  final GameSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: skin.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded, color: skin.accent, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available balance',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '${store.coins} coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${store.hearts}/${ProgressStore.maxHearts}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.favorite_rounded, color: AppTheme.red),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppTheme.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _BoosterTile extends StatelessWidget {
  const _BoosterTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.inventory,
    required this.price,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final int inventory;
  final int price;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text('$description\nOwned: $inventory'),
          isThreeLine: true,
          trailing: FilledButton(
            onPressed: onTap,
            child: Text('$price'),
          ),
        ),
      );
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.offer,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final _ThemeOffer offer;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
                    gradient: LinearGradient(
                      colors: [offer.start, offer.end],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(offer.icon, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.name,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        offer.subtitle,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.green.withValues(alpha: .13)
                        : AppTheme.orange.withValues(alpha: .12),
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

const _themeOffers = <_ThemeOffer>[
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
