import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/icons/wiz_icon_data.dart';
import 'package:wizctl_app/core/widgets/light_card.dart';
import 'package:wizctl_app/core/widgets/room_card.dart';
import 'package:wizctl_app/features/home/widgets/all_lights_panel.dart';

import '../support/wiz_test_app.dart';

/// Keeps everything [wizTestApp] put in the `MediaQuery` — the phone size
/// above all — and turns the system text scale up to the 1.3 that spec §14
/// says the app honours. The 350 box is about the narrowest a card is drawn
/// at: a 390 phone less the compact gutters.
Widget _scaled(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.3)),
    child: SizedBox(width: 350, child: child),
  ),
);

void main() {
  testWidgets('cards and the All lights panel survive 1.3 text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      wizTestApp(
        _scaled(
          Column(
            children: [
              LightCard(
                name: 'Ceiling dome light with a long name',
                meta: 'Cozy',
                icon: WizIcons.lampCeiling,
                on: true,
                brightness: 70,
                onToggle: (_) {},
              ),
              Row(
                children: [
                  Expanded(
                    child: RoomCard(
                      name: 'Living Room',
                      icon: WizIcons.sofa,
                      lightCount: 3,
                      onCount: 2,
                      on: true,
                      onToggle: (_) {},
                    ),
                  ),
                  Expanded(
                    child: RoomCard(
                      name: 'Kitchen',
                      icon: WizIcons.utensilsCrossed,
                      lightCount: 1,
                      onCount: 1,
                      on: true,
                      onToggle: (_) {},
                    ),
                  ),
                ],
              ),
              AllLightsPanel(onCount: 3, total: 6, onToggle: (_) {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
  });
}
