/// Failures the user can act on; presentation turns them into copy.
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);
  @override
  String toString() => message;
}

final class EmptyNameException extends DomainException {
  const EmptyNameException() : super('A name is required.');
}

final class LastHomeException extends DomainException {
  const LastHomeException()
    : super('A home is required. Add another before removing this one.');
}

final class RoomNotEmptyException extends DomainException {
  const RoomNotEmptyException() : super('Move its lights first.');
}

final class AlreadySavedException extends DomainException {
  const AlreadySavedException() : super('This light is already in this home.');
}
