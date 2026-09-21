import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/widgets/notice_listener.dart';

import '../../support/wiz_test_app.dart';

/// A notice with value equality, like every real one: the listener has to
/// re-fire on an equal notice raised again, not merely on a new object.
@immutable
class _Notice {
  final String text;
  const _Notice(this.text);
  @override
  bool operator ==(Object other) => other is _Notice && other.text == text;
  @override
  int get hashCode => text.hashCode;
}

@immutable
class _NoticeState {
  final _Notice? notice;
  const _NoticeState(this.notice);
  @override
  bool operator ==(Object other) =>
      other is _NoticeState && other.notice == notice;
  @override
  int get hashCode => notice.hashCode;
}

/// The smallest bloc that can carry a notice and be told to drop it.
class _NoticeCubit extends Cubit<_NoticeState> {
  _NoticeCubit() : super(const _NoticeState(null));
  void raise(String text) => emit(_NoticeState(_Notice(text)));
  void clear() => emit(const _NoticeState(null));
}

void main() {
  late _NoticeCubit cubit;
  late List<String> seen;

  setUp(() {
    cubit = _NoticeCubit();
    seen = [];
  });

  tearDown(() => cubit.close());

  Widget subject() => wizTestApp(
    BlocProvider<_NoticeCubit>.value(
      value: cubit,
      child: NoticeListener<_NoticeCubit, _NoticeState, _Notice>(
        noticeOf: (state) => state.notice,
        onNotice: (context, notice) => seen.add(notice.text),
        clear: (bloc) => bloc.clear(),
        child: const SizedBox.shrink(),
      ),
    ),
  );

  testWidgets('a notice fires once and is cleared', (tester) async {
    await tester.pumpWidget(subject());
    cubit.raise('one');
    await tester.pump();
    expect(seen, ['one']);
    expect(cubit.state.notice, isNull, reason: 'cleared by the listener');
    await tester.pump();
    expect(seen, ['one'], reason: 'the clear itself must not fire it again');
  });

  testWidgets('the same notice raised again fires again', (tester) async {
    await tester.pumpWidget(subject());
    cubit.raise('one');
    await tester.pump();
    cubit.raise('one');
    await tester.pump();
    expect(seen, ['one', 'one']);
  });

  testWidgets('a null notice never fires', (tester) async {
    await tester.pumpWidget(subject());
    cubit.clear();
    await tester.pump();
    expect(seen, isEmpty);
  });
}
