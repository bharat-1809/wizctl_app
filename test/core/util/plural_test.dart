import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/plural.dart';

void main() {
  test('plural adds an s except for one', () {
    expect(plural(0, 'light'), '0 lights');
    expect(plural(1, 'light'), '1 light');
    expect(plural(3, 'room'), '3 rooms');
  });
}
