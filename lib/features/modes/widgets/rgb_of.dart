import 'dart:ui';

import '../../../domain/entities/entities.dart';

/// A kit colour as the domain's 0-255 triple — the one conversion every
/// modes view needs, since the design system's swatches and the wheel both
/// speak [Color] and every use case speaks [Rgb].
Rgb rgbOf(Color c) =>
    Rgb((c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round());
