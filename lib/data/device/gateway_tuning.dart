import 'package:wizctl/wizctl.dart';

/// Timeouts and retries for an interactive client (spec §3.3, §5.8): three
/// attempts of one second for writes so a dead bulb reports in a few
/// seconds; two attempts for reads so one lost packet is not "unreachable".
class GatewayTuning {
  final Duration writeTimeout;
  final RetryConfig writeRetry;
  final Duration readTimeout;
  final RetryConfig readRetry;
  final Duration broadcastTimeout;
  final Duration sweepTimeout;
  final int port;
  final int localPort;
  final String broadcastAddress;

  const GatewayTuning({
    this.writeTimeout = const Duration(seconds: 1),
    this.writeRetry = const RetryConfig.exponential(
      count: 2,
      initialInterval: Duration(milliseconds: 250),
      maxInterval: Duration(seconds: 1),
    ),
    this.readTimeout = const Duration(milliseconds: 1500),
    this.readRetry = const RetryConfig.fixed(
      count: 1,
      interval: Duration(milliseconds: 250),
    ),
    this.broadcastTimeout = const Duration(seconds: 4),
    this.sweepTimeout = const Duration(seconds: 3),
    this.port = wizPort,
    this.localPort = wizPort,
    this.broadcastAddress = defaultBroadcastAddress,
  });
}
