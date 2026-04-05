class PriceFormatter {
  static String formatCop(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    final formatted = '\$$buffer';
    return isNegative ? '-$formatted' : formatted;
  }

  static String formatCopFromNum(num value) {
    return formatCop(value.round());
  }
}
