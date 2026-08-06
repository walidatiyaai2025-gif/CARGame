import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/ads/ad_service.dart';
import '../../core/storage/progress_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/game_skin.dart';
import '../../l10n/app_localizations.dart';
import 'city_catalog.dart';
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
  int _combo = 0;
  int _bestCombo = 0;
  bool _finished = false;
  bool _usedShield = false;
  bool _madeWrongMove = false;

  int get _matchedCount => widget.level.items.length - _remaining.length;
  double get _progress => widget.level.items.isEmpty
      ? 0
      : _matchedCount / widget.level.items.length;

  int get _earnedStars {
    final ratio = widget.level.moves == 0 ? 0 : _moves / widget.level.moves;
    if (!_madeWrongMove && ratio >= .25) return 3;
    if (_moves > 1) return 2;
    return 1;
  }

  int get _xpEarned =>
      50 + widget.level.difficulty * 10 + _earnedStars * 15 + _bestCombo * 3;

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
    _combo = 0;
    _bestCombo = 0;
    _finished = false;
    _usedShield = false;
    _madeWrongMove = false;
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

    final correct = selected.id == warehouse.id;
    setState(() {
      _moves--;
      if (correct) {
        _remaining.remove(selected);
        _combo++;
        _bestCombo = max(_bestCombo, _combo);
      } else {
        _madeWrongMove = true;
        if (_usedShield) {
          _usedShield = false;
        } else {
          _combo = 0;
        }
      }
      _selected = null;
    });

    if (_remaining.isEmpty) {
      _finished = true;
      final stars = _earnedStars;
      final reward = 25 + widget.level.number * 5 + stars * 10 + _bestCombo * 2;
      await widget.store.completeLevel(
        widget.level.number,
        reward,
        stars: stars,
        combo: _bestCombo,
        xpEarned: _xpEarned,
      );
      if (widget.level.number % 3 == 0) _ads.showInterstitial();
      if (mounted) {
        _showResult(true, stars: stars, reward: reward, xp: _xpEarned);
      }
    } else if (_moves <= 0 && mounted) {
      await widget.store.loseHeart();
      await widget.store.recordLoss();
      if (mounted) _showResult(false, stars: 0, reward: 0, xp: 0);
    }
  }

  Future<void> _useHint() async {
    final selected = _selected;
    if (selected == null) return;

    var usedFreeHint = false;
    if (widget.store.freeHints > 0) {
      usedFreeHint = await widget.store.useFreeHint();
    }
    if (!usedFreeHint) {
      final paid = await widget.store.spendCoins(10);
      if (!paid) {
        _message('Not enough coins or hints.');
        return;
      }
    }
    _message('${selected.name} → ${selected.category} warehouse');
  }

  Future<void> _useExtraMoves() async {
    final used = await widget.store.useExtraMoves();
    if (!used) {
      _message('No extra-moves boosters available.');
      return;
    }
    if (!mounted) return;
    setState(() => _moves += 5);
    _message('+5 moves added.');
  }

  Future<void> _useComboShield() async {
    if (_usedShield) {
      _message('Combo shield is already active.');
      return;
    }
    final used = await widget.store.useComboShield();
    if (!used) {
      _message('No combo shields available.');
      return;
    }
    if (!mounted) return;
    setState(() => _usedShield = true);
    _message('Combo shield activated.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showResult(
    bool won, {
    required int stars,
    required int reward,
    required int xp,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final skin = gameSkinById(widget.store.selectedTheme);

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
                  gradient: won
                      ? skin.heroGradient
                      : const LinearGradient(
                          colors: [Color(0xFFFF7B7B), Color(0xFFD93654)],
                        ),
                ),
                child: Icon(
                  won ? Icons.location_city_rounded : Icons.heart_broken_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.level.cityName,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                won ? l10n.completed : l10n.failed,
                style: const TextStyle(color: AppTheme.muted),
              ),
              if (won) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Icon(
                      index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < stars ? AppTheme.yellow : Colors.black12,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  !_madeWrongMove ? 'PERFECT SORT' : 'CITY CLEARED',
                  style: TextStyle(
                    color: skin.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    _ResultChip(icon: Icons.monetization_on_rounded, text: '+$reward'),
                    _ResultChip(icon: Icons.bolt_rounded, text: '+$xp XP'),
                    _ResultChip(icon: Icons.local_fire_department_rounded, text: 'x$_bestCombo'),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  '${l10n.moves}: 0',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
                  icon: Icon(won ? Icons.map_rounded : Icons.restart_alt_rounded),
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
    final world = gameWorlds[widget.level.world - 1];
    final skin = gameSkinById(widget.store.selectedTheme);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.level.cityName),
            Text(
              '${world.name} • ${l10n.level} ${widget.level.number}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
        decoration: BoxDecoration(gradient: skin.backgroundGradient),
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
                  combo: _combo,
                  hearts: widget.store.hearts,
                  skin: skin,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.level.isBossCity ? 'BOSS CITY MISSION' : l10n.goal,
                  style: TextStyle(
                    color: widget.level.isBossCity ? skin.accent : skin.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
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
                      child: _BoosterButton(
                        icon: Icons.lightbulb_rounded,
                        count: widget.store.freeHints,
                        active: _selected != null,
                        onPressed: _selected == null ? null : _useHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BoosterButton(
                        icon: Icons.add_circle_rounded,
                        count: widget.store.extraMovesBoosters,
                        onPressed: _useExtraMoves,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BoosterButton(
                        icon: Icons.shield_rounded,
                        count: widget.store.comboShields,
                        active: _usedShield,
                        onPressed: _useComboShield,
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

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18, color: AppTheme.orange),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      );
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.count,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final int count;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(active ? Icons.check_circle_rounded : icon),
        label: Text('$count'),
      );
}

class _CargoBoard extends StatelessWidget {
  const _CargoBoard({required this.items, required this.selected, required this.onTap});

  final List<CargoItem> items;
  final CargoItem? selected;
  final ValueChanged<CargoItem> onTap;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(28),
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
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: .92,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            final isSelected = identical(item, selected);
            return InkWell(
              onTap: () => onTap(item),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedScale(
                scale: isSelected ? 1.06 : 1,
                duration: const Duration(milliseconds: 160),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [item.accentColor, item.color]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: .28),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 34),
                      const SizedBox(height: 5),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _WarehouseBoard extends StatelessWidget {
  const _WarehouseBoard({required this.warehouses, required this.onTap});

  final List<CargoItem> warehouses;
  final ValueChanged<CargoItem> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
        itemCount: warehouses.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: min(3, warehouses.length),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (_, index) {
          final item = warehouses[index];
          return InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: item.color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: .16),
                    blurRadius: 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warehouse_rounded, color: item.color, size: 38),
                  const SizedBox(height: 3),
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.movesLabel,
    required this.moves,
    required this.matched,
    required this.total,
    required this.progress,
    required this.combo,
    required this.hearts,
    required this.skin,
  });

  final String movesLabel;
  final int moves;
  final int matched;
  final int total;
  final double progress;
  final int combo;
  final int hearts;
  final GameSkin skin;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: skin.heroGradient,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Metric(icon: Icons.touch_app_rounded, label: movesLabel, value: '$moves'),
                _Metric(icon: Icons.inventory_2_rounded, label: 'Cargo', value: '$matched/$total'),
                _Metric(icon: Icons.local_fire_department_rounded, label: 'Combo', value: 'x$combo'),
                _Metric(icon: Icons.favorite_rounded, label: 'Lives', value: '$hearts'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
              ),
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
        ],
      );
}
