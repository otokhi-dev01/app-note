extension StringExtension on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 6;
  }
}
