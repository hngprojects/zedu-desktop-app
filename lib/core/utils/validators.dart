import 'package:zedu/core/core.dart';

class Validators {
  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    if (_hasSequentialOrRepeating(value)) {
      return 'Password must not contain sequential or repeating characters';
    }
    return null;
  }

  static bool _hasSequentialOrRepeating(String value) {
    if (value.length < 3) return false;
    for (int i = 0; i < value.length - 2; i++) {
      final c1 = value.codeUnitAt(i);
      final c2 = value.codeUnitAt(i + 1);
      final c3 = value.codeUnitAt(i + 2);

      // Repeating characters (e.g. "aaa", "111")
      if (c1 == c2 && c2 == c3) {
        return true;
      }

      // Sequential ascending (e.g. "abc", "123")
      if (c2 == c1 + 1 && c3 == c2 + 1) {
        if (_isAlphanumeric(c1) && _isAlphanumeric(c2) && _isAlphanumeric(c3)) {
          return true;
        }
      }

      // Sequential descending (e.g. "cba", "321")
      if (c2 == c1 - 1 && c3 == c2 - 1) {
        if (_isAlphanumeric(c1) && _isAlphanumeric(c2) && _isAlphanumeric(c3)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isAlphanumeric(int codeUnit) {
    return (codeUnit >= 48 && codeUnit <= 57) || // 0-9
        (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  static String? validateRequired(
    BuildContext context,
    String? value, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }
}
