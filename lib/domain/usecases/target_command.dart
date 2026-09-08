import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/device_command_pipeline.dart';
import '../services/live_state_store.dart';
import '../services/target_resolver.dart';

/// Shared plumbing for writes aimed at a target: resolve the lights, keep
/// the eligible ones, build one item each, hand the batch to the pipeline.
abstract class TargetCommand {
  final TargetResolver resolver;
  final LiveStateStore store;
  final DeviceCommandPipeline pipeline;

  const TargetCommand({
    required this.resolver,
    required this.store,
    required this.pipeline,
  });

  Future<int> dispatch(
    ModeTarget target, {
    required bool Function(Light light, LiveState state) eligible,
    required ControlSignal Function(Light light, LiveState state) signal,
    required LiveState Function(LiveState state) patch,
    String? throttleKey,
  }) async {
    var lights = await resolver.resolve(target);
    var items = [
      for (var light in lights)
        if (eligible(light, store.of(light.id)))
          CommandItem(
            light: light,
            signal: signal(light, store.of(light.id)),
            patch: patch,
          ),
    ];
    if (items.isEmpty) return 0;
    await pipeline.run(CommandBatch(items: items, throttleKey: throttleKey));
    return items.length;
  }
}
