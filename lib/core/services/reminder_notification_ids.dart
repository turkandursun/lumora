import 'dart:convert';

/// Positive 31-bit notification ids reserved for Lumora reminders.
///
/// Bit 30 is the namespace marker and the remaining 30 bits are a stable
/// FNV-1a hash of the Supabase UUID (or a temporary local identity while an
/// offline reminder has not reached Supabase yet). This gives reminders a
/// separate range of 1,073,741,824 ids without touching other Lumora
/// notification namespaces.
const int reminderNotificationNamespace = 0x40000000;
const int _reminderNotificationPayloadMask = 0x3fffffff;
const int _positive31BitMask = 0x7fffffff;

int reminderNotificationId(String stableIdentity) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(stableIdentity)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return (reminderNotificationNamespace |
          (hash & _reminderNotificationPayloadMask)) &
      _positive31BitMask;
}

bool isReminderNotificationId(int id) =>
    id >= reminderNotificationNamespace && id <= _positive31BitMask;
