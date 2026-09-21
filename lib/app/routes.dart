/// The app's locations (spec §9). Screens navigate with these; only the
/// router knows the patterns.
class AppRoutes {
  AppRoutes._();

  static const String setup = '/setup';
  static const String home = '/home';
  static const String rooms = '/rooms';
  static const String modes = '/modes';
  static const String settings = '/settings';
  static const String discover = '/discover';

  /// Debug builds only (Task 19): the widget gallery behind the Settings row.
  static const String gallery = '/gallery';

  static const String roomParam = 'roomId';
  static const String lightParam = 'lightId';
  static const String roomPattern = '$rooms/:$roomParam';
  static const String lightPattern = '/lights/:$lightParam';

  static String room(String roomId) => '$rooms/$roomId';
  static String light(String lightId) => '/lights/$lightId';
}
