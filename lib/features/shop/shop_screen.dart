import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../core/theme/three_d_game_icon.dart';
import '../../core/widgets/game_button.dart';

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
                iconType: ThreeDIconType.heart,
                title: 'Heart Station',
                subtitle: 'Continue your journey without waiting',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: '+1 Heart',
                      subtitle: '120 coins',
                      onTap: () => _buyHearts(context, 1, 120),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OfferCard(
                      iconType: ThreeDIconType.heart,
                      title: 'Full Hearts',
                      subtitle: '450 coins',
                      onTap: () =>
                          _buyHearts(context, ProgressStore.maxHearts, 450),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                iconType: ThreeDIconType.chest,
                title: 'Boosters',
                subtitle: 'Power tools for difficult cities',
              ),
              const SizedBox(height: 12),
              _BoosterTile(
                iconType: ThreeDIconType.hint,
                title: 'Smart Hint Pack',
                description: '3 free hints without spending coins',
                inventory: store.freeHints,
                price: 180,
                onTap: () =>
                    _buyBooster(context, 'hint', 3, 180, 'Smart hints'),
              ),
              _BoosterTile(
                iconType: ThreeDIconType.extraMoves,
                title: 'Extra Moves Pack',
                description: 'Adds 5 moves during a city mission',
                inventory: store.extraMovesBoosters,
                price: 260,
                onTap: () => _buyBooster(
                  context,
                  'moves',
                  1,
                  260,
                  'Extra moves booster',
                ),
              ),
              _BoosterTile(
                iconType: ThreeDIconType.shield,
                title: 'Combo Shield',
                description: 'Protects one combo from a wrong match',
                inventory: store.comboShields,
                price: 220,
                onTap: () =>
                    _buyBooster(context, 'shield', 1, 220, 'Combo shield'),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                iconType: ThreeDIconType.star,
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
          const ThreeDGameIcon(
            type: ThreeDIconType.chest,
            size: 58,
            animate: true,
            semanticLabel: 'Cargo shop',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available balance',
                  style: TextStyle(color: Colors.white70),
                ),
                Row(
                  children: [
                    const ThreeDGameIcon(
                      type: ThreeDIconType.coin,
                      size: 30,
                      semanticLabel: 'Coins',
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${store.coins}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThreeDGameIcon(
                type: ThreeDIconType.heart,
                size: 34,
                semanticLabel: 'Hearts',
              ),
              Text(
                '${store.hearts}/${ProgressStore.maxHearts}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.iconType,
    required this.title,
    required this.subtitle,
  });

  final ThreeDIconType iconType;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ThreeDGameIcon(type: iconType, size: 38, semanticLabel: title),
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
    required this.iconType,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ThreeDIconType iconType;
  final String title;
  final String subtitle;
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
            ThreeDGameIcon(
              type: iconType,
              size: 54,
              animate: true,
              semanticLabel: title,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ThreeDGameIcon(type: ThreeDIconType.coin, size: 24),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    subtitle.replaceAll(' coins', ''),
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BoosterTile extends StatelessWidget {
  const _BoosterTile({
    required this.iconType,
    required this.title,
    required this.description,
    required this.inventory,
    required this.price,
    required this.onTap,
  });

  final ThreeDIconType iconType;
  final String title;
  final String description;
  final int inventory;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: SizedBox.square(
        dimension: 56,
        child: ThreeDGameIcon(type: iconType, size: 54, semanticLabel: title),
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
      trailing: GameButton(
        semanticLabel: 'Buy $title for $price coins',
        onPressed: onTap,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThreeDGameIcon(type: ThreeDIconType.coin, size: 22),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
                  Text(
                    offer.name,
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    offer.subtitle,
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.green.withValues(alpha: .13)
                    : AppTheme.orange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: selected
                  ? const Text(
                      'Selected',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : unlocked
                  ? const Text(
                      'Use',
                      style: TextStyle(
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ThreeDGameIcon(
                          type: ThreeDIconType.coin,
                          size: 20,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${offer.price}',
                          style: const TextStyle(
                            color: AppTheme.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
