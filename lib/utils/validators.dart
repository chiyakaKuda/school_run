/// Form field validators. Each returns `null` when the value is acceptable,
/// or an error message to show under the field.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^\+?[\d\s-]{7,15}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? phone(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    if (!_phone.hasMatch(v)) return 'Enter a valid phone number.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match.';
    return null;
  }
}
