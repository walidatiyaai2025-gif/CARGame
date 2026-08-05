import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/ads/ad_service.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'level_data.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level, required this.store});

  final LevelData level;
  final ProgressStore store;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AdService _ads = AdService();
  late List<CargoItem> _remaining;
  CargoItem? _selected;
  late int _moves;
  bool _finished = false;

  int get _matchedCount => widget.level.items.length - _remaining.length;
  double get _progress => widget.level.items.isEmpty
      ? 0
      : _matchedCount / widget.level.items.length;

  @override
  void initState() {
    super.initState();
    _ads.preload();
    _reset();
  }

  void _reset() {
    _remaining = [...widget.level.items]
      ..shuffle(Random(widget.level.number * 41));
    _moves = widget.level.moves;
    _selected = null;
    _finished = false;
  }

  List<CargoItem> get _warehouses {
    final map = <int, CargoItem>{};
    for (final item in widget.level.items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  void _choosePackage(CargoItem item) {
    if (_finished || _moves <= 0) return;
    setState(() => _selected = item);
  }

  Future<void> _chooseWarehouse(CargoItem warehouse) async {
    final selected = _selected;
    if (selected == null || _finished || _moves <= 0) return;

    setState(() {
      _moves--;
      if (selected.id == warehouse.id) {
        _remaining.remove(selected);
      }
      _selected = null;
    });

    if (_remaining.isEmpty) {
      _finished = true;
      final reward = 25 + widget.level.number * 5;
      await widget.store.completeLevel(widget.level.number, reward);
      if (widget.level.number % 3 == 0) _ads.showInterstitial();
      if (mounted) _showResult(true);
    } else if (_moves <= 0 && mounted) {
      await widget.store.loseHeart();
      if (mounted) _showResult(false);
    }
  }

  Future<void> _hint() async {
    final selected = _selected;
    if (selected == null) return;
    final paid = await widget.store.spendCoins(10);
    if (!paid || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lightbulb_rounded, color: Colors.amber),
            const SizedBox(width: 10),
            Text('✓ ${selected.id}'),
          ],
        ),
      ),
    );
  }

  void _showResult(bool won) {
    final l10n = AppLocalizations.of(context)!;
    final reward = 25 + widget.level.number * 5;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: won
                        ? const [Color(0xFFFFC83D), Color(0xFFFF8A00)]
                        : const [Color(0xFFFF7B7B), Color(0xFFD93654)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  won ? Icons.emoji_events_rounded : Icons.favorite_broken_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                won ? l10n.completed : l10n.failed,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                won
                    ? '+$reward ${l10n.coins}'
                    : '${l10n.moves}: 0',
                style: TextStyle(
                  color: won ? AppTheme.orange : Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              if (!won)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _ads.showRewarded(
                        onReward: () {
                          if (!mounted) return;
                          setState(() => _moves += 5);
                        },
                      );
                    },
                    icon: const Icon(Icons.ondemand_video_rounded),
                    label: Text(l10n.extraMoves),
                  ),
                ),
              if (!won) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    if (won) {
                      Navigator.pop(context);
                    } else {
                      setState(_reset);
                    }
                  },
                  icon: Icon(
                    won ? Icons.arrow_forward_rounded : Icons.restart_alt_rounded,
                  ),
                  label: Text(won ? l10n.next : l10n.retry),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.level} ${widget.level.number}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.restart,
            onPressed: () => setState(_reset),
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), Color(0xFFE8F1FB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              children: [
                _StatusPanel(
                  movesLabel: l10n.moves,
                  moves: _moves,
                  matched: _matchedCount,
                  total: widget.level.items.length,
                  progress: _progress,
                  coins: widget.store.coins,
                  hearts: widget.store.hearts,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.goal,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tapPackage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: _CargoBoard(
                    items: _remaining,
                    selected: _selected,
                    onTap: _choosePackage,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: _WarehouseBoard(
                    warehouses: _warehouses,
                    onTap: _chooseWarehouse,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selected == null ? null : _hint,
                        icon: const Icon(Icons.lightbulb_rounded),
                        label: Text('${l10n.hint} (-10)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => setState(_reset),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(l10n.restart),
                      ),
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
}

class _CargoBoard extends StatelessWidget {
  const _CargoBoard({
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final List<CargoItem> items;
  final CargoItem? selected;
  final ValueChanged<CargoItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          final isSelected = identical(item, selected);
          return InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedScale(
              scale: isSelected ? 1.08 : 1,
              duration: const Duration(milliseconds: 160),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item.color.withValues(alpha: .8),
                      item.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: .28),
                      blurRadius: isSelected ? 18 : 9,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 38),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WarehouseBoard extends StatelessWidget {
  const _WarehouseBoard({required this.warehouses, required this.onTap});

  final List<CargoItem> warehouses;
  final ValueChanged<CargoItem> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: warehouses.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: min(3, warehouses.length),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, index) {
        final item = warehouses[index];
        return InkWell(
          onTap: () => onTap(item),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: item.color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: .16),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.warehouse_rounded, color: item.color, size: 52),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.movesLabel,
    required this.moves,
    required this.matched,
    required this.total,
    required this.progress,
    required this.coins,
    required this.hearts,
  });

  final String movesLabel;
  final int moves;
  final int matched;
  final int total;
  final double progress;
  final int coins;
  final int hearts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142A47), Color(0xFF2D5D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33142A47),
            blurRadius: 22,
            offset: Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Metric(icon: Icons.touch_app_rounded, label: movesLabel, value: '$moves'),
              _Metric(icon: Icons.inventory_2_rounded, label: 'Cargo', value: '$matched/$total'),
              _Metric(icon: Icons.monetization_on_rounded, label: 'Coins', value: '$coins'),
              _Metric(icon: Icons.favorite_rounded, label: 'Lives', value: '$hearts'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.orange, size: 23),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
