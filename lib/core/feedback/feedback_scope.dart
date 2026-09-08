import 'package:flutter/widgets.dart';

import 'feedback_service.dart';

/// Makes a [FeedbackService] available to every control below it.
class FeedbackScope extends InheritedWidget {
  final FeedbackService service;

  const FeedbackScope({super.key, required this.service, required super.child});

  static final FeedbackService _silent = NoopFeedbackService();

  static FeedbackService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeedbackScope>()?.service ??
      _silent;

  @override
  bool updateShouldNotify(FeedbackScope oldWidget) =>
      service != oldWidget.service;
}

extension FeedbackContext on BuildContext {
  FeedbackService get feedback => FeedbackScope.of(this);
}
