enum AnalyticsPropertyType { string, integer, number, boolean }

final class AnalyticsPropertyRule {
  const AnalyticsPropertyRule({
    required this.type,
    this.required = false,
    this.allowedStrings = const <String>{},
    this.minInteger,
    this.maxInteger,
  });

  final AnalyticsPropertyType type;
  final bool required;
  final Set<String> allowedStrings;
  final int? minInteger;
  final int? maxInteger;
}

enum AnalyticsEventName {
  appOpened('app_opened', <String, AnalyticsPropertyRule>{}),
  screenViewed('screen_viewed', <String, AnalyticsPropertyRule>{
    'screen': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.string,
      required: true,
      allowedStrings: <String>{
        'home',
        'world_map',
        'mission_briefing',
        'gameplay',
        'result',
        'shop',
        'progress',
        'settings',
      },
    ),
  }),
  levelStarted('level_started', <String, AnalyticsPropertyRule>{
    'level': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 150,
    ),
    'world': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 6,
    ),
    'difficulty': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.string,
      required: true,
      allowedStrings: <String>{'tutorial', 'easy', 'medium', 'hard', 'expert'},
    ),
  }),
  levelCompleted('level_completed', <String, AnalyticsPropertyRule>{
    'level': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 150,
    ),
    'world': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 6,
    ),
    'stars': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 0,
      maxInteger: 3,
    ),
    'moves_left': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 0,
    ),
  }),
  levelFailed('level_failed', <String, AnalyticsPropertyRule>{
    'level': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 150,
    ),
    'world': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 6,
    ),
    'reason': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.string,
      required: true,
      allowedStrings: <String>{'moves_exhausted', 'quit', 'restart', 'unknown'},
    ),
  }),
  boosterUsed('booster_used', <String, AnalyticsPropertyRule>{
    'level': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.integer,
      required: true,
      minInteger: 1,
      maxInteger: 150,
    ),
    'booster': AnalyticsPropertyRule(
      type: AnalyticsPropertyType.string,
      required: true,
      allowedStrings: <String>{'hint', 'extra_moves', 'combo_shield'},
    ),
  });

  const AnalyticsEventName(this.wireName, this.properties);

  final String wireName;
  final Map<String, AnalyticsPropertyRule> properties;
}

final class AnalyticsEvent {
  AnalyticsEvent(
    this.name, {
    Map<String, Object> properties = const <String, Object>{},
  }) : properties = Map<String, Object>.unmodifiable(
         _validateProperties(name, properties),
       );

  static const int schemaVersion = 1;
  static const int maxPropertyCount = 12;
  static const int maxStringLength = 64;

  final AnalyticsEventName name;
  final Map<String, Object> properties;

  String get wireName => name.wireName;

  Map<String, Object> toWireMap() => <String, Object>{
    'schema_version': schemaVersion,
    'event_name': wireName,
    'properties': properties,
  };

  static Map<String, Object> _validateProperties(
    AnalyticsEventName name,
    Map<String, Object> input,
  ) {
    if (input.length > maxPropertyCount) {
      throw ArgumentError.value(
        input.length,
        'properties',
        'Analytics events support at most $maxPropertyCount properties.',
      );
    }

    final rules = name.properties;
    for (final entry in rules.entries) {
      if (entry.value.required && !input.containsKey(entry.key)) {
        throw ArgumentError(
          'Missing required analytics property: ${entry.key}',
        );
      }
    }

    final validated = <String, Object>{};
    for (final entry in input.entries) {
      final rule = rules[entry.key];
      if (rule == null) {
        throw ArgumentError('Unknown analytics property: ${entry.key}');
      }
      _validateValue(entry.key, entry.value, rule);
      validated[entry.key] = entry.value;
    }
    return validated;
  }

  static void _validateValue(
    String key,
    Object value,
    AnalyticsPropertyRule rule,
  ) {
    switch (rule.type) {
      case AnalyticsPropertyType.string:
        if (value is! String) {
          throw ArgumentError('Analytics property $key must be a String.');
        }
        if (value.isEmpty || value.length > maxStringLength) {
          throw ArgumentError(
            'Analytics property $key must contain 1-$maxStringLength characters.',
          );
        }
        if (rule.allowedStrings.isNotEmpty &&
            !rule.allowedStrings.contains(value)) {
          throw ArgumentError(
            'Analytics property $key has an unsupported value.',
          );
        }
      case AnalyticsPropertyType.integer:
        if (value is! int) {
          throw ArgumentError('Analytics property $key must be an int.');
        }
        if (rule.minInteger case final min? when value < min) {
          throw ArgumentError('Analytics property $key is below its minimum.');
        }
        if (rule.maxInteger case final max? when value > max) {
          throw ArgumentError('Analytics property $key exceeds its maximum.');
        }
      case AnalyticsPropertyType.number:
        if (value is! num || !value.isFinite) {
          throw ArgumentError(
            'Analytics property $key must be a finite number.',
          );
        }
      case AnalyticsPropertyType.boolean:
        if (value is! bool) {
          throw ArgumentError('Analytics property $key must be a bool.');
        }
    }
  }
}
