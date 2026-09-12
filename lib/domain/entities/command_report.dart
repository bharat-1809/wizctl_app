import 'package:equatable/equatable.dart';

import 'device_failure.dart';

/// How a write reports back. The toast layer turns these into toasts.
sealed class CommandReport extends Equatable {
  const CommandReport();

  String get id;
}

final class CommandPending extends CommandReport {
  @override
  final String id;
  final List<String> lightIds;
  final String description;
  const CommandPending(this.id, this.lightIds, this.description);

  @override
  List<Object?> get props => [id, lightIds, description];
}

final class CommandSucceeded extends CommandReport {
  @override
  final String id;
  const CommandSucceeded(this.id);

  @override
  List<Object?> get props => [id];
}

final class CommandFailed extends CommandReport {
  @override
  final String id;
  final String lightId;
  final String lightName;
  final String ip;
  final DeviceFailure failure;
  const CommandFailed(
    this.id,
    this.lightId,
    this.lightName,
    this.ip,
    this.failure,
  );

  @override
  List<Object?> get props => [id, lightId, lightName, ip, failure];
}

final class CommandRetryFailed extends CommandReport {
  @override
  final String id;
  final String lightId;
  final String lightName;
  const CommandRetryFailed(this.id, this.lightId, this.lightName);

  @override
  List<Object?> get props => [id, lightId, lightName];
}
