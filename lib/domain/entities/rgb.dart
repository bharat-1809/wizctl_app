import 'package:equatable/equatable.dart';

class Rgb extends Equatable {
  final int r;
  final int g;
  final int b;

  const Rgb(this.r, this.g, this.b);

  /// The prototype's default "last colour": a warm white.
  static const Rgb warm = Rgb(255, 224, 188);

  /// Tungsten amber, what blink drives an RGB bulb to.
  static const Rgb amber = Rgb(255, 176, 32);

  @override
  List<Object?> get props => [r, g, b];

  @override
  String toString() => 'Rgb($r, $g, $b)';
}
