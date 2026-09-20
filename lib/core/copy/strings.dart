import 'package:wizctl/wizctl.dart' show wizPort;

import '../util/plural.dart';

/// Every line the user reads. Second person, sentence case, no "we", no
/// emoji, no exclamation marks. Control labels are uppercased by widgets.
class Strings {
  Strings._();

  // Copy that must not drift (handoff spec)
  static const privacy =
      'No account, no cloud. Lights are reached over UDP on port 38899 on your own network.';
  static const roomsStored =
      "Rooms are stored in this home's config file on this machine. Nothing is uploaded.";
  static const broadcastHint =
      'Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.';
  static const staleIp =
      "The IP shown in the Philips app can be stale — it talks to the cloud. Your router's DHCP client list is the reliable source.";
  static const dynamicPip =
      'A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200.';
  static const blinkHint =
      'Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back.';

  // Shared actions
  static const cancel = 'Cancel';
  static const close = 'Close';
  static const retry = 'Retry';
  static const rescan = 'Rescan';
  static const save = 'Save';
  static const scanSubnet = 'Scan subnet';
  static const scanAgain = 'Scan again';
  static const discoverLights = 'Discover lights';
  static const dismiss = 'Dismiss';

  // Light mode
  static const lightMode = 'Light mode';
  static const applyTo = 'Apply to';
  static const wholeHome = 'Whole home';
  static const mixed = 'Mixed';
  static const nothingSet = 'Nothing set';
  static const colour = 'Colour';
  static const warmWhite = 'Warm white';
  static const powerOn = 'Power on';
  static const powerOff = 'Power off';

  // Conditions
  static const noResponse = 'No response on the local network';
  static const noRoute = 'No route to the light';

  // Command reports (spec §15).
  static const noResponseAfterTries = 'No response after 3 tries';
  static const stillNoReply = 'Still no reply';
  static const checkWallSwitch =
      'Check the wall switch, then rescan the subnet.';
  static const noLocalNetwork = 'This device has no local network.';

  // Wrong network (spec §15).
  static const notOnHomeNetworkTitle = 'Not on the home network';
  static const joinHomeNetwork = 'Join the home network, then scan again.';

  // Home (spec §10.2).
  static const allLights = 'All lights';
  static const allOn = 'All on';
  static const allOff = 'All off';
  static const homes = 'Homes';
  static const newHome = 'New home';
  static const newHomePlaceholder = 'Studio';
  static const addHome = 'Add home';
  static const discoverOnNetwork = 'Discover the lights on this network';
  static String someOn(int on, int total) => '$on of $total on';
  static String notAnswering(int n) => '${plural(n, 'light')} not answering';
  static String roomsAndLights(int rooms, int lights) =>
      '${plural(rooms, 'room')} · ${plural(lights, 'light')}';
  static String homeCreated(String name) => '$name created';

  // Rooms (spec §10.6).
  static const rooms = 'Rooms';
  static const addRoom = 'Add room';
  static const addARoom = 'Add a room';
  static const roomName = 'Room name';
  static const roomNamePlaceholder = 'Study';
  static const glyph = 'Glyph';
  static const saveRoom = 'Save room';
  static const roomSaved = 'Room saved';
  static const renameRoom = 'Rename room';
  static const deleteRoom = 'Delete room';
  static const moveLightsFirst = 'Move its lights first';
  static const newRoom = 'New room';
  static const createRoom = 'Create room';
  static String lightsOn(int lights, int on) =>
      '${plural(lights, 'light')} · $on on';
  static String roomIsEmpty(String name) =>
      '$name is empty — discover lights for it';

  // Room (spec §10.3).
  static const brightness = 'Brightness';
  static const colourTemp = 'Colour temp.';
  static const wholeRoom = 'Whole room';
  static const noLightsInRoom = 'No lights in this room';
  static const discoverThenPlace =
      'Discover lights on the network, then place them here.';
  static const discoverThenSave =
      'Discover lights on the network, then save them into this room.';
  static const back = 'Back';

  /// The room switch's accessible name: the bar draws the room's name beside
  /// it, but the switch is its own node and has to say what it switches.
  static String roomPower(String name) => '$name power';

