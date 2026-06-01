class EValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );

    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$'
    );

    if (!passwordRegExp.hasMatch(value)) {
      return 'Password must be at least 8 characters long and include both letters and numbers';
    }

    return null;
  }
  
   static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final RegExp phoneRegExp = RegExp(
      r'^\+?[1-9]\d{1,14}$'
    );

    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }

    return null;
  }
}