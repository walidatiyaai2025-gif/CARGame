#!/usr/bin/env python3
from pathlib import Path

path = Path('lib/features/game/gameplay_operations_deck.dart')
text = path.read_text(encoding='utf-8')
old = '''                                  fallback: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: compact ? 27 : 37,
                                  ),'''
new = '''                                  fallback: Icon(
                                    Icons.warehouse_rounded,
                                    color: item.color,
                                    size: compact ? 27 : 37,
                                  ),'''
if text.count(old) != 1:
    raise SystemExit(f'expected exactly one warehouse fallback anchor, found {text.count(old)}')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
print('AST-007 warehouse fallback preserved')
