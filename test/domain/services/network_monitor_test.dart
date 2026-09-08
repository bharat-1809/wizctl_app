import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';

void main() {
  test('off network when the home has a subnet and the current one differs or is missing', () async {
    var info = FakeNetworkInfo('192.168.1');
    var m = NetworkMonitor(info);
    await m.refresh();
    expect(m.isOffNetwork('192.168.1'), isFalse);
    expect(m.isOffNetwork('10.0.0'), isTrue);
    expect(m.isOffNetwork(null), isFalse);
    info.subnet = null;
    await m.refresh();
    expect(m.isOffNetwork('192.168.1'), isTrue);
    m.dispose();
  });

  test('polls on the interval while started and emits changes', () {
    fakeAsync((async) {
      var info = FakeNetworkInfo('192.168.1');
      var m = NetworkMonitor(info, interval: const Duration(seconds: 5));
      var seen = <bool>[];
      m.watchOffNetwork('192.168.1').listen(seen.add);
      m.start();
      async.elapse(const Duration(seconds: 1));
      info.subnet = '10.0.0';
      async.elapse(const Duration(seconds: 5));
      info.subnet = '192.168.1';
      async.elapse(const Duration(seconds: 5));
      m.stop();
      async.elapse(const Duration(seconds: 20));
      expect(info.calls, 3);
      expect(seen, [false, true, false]);
      m.dispose();
    });
  });
}
