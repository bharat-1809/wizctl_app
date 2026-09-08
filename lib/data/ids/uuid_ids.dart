import 'package:uuid/uuid.dart';

import '../../domain/services/id_generator.dart';

class UuidIds implements IdGenerator {
  final Uuid _uuid = const Uuid();

  @override
  String next() => _uuid.v4();
}
