import 'renderer_admission.dart';

/// Exact renderer profile selected for the first Android native visual slice.
Realtime3dRendererCandidate googleFilamentAndroidRendererCandidate() =>
    Realtime3dRendererCandidate(
      id: 'google-filament-android-1.74.0',
      kind: Realtime3dRendererKind.nativeGpu,
      requiredAndroidMinSdk: 21,
      capabilities: Realtime3dRendererAdmissionPolicy.requiredCapabilities,
    );

Realtime3dRendererAdmissionDecision evaluateGoogleFilamentAndroidRenderer() =>
    const Realtime3dRendererAdmissionPolicy().evaluate(
      googleFilamentAndroidRendererCandidate(),
    );
