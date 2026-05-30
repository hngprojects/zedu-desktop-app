import 'package:flutter/material.dart';

class DateFormatter {
  static DateTime parseUtcString(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    String formattedString = dateString;
    if (!dateString.endsWith('Z') &&
        !dateString.contains('+') &&
        !dateString.contains(RegExp(r'-\d{2}:\d{2}'))) {
      formattedString += 'Z';
    }
    return DateTime.tryParse(formattedString)?.toLocal() ?? DateTime.now();
  }

  static String formatTime12h(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
