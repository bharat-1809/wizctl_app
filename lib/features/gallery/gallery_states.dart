import 'package:flutter/material.dart';

import '../../core/copy/strings.dart';
import '../../core/icons/wiz_icon_data.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_empty_state.dart';
import '../../core/widgets/wiz_filament_bar.dart';
import '../../core/widgets/wiz_panel.dart';
import '../../core/widgets/wiz_skeleton.dart';
import '../../core/widgets/wiz_spinner.dart';
import '../../core/widgets/wiz_status_banner.dart';
import '../../core/widgets/wiz_toast.dart';
import 'gallery_section.dart';

/// Loaders, banners, toasts and the empty state — every way the app tells
/// the user it is busy or that something went wrong.
class GalleryStates extends StatelessWidget {
  final ToastController toasts;

  const GalleryStates({super.key, required this.toasts});

  /// A part-swept subnet, so the determinate bar has something to show.
  static const double sweptFraction = 0.47;

  /// The skeleton row's avatar well and its two text bars
  /// (spec §11.2 `WizSkeleton`).
  static const double skeletonAvatar = 40;
  static const double skeletonTitleWidth = 160, skeletonTitleHeight = 14;
  static const double skeletonMetaWidth = 90, skeletonMetaHeight = 10;

  /// How long the demo's loading toast pretends to be saving before it
  /// resolves in place.
  static const Duration fakeSave = Duration(milliseconds: 900);

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var space = wiz.space;
    return GallerySection(
      title: 'States',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WizFilamentBar(value: sweptFraction, label: 'Sweeping subnet'),
          SizedBox(height: space.s5),
          const WizFilamentBar(label: 'Discovering'),
          SizedBox(height: space.s5),
          Row(
            children: [
              const WizSpinner(),
              SizedBox(width: space.s5),
              const WizSpinner(accent: false),
              SizedBox(width: space.s5),
              Expanded(
                child: Text(
                  'Listening for lights',
                  style: wiz.typography.bodySm.copyWith(
                    color: wiz.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: space.s5),
          WizPanel(
            padding: EdgeInsets.symmetric(
              vertical: space.s5,
              horizontal: space.s5,
            ),
            child: Row(
              children: [
                const WizSkeleton(height: skeletonAvatar, circle: true),
                SizedBox(width: space.s5),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WizSkeleton(
                        width: skeletonTitleWidth,
                        height: skeletonTitleHeight,
                      ),
                      SizedBox(height: skeletonMetaHeight),
                      WizSkeleton(
                        width: skeletonMetaWidth,
                        height: skeletonMetaHeight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: space.s5),
          WizStatusBanner(
            status: WizStatus.error,
            title: 'Not on the home network',
            body:
                'This device is on 10.0.0.0/24. Lights answer only on '
                '192.168.1.0/24.',
            action: WizButton(
              label: Strings.retry,
              variant: WizButtonVariant.ghost,
              size: WizButtonSize.sm,
              onPressed: () {},
            ),
          ),
          SizedBox(height: space.s5),
          const WizStatusBanner(
            status: WizStatus.loading,
            title: 'Sweeping 192.168.1.0/24',
            body: '68 of 254 addresses',
          ),
          SizedBox(height: space.s5),
          const WizStatusBanner(
            status: WizStatus.success,
            title: '3 lights answered',
            body: 'Broadcast on 192.168.1.0/24',
          ),
          SizedBox(height: space.s5),
          const WizStatusBanner(
            status: WizStatus.warn,
            title: 'Broadcast was filtered',
            body: Strings.broadcastHint,
          ),
          SizedBox(height: space.s5),
          const WizStatusBanner(
            status: WizStatus.info,
            title: 'Local network only',
            body: Strings.privacy,
          ),
          SizedBox(height: space.s5),
          Wrap(
            spacing: space.s4,
            runSpacing: space.s4,
            children: [
              WizButton(
                label: 'Success toast',
                size: WizButtonSize.sm,
                onPressed: () => toasts.push(
                  tone: WizToastTone.success,
                  title: 'Cozy applied',
                  body: 'to the whole home',
                ),
              ),
              WizButton(
                label: 'Error toast',
                size: WizButtonSize.sm,
                onPressed: () => toasts.push(
                  tone: WizToastTone.error,
                  title: 'No response after 3 tries',
                  body: '192.168.1.118 did not answer on port 38899',
                  actionLabel: Strings.retry,
                  onAction: () {},
                ),
              ),
              WizButton(
                label: 'Info toast',
                size: WizButtonSize.sm,
                onPressed: () => toasts.push(
                  tone: WizToastTone.info,
                  title: 'Living Room is mixed',
                  body: Strings.mixed,
                ),
              ),
              WizButton(
                label: 'Loading toast',
                size: WizButtonSize.sm,
                onPressed: _pushLoadingToast,
              ),
            ],
          ),
          SizedBox(height: space.s5),
          // The card the layer stacks, shown standing still: a queued toast
          // takes itself away after 3.2 s, which is no use for judging it.
          const GalleryToastSample(),
          SizedBox(height: space.s5),
          WizEmptyState(
            icon: WizIcons.radio,
            title: Strings.noResponse,
            body: Strings.broadcastHint,
            action: WizButton(
              label: Strings.scanSubnet,
              variant: WizButtonVariant.primary,
              icon: WizIcons.radio,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// A loading toast that resolves in place, which is how a long write
  /// reports back (spec §5.11).
  void _pushLoadingToast() {
    var id = toasts.push(
      tone: WizToastTone.loading,
      title: 'Saving Bedside bulb',
    );
    Future<void>.delayed(
      fakeSave,
      () => toasts.update(
        id,
        tone: WizToastTone.success,
        title: 'Bedside bulb saved',
        body: '192.168.1.115 added to this home',
      ),
    );
  }
}

/// The toast card itself, shown inline so the gallery has one on screen
/// without waiting for a queue: [WizToastLayer] renders the same widget.
class GalleryToastSample extends StatelessWidget {
  const GalleryToastSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const WizToast(
      data: WizToastData(
        id: 'gallery-sample',
        tone: WizToastTone.success,
        title: 'Cozy applied',
        body: 'to the whole home',
      ),
    );
  }
}
