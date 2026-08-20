import 'package:flutter/material.dart';

import '../../../../core/services/smart_reminders_service.dart';
import '../../../../theme/astra_screen_kit.dart';

/// Settings card for the two smart daily nudges (morning check-in + evening
/// writing invite). Self-contained: loads and persists its own state and
/// (re)schedules the notifications on every change.
class SmartRemindersCard extends StatefulWidget {
  const SmartRemindersCard({super.key, required this.isDark});

  final bool isDark;

  @override
  State<SmartRemindersCard> createState() => _SmartRemindersCardState();
}

class _SmartRemindersCardState extends State<SmartRemindersCard> {
  SmartReminderSettings _s = const SmartReminderSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    SmartRemindersService.instance.load().then((s) {
      if (mounted) {
        setState(() {
            _s = s;
            _loaded = true;
          });
      }
    });
  }

  bool get _isTr => Localizations.localeOf(context).languageCode == 'tr';

  Future<void> _persist(SmartReminderSettings next) async {
    setState(() => _s = next);
    await SmartRemindersService.instance.save(next, isTr: _isTr);
  }

  // 0 = morning good-morning, 1 = evening "pişt", 2 = night good-night.
  Future<void> _pickTime(int slot) async {
    final initial = switch (slot) {
      0 => TimeOfDay(hour: _s.morningHour, minute: _s.morningMinute),
      1 => TimeOfDay(hour: _s.eveningHour, minute: _s.eveningMinute),
      _ => TimeOfDay(hour: _s.nightHour, minute: _s.nightMinute),
    };
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await _persist(switch (slot) {
      0 => _s.copyWith(morningHour: picked.hour, morningMinute: picked.minute),
      1 => _s.copyWith(eveningHour: picked.hour, eveningMinute: picked.minute),
      _ => _s.copyWith(nightHour: picked.hour, nightMinute: picked.minute),
    });
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = AstraKit.primary(context, isDark);
    final isTr = _isTr;

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isTr ? 'Akıllı hatırlatmalar' : 'Smart reminders',
                  style: AstraKit.body(context, isDark,
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Switch.adaptive(
                value: _s.enabled,
                activeThumbColor: primary,
                activeTrackColor: primary.withValues(alpha: 0.4),
                onChanged: _loaded
                    ? (v) => _persist(_s.copyWith(enabled: v))
                    : null,
              ),
            ],
          ),
          if (_s.enabled) ...[
            const SizedBox(height: 4),
            _TimeRow(
              icon: Icons.wb_sunny_rounded,
              label: isTr ? 'Günaydın mesajı' : 'Good-morning message',
              hint: isTr ? 'Sıcak bir başlangıç ☀️' : 'A warm start ☀️',
              time: _fmt(_s.morningHour, _s.morningMinute),
              isDark: isDark,
              primary: primary,
              onTap: () => _pickTime(0),
            ),
            const SizedBox(height: 8),
            _TimeRow(
              icon: Icons.waving_hand_rounded,
              label: isTr ? 'Pişt, neredesin?' : 'Psst, where are you?',
              hint: isTr
                  ? 'Gün boyu uğramazsan 👀'
                  : "If you don't drop by all day 👀",
              time: _fmt(_s.eveningHour, _s.eveningMinute),
              isDark: isDark,
              primary: primary,
              onTap: () => _pickTime(1),
            ),
            const SizedBox(height: 8),
            _TimeRow(
              icon: Icons.nightlight_round,
              label: isTr ? 'İyi geceler mesajı' : 'Good-night message',
              hint: isTr ? 'Tatlı rüyalar 🌙' : 'Sweet dreams 🌙',
              time: _fmt(_s.nightHour, _s.nightMinute),
              isDark: isDark,
              primary: primary,
              onTap: () => _pickTime(2),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.time,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String time;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AstraKit.body(context, isDark,
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text(hint, style: AstraKit.mutedText(context, isDark, fontSize: 11.5)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(time,
                  style: AstraKit.body(context, isDark,
                          fontSize: 14, fontWeight: FontWeight.w800)
                      .copyWith(color: primary)),
            ),
          ],
        ),
      ),
    );
  }
}
