import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/mode_summarizer.dart';

Light light(String id, BulbClass? cls) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: id,
  ip: '10.0.0.$id',
  mac: id,
  bulbClass: cls,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

void main() {
  LiveLight ll(String id, BulbClass? cls, LiveState s) =>
      (light: light(id, cls), state: s);
  const white = LiveState.initial;
  final scene = LiveState.initial.copyWith(
    active: ActiveChannel.scene,
    sceneId: 6,
    isOn: true,
  );
  final dyn = LiveState.initial.copyWith(
    active: ActiveChannel.scene,
    sceneId: 1,
    isOn: true,
  );
  final colour = LiveState.initial.copyWith(
    active: ActiveChannel.colour,
    rgb: const Rgb(255, 120, 60),
    isOn: true,
  );

  test('empty is Nothing set; mismatch is Mixed', () {
    expect(ModeSummarizer.summarize([]), ModeSummary.nothingSet);
    expect(
      ModeSummarizer.summarize([
        ll('a', BulbClass.rgb, scene),
        ll('b', BulbClass.rgb, colour),
      ]),
      ModeSummary.mixed,
    );
  });

  test('a shared scene names it with art and flags', () {
    var s = ModeSummarizer.summarize([
      ll('a', BulbClass.rgb, scene),
      ll('b', BulbClass.tw, scene),
    ]);
    expect(s.name, 'Cozy');
    expect(s.art, const SceneArt(6));
    expect(s.isStaticScene, isTrue);
    expect(s.isDynamicScene, isFalse);
    expect(
      ModeSummarizer.summarize([ll('a', BulbClass.rgb, dyn)]).isDynamicScene,
      isTrue,
    );
  });

  test('sockets are ignored when any other bulb is present', () {
    var socket = ll(
      'p',
      BulbClass.socket,
      LiveState.initial.copyWith(isOn: true),
    );
    expect(
      ModeSummarizer.summarize([socket, ll('a', BulbClass.rgb, scene)]).name,
      'Cozy',
    );
    expect(ModeSummarizer.summarize([socket]).name, 'Power on');
    expect(
      ModeSummarizer.summarize([ll('p', BulbClass.socket, LiveState.initial)])
          .name,
      'Power off',
    );
  });

  test('colour, dimmable and white summaries', () {
    var c = ModeSummarizer.summarize([ll('a', BulbClass.rgb, colour)]);
    expect(c.name, 'Colour');
    expect(c.art, const SolidArt(Rgb(255, 120, 60)));
    var d = ModeSummarizer.summarize([ll('a', BulbClass.dw, white)]);
    expect(d.name, 'Warm white');
    expect(d.art, const SolidArt(Rgb(255, 201, 141)));
    var w = ModeSummarizer.summarize([
      ll('a', BulbClass.tw, white.copyWith(kelvin: 4000)),
    ]);
    expect(w.name, '4000K white');
    expect(w.art, isA<SolidArt>());
  });

  test('selection helpers require every light to agree', () {
    var both = [ll('a', BulbClass.rgb, colour), ll('b', BulbClass.rgb, colour)];
    expect(
      ModeSummarizer.colourSelected(both, const Rgb(255, 120, 60)),
      isTrue,
    );
    expect(
      ModeSummarizer.colourSelected([
        ...both,
        ll('c', BulbClass.rgb, scene),
      ], const Rgb(255, 120, 60)),
      isFalse,
    );
    expect(
      ModeSummarizer.whiteSelected([ll('a', BulbClass.tw, white)], 2700),
      isTrue,
    );
    expect(
      ModeSummarizer.sceneSelected([ll('a', BulbClass.rgb, scene)], 6),
      isTrue,
    );
    expect(ModeSummarizer.sceneSelected([], 6), isFalse);
    expect(
      ModeSummarizer.allOnOneDynamicScene([
        ll('a', BulbClass.rgb, dyn),
        ll('b', BulbClass.rgb, dyn),
      ]),
      isTrue,
    );
    expect(
      ModeSummarizer.allOnOneDynamicScene([
        ll('a', BulbClass.rgb, dyn),
        ll('b', BulbClass.rgb, scene),
      ]),
      isFalse,
    );
  });

  test('a plug never holds a scene selection back', () {
    var socket = ll(
      'p',
      BulbClass.socket,
      LiveState.initial.copyWith(isOn: true),
    );
    expect(
      ModeSummarizer.sceneSelected([
        ll('a', BulbClass.rgb, scene),
        ll('b', BulbClass.tw, scene),
        socket,
      ], 6),
      isTrue,
      reason: 'ApplyScene never writes to a plug, so it can never agree',
    );
    expect(
      ModeSummarizer.allOnOneDynamicScene([
        socket,
        ll('a', BulbClass.rgb, dyn),
      ]),
      isTrue,
      reason:
          "the speed rail is the room's, plug or no plug, and whatever "
          'order the plug sorts in',
    );
    expect(
      ModeSummarizer.sceneSelected([socket], 6),
      isFalse,
      reason: 'plugs only: there is no scene channel to be selected',
    );
    expect(ModeSummarizer.allOnOneDynamicScene([socket]), isFalse);
  });

  test('a plug never holds a colour or a white selection back', () {
    var socket = ll(
      'p',
      BulbClass.socket,
      LiveState.initial.copyWith(isOn: true),
    );
    // The plug leads each list, as it would in a room where it sorts first.
    expect(
      ModeSummarizer.colourSelected([
        socket,
        ll('a', BulbClass.rgb, colour),
      ], const Rgb(255, 120, 60)),
      isTrue,
      reason: 'ApplyColour never writes to a plug, so it can never agree',
    );
    expect(
      ModeSummarizer.colourSelected([
        socket,
        ll('a', BulbClass.rgb, colour),
        ll('b', BulbClass.tw, white),
      ], const Rgb(255, 120, 60)),
      isTrue,
      reason: 'nor to a tunable white: only the colour bulbs get a say',
    );
    expect(
      ModeSummarizer.whiteSelected([
        socket,
        ll('a', BulbClass.tw, white),
      ], 2700),
      isTrue,
    );
    expect(
      ModeSummarizer.whiteSelected([
        socket,
        ll('a', BulbClass.dw, white),
      ], 2700),
      isFalse,
      reason:
          "each filter is its own write's rule: a dimmable white takes no "
          'kelvin, so nothing is left to agree',
    );
    expect(
      ModeSummarizer.colourSelected([socket], const Rgb(255, 120, 60)),
      isFalse,
      reason: 'plugs only: there is no colour channel to be selected',
    );
    expect(ModeSummarizer.whiteSelected([socket], 2700), isFalse);
  });

  test('the kelvin ramp hits its stops and interpolates between them', () {
    expect(ModeSummarizer.kelvinRgb(2200), const Rgb(255, 178, 92));
    expect(ModeSummarizer.kelvinRgb(6500), const Rgb(220, 233, 255));
    // Midpoint between the 2200K and 2700K stops (t = 0.5).
    expect(ModeSummarizer.kelvinRgb(2450), const Rgb(255, 190, 117));
  });
}
