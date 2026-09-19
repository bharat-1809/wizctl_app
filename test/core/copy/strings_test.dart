import 'dart:io';

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
    // No reflection here, so this counts the static const string fields in
    // the source directly rather than maintaining a second, hand-written
    // mirror of the class: a field added to the class but forgotten in
    // `all` changes this count without a matching change to `all.length`.
    var source = File('lib/core/copy/strings.dart').readAsStringSync();
    var fieldCount = RegExp(
      r'^\s+static const (?:String )?\w+ =',
      multiLine: true,
    ).allMatches(source).length;
    expect(
      Strings.all.length,
      fieldCount,
      reason:
          'Strings.all must list every static const string field exactly once',
    );
    expect(
      Strings.all.toSet().length,
      Strings.all.length,
      reason: 'Strings.all must not list a field twice',
    );
  });

  test('templated copy formats addresses and names', () {
    expect(Strings.udpAddress('192.168.1.115'), '192.168.1.115:38899');
    expect(
      Strings.didNotAnswer('192.168.1.115'),
      '192.168.1.115 did not answer on port 38899',
    );
    expect(Strings.sendingTo('Hallway'), 'Sending to Hallway');
    expect(Strings.sendingToLights(3), 'Sending to 3 lights');
    expect(Strings.retrying('Hallway'), 'Retrying Hallway');
    expect(Strings.retryingLights(2), 'Retrying 2 lights');
    expect(
      Strings.notOnHomeNetwork('192.168.1'),
      'This device is not on 192.168.1.0/24.',
    );
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
