import '../../core/copy/strings.dart';
import '../../core/widgets/fixture_hero.dart';
import '../../domain/entities/entities.dart';

/// The domain's "show it as" in the hero's terms; the two enums share
/// their names by design (Plan 2 Task 20, Plan 3 Task 1).
WizFixture fixtureOf(Fixture fixture) => WizFixture.values.byName(fixture.name);

/// What the user reads for a fixture — the "Show it as" tiles, and whatever
/// else names one. The copy is `Strings`', not the domain's `Fixture.label`,
/// which stays the repository's own word for the shape; this mirrors
/// `GlyphPicker.labelFor`, and keeps the copy layer free of domain types.
String fixtureLabelOf(Fixture fixture) => switch (fixture) {
  Fixture.bulb => Strings.fixtureBulb,
  Fixture.dome => Strings.fixtureCeiling,
  Fixture.desk => Strings.glyphLamp,
  Fixture.strip => Strings.fixtureStrip,
  Fixture.socket => Strings.fixturePlug,
};
