import 'package:equatable/equatable.dart';

/// The six room glyphs the design offers. [iconName] is the WizCtl icon
/// name; [storageName] is what the database stores.
enum RoomGlyph {
  sofa('sofa'),
  bed('bed'),
  utensils('utensils-crossed'),
  bath('bath'),
  lampDesk('lamp-desk'),
  trees('trees');

  final String iconName;
  const RoomGlyph(this.iconName);

  String get storageName => name;

  static RoomGlyph parse(String value) =>
      values.firstWhere((g) => g.name == value, orElse: () => RoomGlyph.sofa);
}

class Room extends Equatable {
  final String id;
  final String homeId;
  final String name;
  final RoomGlyph glyph;
  final int sortIndex;

  const Room({
    required this.id,
    required this.homeId,
    required this.name,
    required this.glyph,
    this.sortIndex = 0,
  });

  Room copyWith({String? name, RoomGlyph? glyph, int? sortIndex}) => Room(
    id: id,
    homeId: homeId,
    name: name ?? this.name,
    glyph: glyph ?? this.glyph,
    sortIndex: sortIndex ?? this.sortIndex,
  );

  @override
  List<Object?> get props => [id, homeId, name, glyph, sortIndex];
}
