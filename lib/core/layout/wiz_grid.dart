import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How many equal columns of at least [minTile] fit in [width] with [gap]
/// between them. Never fewer than one.
int wizGridColumns({
  required double width,
  required double minTile,
  required double gap,
}) {
  var columns = ((width + gap) / (minTile + gap)).floor();
  return math.max(1, columns);
}

/// A grid whose column count comes from a minimum tile width, so phones of
/// different widths and desktop windows of any size get a sensible layout
/// without a hard-coded column count.
///
/// Laid out with plain `Column`/`Row` math rather than `Wrap` or a sliver
/// grid, so it can sit inside any scrolling column (e.g. a
/// `SingleChildScrollView`) without needing a `CustomScrollView`. Each row
/// is wrapped in [IntrinsicHeight] so the stretched [Row] inside it has a
/// bounded cross axis even when the grid's own height is unbounded (as it
/// is under a scroll view) — without that, a stretched row under unbounded
/// height would assert.
class WizGrid extends StatelessWidget {
  final double minTile;
  final double gap;
  final List<Widget> children;

  /// Width-to-height ratio applied to every tile. Ignored when
  /// [mainAxisExtent] is set. When both are null, tiles size to their
  /// content.
  final double? childAspectRatio;

  /// Fixed tile height; takes precedence over [childAspectRatio] when both
  /// are given. When both are null, tiles size to their content.
  final double? mainAxisExtent;

  const WizGrid({
    super.key,
    required this.minTile,
    required this.gap,
    required this.children,
    this.childAspectRatio,
    this.mainAxisExtent,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var columns = wizGridColumns(width: width, minTile: minTile, gap: gap);
        var tileWidth = (width - gap * (columns - 1)) / columns;
        var tileHeight =
            mainAxisExtent ??
            (childAspectRatio == null ? null : tileWidth / childAspectRatio!);

        var rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          var cells = <Widget>[];
          for (var i = 0; i < columns; i++) {
            var index = start + i;
            if (i > 0) cells.add(SizedBox(width: gap));
            cells.add(
              Expanded(
                child: index < children.length
                    ? (tileHeight == null
                          ? children[index]
                          : SizedBox(
                              height: tileHeight,
                              child: children[index],
                            ))
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
