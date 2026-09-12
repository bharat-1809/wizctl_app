import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/usecases/refresh_states.dart';

import '../../support/fakes.dart';

Light light(String id) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: id,
  ip: '192.168.1.$id',
  mac: id,
  bulbClass: BulbClass.rgb,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

void main() {
  late FakeGateway gateway;
  late FakeLightRepository lights;
  late FakeSettingsRepository settings;
  late SyncCoordinator sync;

  setUp(() {
    gateway = FakeGateway();
    lights = FakeLightRepository()..seed([light('1'), light('2'), light('3')]);
    settings = FakeSettingsRepository();
    var refresh = RefreshStates(
      gateway: gateway,
      store: LiveStateStore(),
      lights: lights,
      clock: FakeClock(),
    );
    sync = SyncCoordinator(
      refresh: refresh,
      lights: lights,
      settings: settings,
      pollInterval: const Duration(seconds: 10),
    );
  });

  test('polls the union of registered scopes every interval', () {
    fakeAsync((async) {
      sync.activateHome('h');
      var a = sync.registerScope({'1'});
      var b = sync.registerScope({'2'});
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads.toSet(), {'192.168.1.1', '192.168.1.2'});
      gateway.reads.clear();
      b.dispose();
      a.update({'3'});
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads, ['192.168.1.3']);
      gateway.reads.clear();
      sync.pauseForDiscovery();
      async.elapse(const Duration(seconds: 30));
      expect(gateway.reads, isEmpty);
      sync.resumeAfterDiscovery();
      async.elapse(const Duration(seconds: 10));
      expect(gateway.reads, ['192.168.1.3']);
      sync.dispose();
    });
  });

  test(
    'cold start honours the re-scan setting; resume always refreshes all',
    () {
      fakeAsync((async) {
        sync.activateHome('h');
        settings.save(
          const AppSettings(activeHomeId: 'h', rescanOnLaunch: false),
        );
        async.flushMicrotasks();
        sync.onColdStart();
        async.flushMicrotasks();
        expect(gateway.reads, isEmpty);
        sync.onResumed();
        async.flushMicrotasks();
        expect(gateway.reads.toSet(), {
          '192.168.1.1',
          '192.168.1.2',
          '192.168.1.3',
        });
        gateway.reads.clear();
        sync.onPaused();
        async.elapse(const Duration(seconds: 30));
        expect(gateway.reads, isEmpty);
        sync.dispose();
      });
    },
  );

  test('refreshLight reads just that light, and nothing for a light that no longer exists', () {
    fakeAsync((async) {
      sync.activateHome('h');
      async.flushMicrotasks();
      sync.refreshLight('1');
      async.flushMicrotasks();
      expect(gateway.reads, ['192.168.1.1']);
      gateway.reads.clear();
      sync.refreshLight('ghost');
      async.flushMicrotasks();
      expect(gateway.reads, isEmpty);
      sync.dispose();
    });
  });
}
