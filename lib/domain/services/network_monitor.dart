/// Where this device is on the network right now.
///
/// [NetworkMonitor] (Task 6) is added alongside this interface once it
/// exists; this file defines only the port so [TargetResolver] and the
/// shared test fakes have something to depend on today.
abstract interface class NetworkInfo {
  /// The `a.b.c` prefix of the LAN address, or null with no IPv4 address.
  Future<String?> currentSubnet();
}
