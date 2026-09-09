import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/copy/strings.dart';

void main() {
  test('the six lines that must not drift', () {
    expect(
      Strings.privacy,
      'No account, no cloud. Lights are reached over UDP on port 38899 on your own network.',
    );
    expect(
      Strings.roomsStored,
      "Rooms are stored in this home's config file on this machine. Nothing is uploaded.",
    );
    expect(
      Strings.broadcastHint,
      'Broadcast finds most lights. When an access point filters it, sweep the subnet one address at a time.',
    );
    expect(
      Strings.staleIp,
      'The IP shown in the Philips app can be stale — it talks to the cloud. Your router\'s DHCP client list is the reliable source.',
    );
    expect(
      Strings.dynamicPip,
      'A cyan pip marks a dynamic scene. Those accept a speed from 10 to 200.',
    );
    expect(
      Strings.blinkHint,
      'Not sure which bulb is which? Tap the flash key on a card and that light blinks for two seconds, then goes back.',
    );
  });

  test('no exclamation marks anywhere', () {
    for (var s in Strings.all) {
      expect(s.contains('!'), isFalse, reason: s);
    }
  });

  test('Strings.all lists every field, exhaustively', () {
    // Dart has no reflection here, so this list is maintained by hand
    // alongside the class's fields. It exists so a field added to the
    // class but forgotten in `all` shows up as a length mismatch or a
    // missing entry, rather than silently skipping the copy-rules checks
    // below.
    const fields = <String>[
      Strings.privacy,
      Strings.roomsStored,
      Strings.broadcastHint,
      Strings.staleIp,
      Strings.dynamicPip,
      Strings.blinkHint,
      Strings.cancel,
      Strings.close,
      Strings.retry,
      Strings.rescan,
      Strings.save,
      Strings.scanSubnet,
      Strings.scanAgain,
      Strings.discoverLights,
      Strings.dismiss,
      Strings.lightMode,
      Strings.applyTo,
      Strings.wholeHome,
      Strings.mixed,
      Strings.nothingSet,
      Strings.colour,
      Strings.warmWhite,
      Strings.powerOn,
      Strings.powerOff,
      Strings.noResponse,
      Strings.noRoute,
    ];
    expect(
      Strings.all.length,
      fields.length,
      reason: 'Strings.all must list every static const field exactly once',
    );
    for (var field in fields) {
      expect(Strings.all, contains(field));
    }
  });

  test('copy rules: no emoji, no "we" as a word, none ends with "!"', () {
    // Common emoji blocks: pictographs, emoticons, transport, symbols and
    // dingbats, plus the variation selector used to force emoji rendering.
    var emoji = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
      unicode: true,
    );
    var weAsWord = RegExp(r'\bwe\b', caseSensitive: false);
    for (var s in Strings.all) {
      expect(emoji.hasMatch(s), isFalse, reason: s);
      expect(weAsWord.hasMatch(s), isFalse, reason: s);
      expect(s.endsWith('!'), isFalse, reason: s);
    }
  });
}
