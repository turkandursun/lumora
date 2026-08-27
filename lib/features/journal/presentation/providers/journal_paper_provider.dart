import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ruling drawn behind the journal writing area.
enum JournalPaper {
  blank('blank', 'Boş', 'Blank'),
  lined('lined', 'Çizgili', 'Lined'),
  grid('grid', 'Kareli', 'Grid'),
  dotted('dotted', 'Noktalı', 'Dotted');

  const JournalPaper(this.wire, this.labelTr, this.labelEn);

  final String wire;
  final String labelTr;
  final String labelEn;

  static JournalPaper fromWire(String? v) => JournalPaper.values.firstWhere(
        (p) => p.wire == v,
        orElse: () => JournalPaper.lined,
      );
}

/// Persists the user's chosen writing-paper ruling (global preference).
class JournalPaperNotifier extends StateNotifier<JournalPaper> {
  JournalPaperNotifier() : super(JournalPaper.lined) {
    _load();
  }

  static const _key = 'journal_paper_style_v1';

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = JournalPaper.fromWire(p.getString(_key));
    } catch (_) {
      // Keep the default on any failure.
    }
  }

  Future<void> set(JournalPaper paper) async {
    state = paper;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, paper.wire);
    } catch (_) {}
  }
}

final journalPaperProvider =
    StateNotifierProvider<JournalPaperNotifier, JournalPaper>(
  (ref) => JournalPaperNotifier(),
);

/// Paints the chosen ruling using a theme-supplied [color], so the paper always
/// matches the app's active palette (light/dark + accent).
class JournalPaperPainter extends CustomPainter {
  const JournalPaperPainter({required this.paper, required this.color});

  final JournalPaper paper;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    const gap = 30.0;

    switch (paper) {
      case JournalPaper.blank:
        break;
      case JournalPaper.lined:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        break;
      case JournalPaper.grid:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = gap; x < size.width; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case JournalPaper.dotted:
        final dot = Paint()..color = color;
        for (var y = gap; y < size.height; y += gap) {
          for (var x = gap; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 1, dot);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant JournalPaperPainter old) =>
      old.paper != paper || old.color != color;
}
