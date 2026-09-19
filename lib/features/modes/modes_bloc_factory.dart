import '../../domain/entities/entities.dart';
import 'bloc/light_modes_bloc.dart';

/// Builds a modes bloc for a target. The shell provides one over the real
/// use cases (Task 19); screens read it with `context.read` and hand it to
/// `showModesSheet`, so no screen holds a use case.
typedef ModesBlocFactory = LightModesBloc Function(ModeTarget target);
