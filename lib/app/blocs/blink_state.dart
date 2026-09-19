import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// A blink that did not happen: the bulb answered neither the read nor the
/// restore (spec §5.10); the view shows the command-timeout toast.
class BlinkFailure extends Equatable {
  final String ip;
  final DeviceFailure failure;
  const BlinkFailure(this.ip, this.failure);
  @override
  List<Object?> get props => [ip, failure];
}

class BlinkState extends Equatable {
  final Set<String> blinking;
  final BlinkFailure? failure;
  const BlinkState({required this.blinking, this.failure});

  bool isBlinking(String ip) => blinking.contains(ip);

  @override
  List<Object?> get props => [blinking, failure];
}
