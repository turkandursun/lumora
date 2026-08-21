import 'package:flutter/material.dart';

import '../../../../core/services/smart_reminders_service.dart';
import '../../../../theme/astra_screen_kit.dart';

/// Settings card for ASTRA's rotating daily nudges. A single master switch
/// turns all five slots on or off; the times are fixed by product spec and
/// shown here read-only so the user knows what to expect.
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = AstraKit.primary(context, isDark);
    final isTr = _isTr;

    final rows = <_SlotInfo>[
      _SlotInfo(
        Icons.wb_sunny_rounded,
        isTr ? 'Güne başlarken' : 'Morning boost',
        isTr ? 'Sabah motivasyonu' : 'Morning motivation',
        '09:00',
      ),
      _SlotInfo(
        Icons.self_improvement_rounded,
        isTr ? 'Gün içi molası' : 'Midday break',
        isTr ? 'Nefes ve odaklanma' : 'Breathe and refocus',
        '13:00',
      ),
      _SlotInfo(
        Icons.favorite_rounded,
        isTr ? 'Öz değer hatırlatıcısı' : 'Self-worth reminder',
        isTr ? 'Kendine bir hatırlatma' : 'A note to yourself',
        '18:00',
      ),
      _SlotInfo(
        Icons.nightlight_round,
        isTr ? 'Gün sonu' : 'Wind down',
        isTr ? 'Gevşeme ve meditasyon' : 'Relax and reflect',
        '22:00',
      ),
      _SlotInfo(
        Icons.waving_hand_rounded,
        isTr ? 'Yoklama' : 'Check-in',
        isTr ? 'Uğramadığın günlerde' : 'On days you stay away',
        '15:00',
      ),
    ];

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
                onChanged:
                    _loaded ? (v) => _persist(_s.copyWith(enabled: v)) : null,
              ),
            ],
          ),
          if (_s.enabled) ...[
            const SizedBox(height: 6),
            Text(
              isTr
                  ? 'Gün boyu her seferinde farklı, sıcacık mesajlar 💛'
                  : 'Warm, always-different messages through the day 💛',
              style: AstraKit.mutedText(context, isDark, fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            for (final row in rows) ...[
              _SlotRow(info: row, isDark: isDark, primary: primary),
              if (row != rows.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _SlotInfo {
  const _SlotInfo(this.icon, this.label, this.hint, this.time);

  final IconData icon;
  final String label;
  final String hint;
  final String time;
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.info,
    required this.isDark,
    required this.primary,
  });

  final _SlotInfo info;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Row(
        children: [
          Icon(info.icon, color: primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label,
                    style: AstraKit.body(context, isDark,
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(info.hint,
                    style:
                        AstraKit.mutedText(context, isDark, fontSize: 11.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(info.time,
                style: AstraKit.body(context, isDark,
                        fontSize: 14, fontWeight: FontWeight.w800)
                    .copyWith(color: primary)),
          ),
        ],
      ),
    );
  }
}
