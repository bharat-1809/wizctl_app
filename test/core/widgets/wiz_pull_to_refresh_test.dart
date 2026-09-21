import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/widgets/wiz_filament_bar.dart';
import 'package:wizctl_app/core/widgets/wiz_pull_to_refresh.dart';

import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('a pull shows the filament until the refresh completes', (
    tester,
  ) async {
    var completer = Completer<void>();
    var pulls = 0;
    await tester.pumpWidget(
      wizTestApp(
        SizedBox(
          height: 400,
          child: WizPullToRefresh(
            onRefresh: () {
              pulls++;
              return completer.future;
            },
            child: ListView(
              children: const [SizedBox(height: 100, child: Text('row'))],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(WizFilamentBar), findsNothing);
    await tester.fling(find.text('row'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pulls, 1);
    expect(find.byType(WizFilamentBar), findsOneWidget);
    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WizFilamentBar), findsNothing);
  });
}