  // Light modes (spec §10.5, §5.12).
  static const lightModes = 'Light modes';
  static const applyScenesTo = 'Apply scenes to';
  static const colours = 'Colours';
  static const whites = 'Whites';
  static const staticTab = 'Static';
  static const dynamicTab = 'Dynamic';
  static const dynamicNote = 'Dynamic scenes cycle. Speed runs from 10 to 200.';
  static const staticNote =
      'Static scenes hold one look. The bulb ignores speed.';
  static const noColourBulb = 'No colour bulb here';
  static const colourNeedsRgb = 'Colour needs an RGB bulb.';
  static const noWhiteChannel = 'No white channel here';
  static const bulbsOnlyDim = 'These bulbs only dim.';
  static const noSceneChannel = 'No scene channel here';
  static const plugOnlySwitches = 'A plug only switches power.';
  static const toWholeHome = 'to the whole home';
  static const lightModeWholeHome = 'Light mode · whole home';
  static const speed = 'Speed';

  /// The Scenes tab's subtitle counts the kit's own scene table rather than
  /// repeating a fixed pair of numbers, so the line stays true when the table
  /// changes.
  static String modesSubtitle(int staticCount, int dynamicCount) =>
      'Colour, $staticCount static and $dynamicCount dynamic scenes';
  static String lightModeFor(String name) => 'Light mode · $name';
  static String sceneApplied(String name) => '$name applied';
  static String toTarget(String name) => 'to $name';
  static String speedFor(String scene) => 'Speed — $scene';
  static String kelvinLabel(int kelvin) => '${kelvin}K';

  /// The apply-to key's whole accessible name. The key draws "APPLY TO" over
  /// the target on two lines, but a labelled `WizPressable` is one node and
  /// excludes the copy it draws, so the label has to carry both or the target
  /// is never spoken. A key with no target name yet falls back to [applyTo].
  static String applyToTarget(String name) => 'Apply to $name';

  // Light detail (spec §10.4, §15).
  static const live = 'Live';
  static const noReply = 'No reply';
  static const noReplyFromLight = 'No reply from this light';
  static const mayBeOffAtWall =
      'It may be switched off at the wall, or the router changed its address.';
  static const colourTempTile = 'Colour temp';
  static const classTile = 'Class';
  static const power = 'Power';
  static const intensity = 'Intensity';
  static const on = 'On';
  static const off = 'Off';
  static const plugOnlyNote =
      'A plug switches power only. It has no brightness, colour or scene channel.';
  static const dimsNoWhite = 'This bulb dims but has no white channel to tune.';
  static const device = 'Device';
  static const address = 'Address';
  static const mac = 'MAC';
  static const signal = 'Signal';
  static const noReplyLower = 'no reply';
  static const showItAs = 'Show it as';
  static const showItAsNote =
      'This only changes how the light is drawn here. It does not change what the bulb supports.';
  static const rename = 'Rename';
  static const renameLight = 'Rename light';
  static const forget = 'Forget';
  static const alias = 'Alias';
  static const aliasPlaceholder = 'Bedside bulb';
  static const saveAlias = 'Save alias';
  static const forgetBody =
      'Its alias and room are removed. The bulb keeps working.';
  static const removedFromConfig = "Removed from this home's config file";
  static String staticSceneNote(String name) =>
      '$name is a static scene — the bulb ignores speed.';
  static String dbm(int rssi) => '$rssi dBm';
  static String forgetTitle(String name) => 'Forget $name?';
  static String forgotten(String name) => '$name forgotten';
  static String roomAndClass(String room, String cls) => '$room · $cls';

  /// What "Show it as" calls each fixture (`fixtureLabelOf`): copy, not the
  /// domain's own `Fixture.label`. There is no `fixtureLamp` here — the desk
  /// fixture's label is the word [glyphLamp] already holds, and [all] may not
  /// carry a value twice.
  static const fixtureBulb = 'Bulb';
  static const fixtureCeiling = 'Ceiling light';
  static const fixtureStrip = 'Light strip';
  static const fixturePlug = 'Plug';

  // Semantics.
  static const blinkLight = 'Blink this light';

  /// What the screen reader calls each room glyph in the picker
  /// (`GlyphPicker.labelFor`): the thing drawn, not the enum's name.
  /// [glyphLamp] names the Lamp fixture in "Show it as" too — one word for one
  /// drawn thing, and [all] may not carry a value twice.
  static const glyphSofa = 'Sofa';
  static const glyphBed = 'Bed';
  static const glyphKitchen = 'Kitchen';
  static const glyphBath = 'Bath';
  static const glyphLamp = 'Lamp';
  static const glyphTrees = 'Trees';

