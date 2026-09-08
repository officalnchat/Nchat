import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  static const MethodChannel _channel =
      MethodChannel('nchat/contacts');

  // ===========================
  // Request Contacts Permission
  // ===========================

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();

    return status.isGranted;
  }

  // ===========================
  // Check Contacts Permission
  // ===========================

  Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;

    return status.isGranted;
  }

  // ===========================
  // Get Phone Contacts
  // ===========================

  Future<List<String>> getContactNumbers() async {
    final hasAccess = await hasPermission();

    if (!hasAccess) {
      return [];
    }

    final List<dynamic> result =
        await _channel.invokeMethod<List<dynamic>>(
              'getContacts',
            ) ??
            [];

    final Set<String> normalizedNumbers = {};

    for (final contact in result) {
      if (contact is String) {
        final normalized =
            normalizeIndianNumber(contact);

        if (normalized != null) {
          normalizedNumbers.add(normalized);
        }
      }
    }

    return normalizedNumbers.toList();
  }

  // ===========================
  // Normalize Indian Number
  // ===========================

  String? normalizeIndianNumber(
    String phoneNumber,
  ) {
    String digits =
        phoneNumber.replaceAll(
      RegExp(r'\D'),
      '',
    );

    // +91XXXXXXXXXX / 91XXXXXXXXXX
    if (digits.startsWith('91') &&
        digits.length == 12) {
      digits = digits.substring(2);
    }

    // 0XXXXXXXXXX
    if (digits.startsWith('0') &&
        digits.length == 11) {
      digits = digits.substring(1);
    }

    // Normal 10 digit Indian mobile number
    if (digits.length != 10) {
      return null;
    }

    // Indian mobile numbers normally start with 6, 7, 8 or 9.
    if (!RegExp(r'^[6-9]').hasMatch(digits)) {
      return null;
    }

    return '+91$digits';
  }
}