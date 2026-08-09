import 'package:cargo_sort_game/core/domain/analytics_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsEvent', () {
    test('exposes a stable schema version and wire name', () {
      final event = AnalyticsEvent(
        AnalyticsEventName.levelStarted,
        properties: const <String, Object>{
          'level': 26,
          'world': 2,
          'difficulty': 'easy',
        },
      );

      expect(AnalyticsEvent.schemaVersion, 1);
      expect(event.wireName, 'level_started');
      expect(event.toWireMap(), <String, Object>{
        'schema_version': 1,
        'event_name': 'level_started',
        'properties': const <String, Object>{
          'level': 26,
          'world': 2,
          'difficulty': 'easy',
        },
      });
    });

    test('accepts only declared event properties', () {
      expect(
        () => AnalyticsEvent(
          AnalyticsEventName.screenViewed,
          properties: const <String, Object>{
            'screen': 'home',
            'email': 'player@example.com',
          },
        ),
        throwsArgumentError,
      );
    });

    test('requires mandatory properties', () {
      expect(
        () => AnalyticsEvent(
          AnalyticsEventName.levelCompleted,
          properties: const <String, Object>{
            'level': 1,
            'world': 1,
            'stars': 3,
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-scalar or wrong property types', () {
      expect(
        () => AnalyticsEvent(
          AnalyticsEventName.levelStarted,
          properties: <String, Object>{
            'level': <int>[1],
            'world': 1,
            'difficulty': 'tutorial',
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range numeric values', () {
      expect(
        () => AnalyticsEvent(
          AnalyticsEventName.levelCompleted,
          properties: const <String, Object>{
            'level': 151,
            'world': 7,
            'stars': 4,
            'moves_left': -1,
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects free-form strings outside the schema allowlist', () {
      expect(
        () => AnalyticsEvent(
          AnalyticsEventName.boosterUsed,
          properties: const <String, Object>{
            'level': 10,
            'booster': 'custom_payload',
          },
        ),
        throwsArgumentError,
      );
    });

    test('properties are immutable after validation', () {
      final source = <String, Object>{'screen': 'settings'};
      final event = AnalyticsEvent(
        AnalyticsEventName.screenViewed,
        properties: source,
      );
      source['screen'] = 'home';

      expect(event.properties['screen'], 'settings');
      expect(() => event.properties['screen'] = 'home', throwsUnsupportedError);
    });
  });
}
