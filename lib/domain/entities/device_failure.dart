import 'package:equatable/equatable.dart';

/// Why a device operation failed, in the app's vocabulary. Copy for the
/// user lives in the presentation layer; these carry the facts.
sealed class DeviceFailure extends Equatable {
  const DeviceFailure();

  String get message;
}

final class TimeoutFailure extends DeviceFailure {
  final String ip;
  final int attempts;
  const TimeoutFailure(this.ip, this.attempts);

  @override
  String get message => '$ip did not answer after $attempts tries';

  @override
  List<Object?> get props => [ip, attempts];
}

final class UnreachableFailure extends DeviceFailure {
  final String ip;
  final String cause;
  const UnreachableFailure(this.ip, this.cause);

  @override
  String get message => 'Cannot reach $ip: $cause';

  @override
  List<Object?> get props => [ip, cause];
}

final class UnsupportedFailure extends DeviceFailure {
  final String ip;
  final String method;
  const UnsupportedFailure(this.ip, this.method);

  @override
  String get message => '$ip does not support $method';

  @override
  List<Object?> get props => [ip, method];
}

final class OffNetworkFailure extends DeviceFailure {
  final String? homeSubnet;
  final String? currentSubnet;
  const OffNetworkFailure(this.homeSubnet, this.currentSubnet);

  @override
  String get message =>
      'This device is on ${currentSubnet ?? 'no network'}, not ${homeSubnet ?? 'the home network'}';

  @override
  List<Object?> get props => [homeSubnet, currentSubnet];
}

final class InvalidArgumentFailure extends DeviceFailure {
  @override
  final String message;
  const InvalidArgumentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceException implements Exception {
  final DeviceFailure failure;
  const DeviceException(this.failure);

  @override
  String toString() => 'DeviceException: ${failure.message}';
}
