import 'active_run_session.dart';
import 'active_run_store.dart';
import 'level_data.dart';

/// Serializes active-run persistence operations around one production level.
///
/// This coordinator owns no durable progression, rewards, hearts, ads, or
/// inventory. Its only responsibility is reward-neutral unfinished-run state.
final class ActiveRunCoordinator {
  ActiveRunCoordinator({required this.level, ActiveRunStore? store})
    : _store = store ?? ActiveRunStore();

  final LevelData level;
  final ActiveRunStore _store;
  Future<void> _tail = Future<void>.value();
  bool _terminal = false;

  Future<ActiveRunSession?> restore() async {
    final snapshot = await _store.restoreFor(level);
    if (snapshot == null) return null;
    final session = ActiveRunSession.fromSnapshot(snapshot, level);
    if (session == null) {
      await _store.clear();
      return null;
    }
    return session;
  }

  Future<void> checkpoint(ActiveRunSession session) {
    if (_terminal) return Future<void>.value();
    return _enqueue(() async {
      if (_terminal) return;
      await _store.save(session.toSnapshot(level), level);
    });
  }

  Future<void> clearForRestartOrAbandon() {
    return _enqueue(() async {
      if (_terminal) return;
      await _store.clear();
    });
  }

  Future<void> clearTerminal() {
    _terminal = true;
    return _enqueue(_store.clear);
  }

  Future<void> flush() => _tail;

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.catchError((Object _) {
      // Keep the queue usable after an I/O failure. The caller still receives
      // the original error through [next].
    });
    return next;
  }
}
