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

  double get _progress {
    if (widget.level.items.isEmpty) return 0;
    return _matchedCount / widget.level.items.length;
  }

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
      await widget.store.completeLevel(
        widget.level.number,
        25 + widget.level.number * 5,
      );
      if (widget.level.number % 3 == 0) {
        _ads.showInterstitial();
      }
      if (mounted) _showResult(true);
    } else if (_moves <= 0 && mounted) {
      _showResult(false);
    }
  }

  Future<void> _hint() async {
    final selected = _selected;
    if (selected == null) return;

    final paid = await widget.store.spendCoins(10);
    if (!paid || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: won
                ? AppTheme.orange.withValues(alpha: .14)
                : Colors.redAccent.withValues(alpha: .12),
          ),
          child: Icon(
            won ? Icons.emoji_events_rounded : Icons.hourglass_empty_rounded,
            size: 46,
            color: won ? AppTheme.orange : Colors.redAccent,
          ),
        ),
        title: Text(
          won ? l10n.completed : l10n.failed,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: won
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$reward ${l10n.coins}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.orange,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('${l10n.moves}: $_moves'),
                ],
              )
            : null,
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!won)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _ads.showRewarded(
                  onReward: () {
                    if (!mounted) return;
                    setState(() => _moves += 5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.rewardAdded)),
                    );
                  },
                );
              },
              icon: const Icon(Icons.ondemand_video_rounded),
              label: Text(l10n.extraMoves),
            ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (won) {
                Navigator.pop(context);
              } else {
                setState(_reset);
              }
            },
            icon: Icon(won ? Icons.arrow_forward_rounded : Icons.refresh_rounded),
            label: Text(won ? l10n.next : l10n.retry),
          ),
        ],
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
      backgroundColor: const Color(0xFFF6F8FC),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              _StatusPanel(
                movesLabel: l10n.moves,
                moves: _moves,
                matched: _matchedCount,
                total: widget.level.items.length,
                progress: _progress,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.goal,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tapPackage,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: GridView.builder(
                      itemCount: _remaining.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (_, index) {
                        final item = _remaining[index];
                        final selected = identical(item, _selected);

                        return InkWell(
                          onTap: () => _choosePackage(item),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 160),
                            scale: selected ? 1.06 : 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    item.color.withValues(alpha: .92),
                                    item.color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: selected ? 18 : 8,
                                    offset: const Offset(0, 7),
                                    color: item.color.withValues(alpha: .28),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  itemCount: _warehouses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: min(3, _warehouses.length),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (_, index) {
                    final item = _warehouses[index];
                    return InkWell(
                      onTap: () => _chooseWarehouse(item),
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: item.color, width: 3),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                              color: item.color.withValues(alpha: .15),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.warehouse_rounded,
                              color: item.color,
                              size: 48,
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
  });

  final String movesLabel;
  final int moves;
  final int matched;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172A46), Color(0xFF24456F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 9),
            color: Color(0x25172A46),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.touch_app_rounded,
                  label: movesLabel,
                  value: '$moves',
                ),
              ),
              Container(width: 1, height: 38, color: Colors.white24),
              Expanded(
                child: _Metric(
                  icon: Icons.inventory_2_rounded,
                  label: 'Cargo',
                  value: '$matched / $total',
                ),
              ),
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
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.orange, size: 26),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
