import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/theme/wiz_type.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';

/// Step 1, "Name this home" (spec §10.1): wordmark, hero, body, the field,
/// the key and the two lines beneath it, rising in one after another.
class NameHomeStep extends StatefulWidget {
  const NameHomeStep({super.key});

  /// `design/reference/WizCtl_Mobile.dc.html:50`: the first run's brand mark
  /// is 15 px at weight 800 — a size no type token carries.
  static const double wordmarkSize = 15;

  @override
  State<NameHomeStep> createState() => _NameHomeStepState();
}

class _NameHomeStepState extends State<NameHomeStep> {
  /// Seeded from the draft, so coming back to this step shows the name that
  /// was typed rather than an empty field.
  late final TextEditingController _name = TextEditingController(
    text: context.read<OnboardingBloc>().state.draftName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    var compact = context.layout.widthClass.isCompact;
    var nameEmpty = context.select<OnboardingBloc, bool>(
      (b) => b.state.nameEmpty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The prototype centres this step vertically, but the column lives in
        // a scroll view so the keyboard can push it: air above the wordmark is
        // what keeps it off the status bar on a phone.
        if (compact) SizedBox(height: wiz.space.s12),
        RiseIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Strings.wordmark,
                // The display face comes from the nearest token carrying it,
                // the way `GalleryWordmark` takes the rail's 30 px mark from
                // `title`; only the brand mark's own size, weight and tracking
                // are stated here.
                style: wiz.typography.heading.copyWith(
                  fontSize: NameHomeStep.wordmarkSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing:
                      NameHomeStep.wordmarkSize * WizType.wordmarkTrackingSmall,
                  height: 1,
                  color: wiz.colors.amber500,
                ),
              ),
              SizedBox(height: wiz.space.s8),
              Text(
                Strings.nameThisHome,
                // 44 on a phone, 64 on anything wider: the two sizes the
                // prototypes draw this hero at.
                style: (compact ? wiz.typography.display : wiz.typography.hero)
                    .copyWith(color: wiz.colors.textPrimary),
              ),
              SizedBox(height: wiz.space.s5),
              Text(
                Strings.homeStoredHere,
                style: wiz.typography.body.copyWith(
                  color: wiz.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.homeName),
              SizedBox(height: wiz.space.s3),
              WizTextField(
                controller: _name,
                height: wiz.space.controlLg,
                placeholder: Strings.homeNamePlaceholder,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (v) => bloc.add(OnboardingNameChanged(v)),
                onSubmitted: (_) => bloc.add(const OnboardingHomeCreated()),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizButton(
                label: Strings.createHome,
                variant: WizButtonVariant.primary,
                icon: WizIcons.radio,
                fullWidth: compact,
                // A blank name raises no notice from the bloc — the event is a
                // no-op — so the key itself is the guard.
                enabled: !nameEmpty,
                onPressed: () => bloc.add(const OnboardingHomeCreated()),
              ),
              SizedBox(height: wiz.space.s4),
              Text(
                Strings.homeRequired,
                style: wiz.typography.bodySm.copyWith(
                  color: wiz.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: wiz.space.s7),
        RiseIn(
          index: 3,
          child: Text(
            Strings.privacy,
            style: wiz.typography.bodySm.copyWith(
              color: wiz.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
