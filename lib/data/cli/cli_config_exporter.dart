import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/light.dart';
import '../../domain/entities/room.dart';

/// Rewrites the CLI's config file from the active home so
/// `wizctl on -t "Living Room"` addresses the same lights (spec §16).
/// Desktop only; the file is overwritten and never read.
class CliConfigExporter {
  /// The path segments of the CLI's config file under the home directory:
  /// the CLI reads `~/.config/wizctl/config.json` (spec §16).
  static const String configDirectoryName = '.config';
  static const String toolDirectoryName = 'wizctl';
  static const String configFileName = 'config.json';

  /// The suffix of the scratch file the export writes before renaming it
  /// over the real one, so a reader never sees a half-written config.
  static const String temporarySuffix = '.tmp';

  final Directory Function() homeDirectory;

  CliConfigExporter({required this.homeDirectory});

  static Directory defaultHomeDirectory() => Directory(
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.',
  );

  File get file => File(
    p.join(
      homeDirectory().path,
      configDirectoryName,
      toolDirectoryName,
      configFileName,
    ),
  );

  static Map<String, dynamic> toJson({
    required List<Light> lights,
    required List<Room> rooms,
  }) {
    var byRoom = <String, List<String>>{};
    for (var room in rooms) {
      byRoom[room.name] = [
        for (var l in lights)
          if (l.roomId == room.id) l.ip,
      ];
    }
    return {
      'lights': {
        for (var l in lights) l.ip: {'alias': l.name, 'mac': l.mac},
      },
      'groups': byRoom,
    };
  }

  Future<void> export({
    required List<Light> lights,
    required List<Room> rooms,
  }) async {
    var target = file;
    await target.parent.create(recursive: true);
    var tmp = File('${target.path}$temporarySuffix');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(toJson(lights: lights, rooms: rooms)),
    );
    await tmp.rename(target.path);
  }
}
