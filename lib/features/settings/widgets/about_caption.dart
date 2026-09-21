import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wizctl/wizctl.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';

/// The About caption at the foot of Settings (spec §10.7): the app's own
/// version beside the version of the `wizctl` package that talks to the bulbs.
///
/// Nothing while the platform is still reporting the app's version — an empty
/// line for a frame is better than a placeholder the user might read as the
/// real number.
class AboutCaption extends StatefulWidget {
  const AboutCaption({super.key});

  @override
  State<AboutCaption> createState() => _AboutCaptionState();
}

class _AboutCaptionState extends State<AboutCaption> {
  /// Asked for once, in a field rather than in `build`: a rebuild would
  /// otherwise start a fresh platform call and flash the caption away.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        var app = snapshot.data?.version;
        if (app == null) return const SizedBox.shrink();
        return Text(
          Strings.version(app, cliVersion),
          textAlign: TextAlign.center,
          style: wiz.typography.caption.copyWith(
            color: wiz.colors.textTertiary,
          ),
        );
      },
    );
  }
}
