import 'package:cargo_sort_game/core/ads/ad_consent_controller.dart';
import 'package:cargo_sort_game/core/settings/app_settings_store.dart';
import 'package:cargo_sort_game/core/widgets/game_button.dart';
import 'package:cargo_sort_game/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'privacy entry re-opens required UMP options and updates eligibility',
    (tester) async {
      final gateway = _FakeConsentGateway(
        refreshSnapshot: const AdConsentSnapshot(
          canRequestAds: true,
          privacyOptionsRequired: true,
        ),
        privacySnapshot: const AdConsentSnapshot(
          canRequestAds: false,
          privacyOptionsRequired: true,
        ),
      );
      final state = AdConsentState();
      final controller = AdConsentController(
        gateway: gateway,
        state: state,
        adsEnabled: () => true,
      );
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settings: AppSettingsStore(),
            onToggleLanguage: () {},
            adConsentController: controller,
          ),
        ),
      );
      await _pumpTransition(tester);
      await _openPrivacySheet(tester);

      final buttonFinder = find.byKey(
        const ValueKey('privacy-options-button'),
      );
      expect(buttonFinder, findsOneWidget);
      expect(find.text('Manage privacy choices'), findsOneWidget);
      expect(state.canRequestAds, isTrue);

      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
      button.onPressed!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(gateway.privacyCalls, 1);
      expect(state.canRequestAds, isFalse);
      expect(state.privacyOptionsRequired, isTrue);
    },
  );

  testWidgets(
    'privacy options button stays hidden when UMP does not require it',
    (tester) async {
      final controller = AdConsentController(
        gateway: _FakeConsentGateway(
          refreshSnapshot: const AdConsentSnapshot(
            canRequestAds: true,
            privacyOptionsRequired: false,
          ),
        ),
        state: AdConsentState(),
        adsEnabled: () => true,
      );
      await controller.refresh();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settings: AppSettingsStore(),
            onToggleLanguage: () {},
            adConsentController: controller,
          ),
        ),
      );
      await _pumpTransition(tester);
      await _openPrivacySheet(tester);

      expect(find.byKey(const ValueKey('privacy-options-button')), findsNothing);
      expect(find.text('Privacy & Ads'), findsOneWidget);
    },
  );
}

Future<void> _openPrivacySheet(WidgetTester tester) async {
  final privacyButtonFinder = find.ancestor(
    of: find.text('Privacy'),
    matching: find.byType(GameButton),
  );
  expect(privacyButtonFinder, findsOneWidget);
  final privacyButton = tester.widget<GameButton>(privacyButtonFinder);
  expect(privacyButton.onPressed, isNotNull);
  privacyButton.onPressed!.call();
  await _pumpTransition(tester);
}

Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _FakeConsentGateway implements AdConsentGateway {
  _FakeConsentGateway({
    required this.refreshSnapshot,
    this.privacySnapshot = const AdConsentSnapshot(
      canRequestAds: false,
      privacyOptionsRequired: false,
    ),
  });

  final AdConsentSnapshot refreshSnapshot;
  final AdConsentSnapshot privacySnapshot;
  int privacyCalls = 0;

  @override
  Future<AdConsentSnapshot> refresh() async => refreshSnapshot;

  @override
  Future<AdConsentSnapshot> showPrivacyOptions() async {
    privacyCalls++;
    return privacySnapshot;
  }
}
