import 'package:equatable/equatable.dart';

/// A device holds one or more homes; a home holds rooms; a room holds lights.
class Home extends Equatable {
  final String id;
  final String name;

  /// The `a.b.c` prefix of the network this home's lights live on, learned at
  /// setup or first discovery. Null until known.
  final String? subnet;
  final DateTime createdAt;
  final int sortIndex;

  const Home({
    required this.id,
    required this.name,
    this.subnet,
    required this.createdAt,
    this.sortIndex = 0,
  });

  Home copyWith({String? name, String? subnet, int? sortIndex}) => Home(
    id: id,
    name: name ?? this.name,
    subnet: subnet ?? this.subnet,
    createdAt: createdAt,
    sortIndex: sortIndex ?? this.sortIndex,
  );

  @override
  List<Object?> get props => [id, name, subnet, createdAt, sortIndex];
}
