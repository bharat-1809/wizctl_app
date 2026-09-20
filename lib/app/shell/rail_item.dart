/// What the desktop rail can light (spec §10.9): one of the home's rooms, or
/// one of the four house items.
///
/// A value type rather than the location string itself, so the rail's
/// selection is checked by the compiler and `DesktopRail.itemFor` is the one
/// place that knows how a path maps onto a row.
sealed class RailItem {
  const RailItem();
}

/// One room, by id.
final class RoomRailItem extends RailItem {
  final String roomId;

  const RoomRailItem(this.roomId);

  @override
  bool operator ==(Object other) =>
      other is RoomRailItem && other.roomId == roomId;

  @override
  int get hashCode => roomId.hashCode;
}

// The four below carry no field, so `const` canonicalisation already makes two
// instances of one the same object, and identity is the equality they need.

/// The whole home's grid.
final class AllLightsRailItem extends RailItem {
  const AllLightsRailItem();
}

/// The Scenes screen.
final class ScenesRailItem extends RailItem {
  const ScenesRailItem();
}

/// Discovery.
final class DiscoveryRailItem extends RailItem {
  const DiscoveryRailItem();
}

/// Settings.
final class SettingsRailItem extends RailItem {
  const SettingsRailItem();
}
