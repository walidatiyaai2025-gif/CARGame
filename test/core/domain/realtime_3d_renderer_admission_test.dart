import 'package:cargo_sort_game/core/domain/realtime_3d/renderer_admission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Realtime3dRendererAdmissionPolicy', () {
    const policy = Realtime3dRendererAdmissionPolicy();

    test(
      'admits a native renderer with the complete production capability set',
      () {
        final candidate = Realtime3dRendererCandidate(
          id: 'native-test-renderer',
          kind: Realtime3dRendererKind.nativeGpu,
          capabilities: Realtime3dRendererAdmissionPolicy.requiredCapabilities,
          requiredAndroidMinSdk: 23,
        );

        final decision = policy.evaluate(candidate);

        expect(decision.admitted, isTrue);
        expect(decision.missingCapabilities, isEmpty);
        expect(decision.reasons, isEmpty);
      },
    );

    test('rejects WebView-backed renderers for production gameplay', () {
      final candidate = Realtime3dRendererCandidate(
        id: 'model-viewer-wrapper',
        kind: Realtime3dRendererKind.webView,
        capabilities: Realtime3dRendererAdmissionPolicy.requiredCapabilities,
        requiredAndroidMinSdk: 23,
      );

      final decision = policy.evaluate(candidate);

      expect(decision.admitted, isFalse);
      expect(
        decision.reasons,
        contains('production gameplay renderer must be native GPU backed'),
      );
    });

    test('rejects a renderer missing GLB support', () {
      final capabilities = <Realtime3dRendererCapability>{
        ...Realtime3dRendererAdmissionPolicy.requiredCapabilities,
      }..remove(Realtime3dRendererCapability.localGlb);
      final candidate = Realtime3dRendererCandidate(
        id: 'missing-glb',
        kind: Realtime3dRendererKind.nativeGpu,
        capabilities: capabilities,
        requiredAndroidMinSdk: 23,
      );

      final decision = policy.evaluate(candidate);

      expect(decision.admitted, isFalse);
      expect(
        decision.missingCapabilities,
        contains(Realtime3dRendererCapability.localGlb),
      );
    });

    test('rejects a renderer that would raise the Android minSdk', () {
      final candidate = Realtime3dRendererCandidate(
        id: 'high-min-sdk',
        kind: Realtime3dRendererKind.nativeGpu,
        capabilities: Realtime3dRendererAdmissionPolicy.requiredCapabilities,
        requiredAndroidMinSdk: 24,
      );

      final decision = policy.evaluate(candidate);

      expect(decision.admitted, isFalse);
      expect(decision.reasons.single, contains('above project minSdk 23'));
    });

    test('rejects a blank renderer identity', () {
      final candidate = Realtime3dRendererCandidate(
        id: '  ',
        kind: Realtime3dRendererKind.nativeGpu,
        capabilities: Realtime3dRendererAdmissionPolicy.requiredCapabilities,
        requiredAndroidMinSdk: 23,
      );

      final decision = policy.evaluate(candidate);

      expect(decision.admitted, isFalse);
      expect(decision.reasons, contains('renderer id must not be blank'));
    });
  });
}
