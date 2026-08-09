import '../core/application/optional_service_port.dart';
import '../core/services/optional_service_coordinator.dart';
import '../core/settings/app_settings_store.dart';
import '../core/storage/progress_store.dart';

class AppComposition {
  AppComposition({
    required this.progressStore,
    required this.settingsStore,
    required this.optionalServices,
  });

  factory AppComposition.production() => AppComposition(
    progressStore: ProgressStore(),
    settingsStore: AppSettingsStore(),
    optionalServices: OptionalServiceCoordinator(
      defaultTimeout: const Duration(seconds: 20),
      maxAttempts: 3,
    ),
  );

  final ProgressStore progressStore;
  final AppSettingsStore settingsStore;
  final OptionalServicePort optionalServices;

  Future<void> dispose() => optionalServices.dispose();
}
