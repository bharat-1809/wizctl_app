import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  var services = await bootstrap();
  runApp(WizCtlApp(services: services));
}
