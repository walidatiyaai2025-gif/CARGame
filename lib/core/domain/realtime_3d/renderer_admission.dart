enum Realtime3dRendererKind { nativeGpu, webView, projectedFallback }

enum Realtime3dRendererCapability {
  realtimeScene,
  localGlb,
  pbrMaterials,
  dynamicLighting,
  shadows,
  objectPicking,
  mutableTransforms,
  cameraControl,
  android,
  stableFlutterCompatible,
}

final class Realtime3dRendererCandidate {
  Realtime3dRendererCandidate({
    required this.id,
    required this.kind,
    required Iterable<Realtime3dRendererCapability> capabilities,
    required this.requiredAndroidMinSdk,
  }) : capabilities = Set<Realtime3dRendererCapability>.unmodifiable(
         capabilities,
       );

  final String id;
  final Realtime3dRendererKind kind;
  final Set<Realtime3dRendererCapability> capabilities;
  final int requiredAndroidMinSdk;

  bool supports(Realtime3dRendererCapability capability) =>
      capabilities.contains(capability);
}

final class Realtime3dRendererAdmissionDecision {
  Realtime3dRendererAdmissionDecision({
    required this.admitted,
    required Iterable<Realtime3dRendererCapability> missingCapabilities,
    required Iterable<String> reasons,
  }) : missingCapabilities =
           Set<Realtime3dRendererCapability>.unmodifiable(missingCapabilities),
       reasons = List<String>.unmodifiable(reasons);

  final bool admitted;
  final Set<Realtime3dRendererCapability> missingCapabilities;
  final List<String> reasons;
}

final class Realtime3dRendererAdmissionPolicy {
  const Realtime3dRendererAdmissionPolicy({
    this.projectAndroidMinSdk = 23,
    this.requireNativeGpu = true,
  });

  static const requiredCapabilities = <Realtime3dRendererCapability>{
    Realtime3dRendererCapability.realtimeScene,
    Realtime3dRendererCapability.localGlb,
    Realtime3dRendererCapability.pbrMaterials,
    Realtime3dRendererCapability.dynamicLighting,
    Realtime3dRendererCapability.shadows,
    Realtime3dRendererCapability.objectPicking,
    Realtime3dRendererCapability.mutableTransforms,
    Realtime3dRendererCapability.cameraControl,
    Realtime3dRendererCapability.android,
    Realtime3dRendererCapability.stableFlutterCompatible,
  };

  final int projectAndroidMinSdk;
  final bool requireNativeGpu;

  Realtime3dRendererAdmissionDecision evaluate(
    Realtime3dRendererCandidate candidate,
  ) {
    final reasons = <String>[];
    final missing = requiredCapabilities.difference(candidate.capabilities);

    if (candidate.id.trim().isEmpty) {
      reasons.add('renderer id must not be blank');
    }
    if (requireNativeGpu &&
        candidate.kind != Realtime3dRendererKind.nativeGpu) {
      reasons.add('production gameplay renderer must be native GPU backed');
    }
    if (candidate.requiredAndroidMinSdk > projectAndroidMinSdk) {
      reasons.add(
        'renderer requires Android minSdk ${candidate.requiredAndroidMinSdk}, '
        'above project minSdk $projectAndroidMinSdk',
      );
    }
    if (missing.isNotEmpty) {
      reasons.add('renderer is missing required production capabilities');
    }

    return Realtime3dRendererAdmissionDecision(
      admitted: reasons.isEmpty,
      missingCapabilities: missing,
      reasons: reasons,
    );
  }
}
