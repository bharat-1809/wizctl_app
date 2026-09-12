abstract interface class Clock {
  DateTime now();
  Future<void> delay(Duration duration);
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Future<void> delay(Duration duration) => Future<void>.delayed(duration);
}
