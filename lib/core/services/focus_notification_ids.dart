import 'dart:convert';

/// Separate positive 31-bit namespace for focus completion notifications.
const int focusNotificationNamespace = 0x20000000;
const int _focusNotificationPayloadMask = 0x1fffffff;

int focusNotificationId(String stableIdentity) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(stableIdentity)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return focusNotificationNamespace | (hash & _focusNotificationPayloadMask);
}
