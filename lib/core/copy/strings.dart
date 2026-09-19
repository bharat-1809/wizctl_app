import 'package:wizctl/wizctl.dart' show wizPort;

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

  /// `<ip>:38899`, the address every device fact and toast body shows.
  static String udpAddress(String ip) => '$ip:$wizPort';
  static String didNotAnswer(String ip) =>
      '$ip did not answer on port $wizPort';
  static String retrying(String name) => 'Retrying $name';
  static String notOnHomeNetwork(String subnet) =>
      'This device is not on $subnet.0/24.';

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
  ];
}
