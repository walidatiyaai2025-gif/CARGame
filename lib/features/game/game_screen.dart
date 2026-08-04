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

  @override
  void initState() {
    super.initState();
    _ads.preload();
    _reset();
  }

  void _reset() {
    _remaining = [...widget.level.items]..shuffle(Random(widget.level.number * 41));
    _moves = widget.level.moves;
    _selected = null;
    _finished = false;
  }

  List<CargoItem> get _warehouses {
    final map = <int, CargoItem>{};
    for (final item in widget.level.items) map[item.id] = item;
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
      await widget.store.completeLevel(widget.level.number, 25 + widget.level.number * 5);
      if (widget.level.number % 3 == 0) _ads.showInterstitial();
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ ${selected.id}')));
  }

  void _showResult(bool won) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(won ? Icons.emoji_events_rounded : Icons.hourglass_empty_rounded, size: 54, color: won ? AppTheme.orange : Colors.redAccent),
        title: Text(won ? l10n.completed : l10n.failed),
        content: won ? Text('+${25 + widget.level.number * 5} ${l10n.coins}') : null,
        actions: [
          if (!won)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _ads.showRewarded(onReward: () {
                  if (!mounted) return;
                  setState(() => _moves += 5);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rewardAdded)));
                });
              },
              child: Text(l10n.extraMoves),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (won) {
                Navigator.pop(context);
              } else {
                setState(_reset);
              }
            },
            child: Text(won ? l10n.next : l10n.retry),
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
      appBar: AppBar(
        title: Text('${l10n.level} ${widget.level.number}'),
        actions: [
          Center(child: Padding(padding: const EdgeInsetsDirectional.only(end: 16), child: Text('${l10n.moves}: $_moves', style: const TextStyle(fontWeight: FontWeight.bold)))),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(l10n.goal, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(l10n.tapPackage, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              Expanded(
                flex: 3,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: GridView.builder(
                      itemCount: _remaining.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemBuilder: (_, index) {
                        final item = _remaining[index];
                        final selected = identical(item, _selected);
                        return InkWell(
                          onTap: () => _choosePackage(item),
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 5),
                              boxShadow: selected ? const [BoxShadow(blurRadius: 12, color: Colors.black26)] : null,
                            ),
                            child: Icon(item.icon, color: Colors.white, size: 34),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  itemCount: _warehouses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: min(3, _warehouses.length), crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemBuilder: (_, index) {
                    final item = _warehouses[index];
                    return InkWell(
                      onTap: () => _chooseWarehouse(item),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(color: item.color.withValues(alpha: .2), borderRadius: BorderRadius.circular(18), border: Border.all(color: item.color, width: 3)),
                        child: Icon(Icons.warehouse_rounded, color: item.color, size: 42),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _selected == null ? null : _hint, icon: const Icon(Icons.lightbulb_rounded), label: Text('${l10n.hint} (-10)'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () => setState(_reset), icon: const Icon(Icons.refresh_rounded), label: Text(l10n.restart))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
