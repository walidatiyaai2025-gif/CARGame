from pathlib import Path

path = Path('lib/core/ads/ad_service.dart')
text = path.read_text(encoding='utf-8')
old = """class AdService {\n  AdService({AdRequestGate? requestGate})\n    : _requestGate = requestGate ?? AdConsentState.shared {\n    final gate = _requestGate;\n    if (gate is Listenable) gate.addListener(_handleRequestGateChanged);\n  }\n"""
new = """class AdService {\n  AdService({AdRequestGate? requestGate})\n    : _requestGate = requestGate ?? AdConsentState.shared {\n    final gate = _requestGate;\n    _listenableGate = gate is Listenable ? gate as Listenable : null;\n    _listenableGate?.addListener(_handleRequestGateChanged);\n  }\n"""
if old not in text:
    raise SystemExit('AdService constructor pattern missing')
text = text.replace(old, new, 1)
old = "  final AdRequestGate _requestGate;\n  RewardedAd? _rewarded;"
new = "  final AdRequestGate _requestGate;\n  Listenable? _listenableGate;\n  RewardedAd? _rewarded;"
if old not in text:
    raise SystemExit('AdService field pattern missing')
text = text.replace(old, new, 1)
old = """    final gate = _requestGate;\n    if (gate is Listenable) gate.removeListener(_handleRequestGateChanged);\n    _disposeLoadedAds();\n"""
new = """    _listenableGate?.removeListener(_handleRequestGateChanged);\n    _listenableGate = null;\n    _disposeLoadedAds();\n"""
if old not in text:
    raise SystemExit('AdService dispose pattern missing')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
