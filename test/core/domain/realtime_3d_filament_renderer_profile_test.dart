import 'package:cargo_sort_game/core/domain/realtime_3d/filament_renderer_profile.dart';
import 'package:cargo_sort_game/core/domain/realtime_3d/renderer_admission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Google Filament 1.74.0 satisfies production renderer admission', () {
    final candidate = googleFilamentAndroidRendererCandidate();
    final decision = evaluateGoogleFilamentAndroidRenderer();

    expect(candidate.id, 'google-filament-android-1.74.0');
    expect(candidate.kind, Realtime3dRendererKind.nativeGpu);
    expect(candidate.requiredAndroidMinSdk, lessThanOrEqualTo(23));
    expect(
      candidate.capabilities,
      containsAll(Realtime3dRendererAdmissionPolicy.requiredCapabilities),
    );
    expect(decision.admitted, isTrue);
    expect(decision.missingCapabilities, isEmpty);
    expect(decision.reasons, isEmpty);
  });
}
