/// User-facing copy. Kept in one place so it can be swapped for a real
/// localisation delegate later without touching widgets.
class AppStrings {
  const AppStrings._();

  static const String appName = 'School Run';
  static const String tagline = 'Every child, safely there.';

  // Auth
  static const String login = 'Log in';
  static const String logout = 'Log out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String welcomeBack = 'Welcome back';
  static const String loginSubtitle = 'Sign in to continue your school run.';

  // Driver
  static const String driverHome = 'Today\'s run';
  static const String startTrip = 'Start trip';
  static const String endTrip = 'End trip';
  static const String students = 'Students';
  static const String pickedUp = 'Picked up';
  static const String droppedOff = 'Dropped off';

  // Parent
  static const String parentHome = 'My children';
  static const String liveTracking = 'Live tracking';
  static const String notifications = 'Notifications';
  static const String noNotifications = 'You\'re all caught up.';

  // Profile
  static const String profile = 'Profile';

  // Generic
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String loading = 'Loading…';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String noConnection = 'No internet connection.';
}
