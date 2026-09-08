/// Where this device is on the network right now.
abstract interface class NetworkInfo {
  /// The `a.b.c` prefix of the LAN address, or null with no IPv4 address.
  Future<String?> currentSubnet();
}
