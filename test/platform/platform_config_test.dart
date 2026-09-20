import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/platform/window_limits.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('iOS declares the local-network use and the display name', () {
    var plist = _read('ios/Runner/Info.plist');
    expect(plist, contains('<key>NSLocalNetworkUsageDescription</key>'));
    expect(
      plist,
      contains('WizCtl finds and controls WiZ lights on your local network.'),
    );
    expect(
      plist,
      contains('<key>CFBundleDisplayName</key>\n\t<string>WizCtl</string>'),
    );
    expect(plist, isNot(contains('UIBackgroundModes')));
  });

  test('macOS opens the network in both entitlements and is named WizCtl', () {
    for (var file in [
      'macos/Runner/DebugProfile.entitlements',
      'macos/Runner/Release.entitlements',
    ]) {
      var text = _read(file);
      expect(text, contains('com.apple.security.network.client'), reason: file);
      expect(text, contains('com.apple.security.network.server'), reason: file);
      expect(text, contains('com.apple.security.app-sandbox'), reason: file);
    }
    var config = _read('macos/Runner/Configs/AppInfo.xcconfig');
    expect(config, contains('PRODUCT_NAME = WizCtl'));
    expect(
      config,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.dotstudios.wizctlApp'),
    );
    var window = _read('macos/Runner/MainFlutterWindow.swift');
    expect(window, contains('minSize'));
    expect(
      window,
      contains(
        'width: ${WindowLimits.minWidth.toInt()}, '
        'height: ${WindowLimits.minHeight.toInt()}',
      ),
    );
  });

  test('Android asks for INTERNET and is named WizCtl', () {
    var manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(
      manifest,
      contains('<uses-permission android:name="android.permission.INTERNET"/>'),
    );
    expect(manifest, contains('android:label="WizCtl"'));
    expect(
      _read('android/app/build.gradle.kts'),
      contains('applicationId = "com.dotstudios.wizctl_app"'),
    );
  });

  test('Windows and Linux title the window WizCtl and set the minimum', () {
    expect(_read('windows/runner/main.cpp'), contains('L"WizCtl"'));
    var win32 = _read('windows/runner/win32_window.cpp');
    expect(win32, contains('WM_GETMINMAXINFO'));
    expect(win32, contains('${WindowLimits.minWidth.toInt()}'));
    expect(win32, contains('${WindowLimits.minHeight.toInt()}'));
    var linux = _read('linux/runner/my_application.cc');
    expect(linux, contains('"WizCtl"'));
    expect(linux, contains('gtk_window_set_geometry_hints'));
    expect(linux, contains('min_width = ${WindowLimits.minWidth.toInt()}'));
    expect(linux, contains('min_height = ${WindowLimits.minHeight.toInt()}'));
  });
}