  /// What the screen reader calls each hue swatch (`SwatchRow.hueNames`), in
  /// `WizColors.hues` order: the colour a sighted user sees, not the token's
  /// name.
  static const hueRed = 'Red';
  static const hueOrange = 'Orange';
  static const hueYellow = 'Yellow';
  static const hueLime = 'Lime';
  static const hueGreen = 'Green';
  static const hueTeal = 'Teal';
  static const hueCyan = 'Cyan';
  static const hueBlue = 'Blue';
  static const hueIndigo = 'Indigo';
  static const hueViolet = 'Violet';
  static const hueMagenta = 'Magenta';
  static const huePink = 'Pink';

  /// `<ip>:38899`, the address every device fact and toast body shows.
  static String udpAddress(String ip) => '$ip:$wizPort';
  static String didNotAnswer(String ip) =>
      '$ip did not answer on port $wizPort';

  /// The loading toast for a write to one light, and for a batch of several.
  /// The toast layer composes its title from these rather than showing
  /// `CommandPending.description`: every line the user reads lives here.
  static String sendingTo(String name) => 'Sending to $name';
  static String sendingToLights(int n) => 'Sending to $n lights';

  /// The loading toast a Retry puts up, for one light and for a batch — a
  /// retry resends every light that failed under one report at once.
  static String retrying(String name) => 'Retrying $name';
  static String retryingLights(int n) => 'Retrying $n lights';
  static String notOnHomeNetwork(String subnet) =>
      'This device is not on $subnet.0/24.';

  /// The wrong-network banner's body, and the title of the toast a Retry
  /// that changed nothing puts up (spec §15).
  static String deviceOn(String current, String home) =>
      'This device is on $current.0/24. Lights answer only on $home.0/24.';
  static String stillOn(String current) => 'Still on $current.0/24';

  static const List<String> all = [
    privacy,
    roomsStored,
    broadcastHint,
    staleIp,
    dynamicPip,
    blinkHint,
    cancel,
    close,
    retry,
    rescan,
    save,
    scanSubnet,
    scanAgain,
    discoverLights,
    dismiss,
    lightMode,
    applyTo,
    wholeHome,
    mixed,
    nothingSet,
    colour,
    warmWhite,
    powerOn,
    powerOff,
    noResponse,
    noRoute,
    noResponseAfterTries,
    stillNoReply,
    checkWallSwitch,
    noLocalNetwork,
    notOnHomeNetworkTitle,
    joinHomeNetwork,
    allLights,
    allOn,
    allOff,
    homes,
    newHome,
    newHomePlaceholder,
    addHome,
    discoverOnNetwork,
    rooms,
    addRoom,
    addARoom,
    roomName,
    roomNamePlaceholder,
    glyph,
    saveRoom,
    roomSaved,
    renameRoom,
    deleteRoom,
    moveLightsFirst,
    newRoom,
    createRoom,
    brightness,
    colourTemp,
    wholeRoom,
    noLightsInRoom,
    discoverThenPlace,
    discoverThenSave,
    back,
    lightModes,
    applyScenesTo,
    colours,
    whites,
    staticTab,
    dynamicTab,
    dynamicNote,
    staticNote,
    noColourBulb,
    colourNeedsRgb,
    noWhiteChannel,
    bulbsOnlyDim,
    noSceneChannel,
    plugOnlySwitches,
    toWholeHome,
    lightModeWholeHome,
    speed,
    live,
    noReply,
    noReplyFromLight,
    mayBeOffAtWall,
    colourTempTile,
    classTile,
    power,
    intensity,
    on,
    off,
    plugOnlyNote,
    dimsNoWhite,
    device,
    address,
    mac,
    signal,
    noReplyLower,
    showItAs,
    showItAsNote,
    rename,
    renameLight,
    forget,
    alias,
    aliasPlaceholder,
    saveAlias,
    forgetBody,
    removedFromConfig,
    fixtureBulb,
    fixtureCeiling,
    fixtureStrip,
    fixturePlug,
    blinkLight,
    glyphSofa,
    glyphBed,
    glyphKitchen,
    glyphBath,
    glyphLamp,
    glyphTrees,
    hueRed,
    hueOrange,
    hueYellow,
    hueLime,
    hueGreen,
    hueTeal,
    hueCyan,
    hueBlue,
    hueIndigo,
    hueViolet,
    hueMagenta,
    huePink,
  ];
}
