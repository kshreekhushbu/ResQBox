import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatTimestamp(String timestamp) {
  DateTime parsedDate =
      DateTime.parse(timestamp).toLocal(); // Convert to local timezone
  String formattedDate = DateFormat("dd MMM yyyy, hh:mm a").format(parsedDate);
  return formattedDate;
}

// Format Date (dd-MM-yyyy)
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '--';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    debugPrint("Date parsing error: $e");
    return '--';
  }
}

String formatTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '--';
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('hh:mm a').format(date);
  } catch (e) {
    debugPrint("Time parsing error: $e");
    return '--';
  }
}

String formatNotificationDateTime(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '--';
  try {
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('hh:mm a, dd MMM yyyy').format(date);
  } catch (e) {
    debugPrint("Notification date parsing error: $e");
    return '--';
  }
}

// Convert TimeOfDay to formatted HH:mm string 12 hours format

String formatTimeOfDay(TimeOfDay? time) {
  if (time == null) return '';

  final now = DateTime.now();
  final dateTime =
      DateTime(now.year, now.month, now.day, time.hour, time.minute);

  return DateFormat('hh:mm a').format(dateTime); // 12-hour format with AM/PM
}

String truncateText(String text, int length) {
  return text.length > length ? '${text.substring(0, length)}...' : text;
}

String formattedHMTime(String isoTime) {
  DateTime parsedTime = DateTime.parse(isoTime)
      .toUtc()
      .add(const Duration(hours: 5, minutes: 30));
  String formattedTime = DateFormat('hh:mm a').format(parsedTime);
  return formattedTime;
}

TimeOfDay parseTime(String timeStr) {
  // Remove leading/trailing spaces
  timeStr = timeStr.trim();

  // Split by space to separate time from AM/PM
  final timeParts = timeStr.split(' ');
  if (timeParts.length != 2) {
    throw FormatException('Invalid time format');
  }

  // Split the time by the colon to extract hours and minutes
  final time = timeParts[0].split(':');
  if (time.length != 2) {
    throw FormatException('Invalid time format');
  }

  final hour = int.parse(time[0].trim());
  final minute = int.parse(time[1].trim());
  final period = timeParts[1].toUpperCase();

  // Adjust hour based on AM/PM
  int adjustedHour = hour;
  if (period == 'PM' && hour != 12) {
    adjustedHour += 12;
  } else if (period == 'AM' && hour == 12) {
    adjustedHour = 0;
  }

  return TimeOfDay(hour: adjustedHour, minute: minute);
}

String formattedTimeOfDay(TimeOfDay? time) {
  debugPrint(".......... $time");
  if (time == null) return "00:00";
  final hour = time.hourOfPeriod.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  debugPrint("------------ $hour $minute $period");
  return "$hour:$minute $period";
}

bool isKitchenClosed(List<String> operatingHours) {
  // debugPrint("..........////////// $operatingHours");
  if (operatingHours.length < 2) return true;

  try {
    final now = DateTime.now();
    final format = DateFormat('hh:mm a');

    // Safely parse times
    TimeOfDay startTod = _parseTime(operatingHours[0]);
    TimeOfDay endTod = _parseTime(operatingHours[1]);

    DateTime startTime =
        DateTime(now.year, now.month, now.day, startTod.hour, startTod.minute);
    DateTime endTime =
        DateTime(now.year, now.month, now.day, endTod.hour, endTod.minute);

    // Handle overnight case (e.g., 10 PM to 2 AM)
    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    // Now >= startTime && now < endTime means open
    final isOpen =
        (now.isAtSameMomentAs(startTime) || now.isAfter(startTime)) &&
            now.isBefore(endTime);

    return !isOpen; // true if closed
  } catch (e) {
    debugPrint("Error in time parsing: $e");
    return true;
  }
}

TimeOfDay _parseTime(String timeStr) {
  final format = DateFormat('hh:mm a');
  final dt = format.parse(timeStr.trim()); // <-- FIX applied here
  return TimeOfDay(hour: dt.hour, minute: dt.minute);
}
