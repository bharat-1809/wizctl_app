import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/network/network_info.dart';

void main() {
  test('prefers RFC1918 space over a VPN address and drops loopback', () {
    expect(IoNetworkInfo.subnetOf(['100.64.3.9', '192.168.1.42']), '192.168.1');
    expect(IoNetworkInfo.subnetOf(['127.0.0.1', '10.20.30.40']), '10.20.30');
    expect(IoNetworkInfo.subnetOf(['172.16.5.5']), '172.16.5');
    expect(IoNetworkInfo.subnetOf(['100.64.3.9']), '100.64.3');
    expect(IoNetworkInfo.subnetOf(['127.0.0.1']), isNull);
    expect(IoNetworkInfo.subnetOf([]), isNull);
  });
}
