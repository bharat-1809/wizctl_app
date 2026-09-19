import 'package:bloc/bloc.dart';

/// The light the desktop inspector shows (spec §10.9), or null for the
/// "No light selected" state. Cleared when the home changes (Task 20).
class InspectorCubit extends Cubit<String?> {
  InspectorCubit() : super(null);
  void select(String lightId) => emit(lightId);
  void clear() => emit(null);
}
