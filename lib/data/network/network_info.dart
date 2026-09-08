import 'dart:io';

import '../../domain/services/network_monitor.dart';

/// Reads the interfaces with `dart:io`. Same preference as the wizctl
/// package: RFC1918 first, so a VPN adapter never wins over the LAN.
class IoNetworkInfo implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async {
    var interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    return subnetOf([
      for (var i in interfaces)
        for (var a in i.addresses) a.address,
    ]);
  }

  static String? subnetOf(List<String> addresses) {
    String? fallback;
    for (var address in addresses) {
      var octets = address.split('.');
      if (octets.length != 4) continue;
      if (octets[0] == '127') continue;
      var base = octets.take(3).join('.');
      if (_isPrivate(octets)) return base;
      fallback ??= base;
    }
    return fallback;
  }

  static bool _isPrivate(List<String> octets) {
    var first = int.tryParse(octets[0]);
    var second = int.tryParse(octets[1]);
    if (first == null || second == null) return false;
    return first == 10 ||
        (first == 192 && second == 168) ||
        (first == 172 && second >= 16 && second <= 31);
  }
}
