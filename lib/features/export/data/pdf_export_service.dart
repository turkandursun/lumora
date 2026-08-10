import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../letters/data/letter_repository.dart';

/// Localized, pre-resolved strings the PDF needs, so the data layer stays free
/// of any `AppLocalizations`/`BuildContext` dependency.
class ExportLabels {
  const ExportLabels({
    required this.documentTitle,
    required this.rangeLine,
    required this.generatedOn,
    required this.journalSection,
    required this.dreamsSection,
    required this.lettersSection,
    required this.moodSection,
    required this.emptySection,
    required this.untitled,
    required this.moodDaysSuffix,
    required this.letterSealedFor,
    required this.moodNames,
    required this.localeCode,
  });

  final String documentTitle;
  final String rangeLine;
  final String generatedOn;
  final String journalSection;
  final String dreamsSection;
  final String lettersSection;
  final String moodSection;
  final String emptySection;
  final String untitled;
  final String moodDaysSuffix;
  final String letterSealedFor;

  /// Localized mood names in [AppMood] order: happy, calm, tired, sad, anxious.
  final List<String> moodNames;
  final String localeCode;
}

/// Everything gathered from the repositories, already filtered to the chosen
/// date range and sorted newest-first.
class ExportBundle {
  const ExportBundle({
    required this.journals,
    required this.dreams,
    required this.letters,
    required this.moods,
  });

  final List<JournalEntryRow> journals;
  final List<DreamRow> dreams;
  final List<Letter> letters;
  final Map<DateTime, int> moods;

  bool get isEmpty =>
      journals.isEmpty && dreams.isEmpty && letters.isEmpty && moods.isEmpty;
}

/// Builds a warm, readable PDF archive of the user's personal writing.
///
/// A Unicode font (Noto Sans) is embedded so Turkish, German, Spanish and
/// French characters render correctly — the PDF standard Helvetica font cannot
/// draw glyphs like ş, ğ, İ, ñ or ß. If the font can't be fetched we fall back
/// to the built-in font rather than failing the export.
Future<Uint8List> buildJournalPdf({
  required ExportBundle data,
  required ExportLabels labels,
}) async {
  pw.ThemeData? theme;
  try {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();
    theme = pw.ThemeData.withFont(base: regular, bold: bold, italic: italic);
  } catch (_) {
    theme = null; // graceful fallback to Helvetica
  }

  DateFormat dateFmt;
  try {
    dateFmt = DateFormat('d MMMM yyyy', labels.localeCode);
  } catch (_) {
    dateFmt = DateFormat('d MMMM yyyy');
  }
  String fmtDate(DateTime d) {
    try {
      return dateFmt.format(d);
    } catch (_) {
      return '${d.day}.${d.month}.${d.year}';
    }
  }

  const ink = PdfColor.fromInt(0xFF3A3346);
  const muted = PdfColor.fromInt(0xFF8A8296);
  const accent = PdfColor.fromInt(0xFFB07BC9);
  const rule = PdfColor.fromInt(0xFFE6DDF0);

  final doc = pw.Document();

  pw.Widget sectionHeader(String title) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: rule, width: 1)),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: accent,
          ),
        ),
      );

  pw.Widget entryCard({
    required String dateLine,
    String? heading,
    required String body,
    String? tag,
  }) =>
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFBF8FE),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: rule, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(dateLine,
                    style: const pw.TextStyle(fontSize: 9, color: muted)),
                if (tag != null && tag.isNotEmpty)
                  pw.Text(tag,
                      style: const pw.TextStyle(fontSize: 9, color: accent)),
              ],
            ),
            if (heading != null && heading.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(heading,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: ink)),
            ],
            pw.SizedBox(height: 4),
            pw.Text(body,
                style: const pw.TextStyle(fontSize: 11, color: ink, lineSpacing: 2)),
          ],
        ),
      );

  final content = <pw.Widget>[];

  // Journal entries
  content.add(sectionHeader(labels.journalSection));
  if (data.journals.isEmpty) {
    content.add(pw.Text(labels.emptySection,
        style: const pw.TextStyle(fontSize: 10, color: muted)));
  } else {
    for (final e in data.journals) {
      content.add(entryCard(
        dateLine: fmtDate(e.createdAt),
        heading: e.title,
        body: e.content,
      ));
    }
  }

  // Dreams
  content.add(sectionHeader(labels.dreamsSection));
  if (data.dreams.isEmpty) {
    content.add(pw.Text(labels.emptySection,
        style: const pw.TextStyle(fontSize: 10, color: muted)));
  } else {
    for (final d in data.dreams) {
      content.add(entryCard(
        dateLine: fmtDate(d.date),
        body: d.content,
        tag: d.symbolTags.isEmpty ? null : d.symbolTags.replaceAll(',', ' · '),
      ));
    }
  }

  // Letters to the future
  content.add(sectionHeader(labels.lettersSection));
  if (data.letters.isEmpty) {
    content.add(pw.Text(labels.emptySection,
        style: const pw.TextStyle(fontSize: 10, color: muted)));
  } else {
    for (final l in data.letters) {
      content.add(entryCard(
        dateLine: fmtDate(l.createdAt),
        heading: l.title,
        body: l.body,
        tag: '${labels.letterSealedFor} ${fmtDate(l.openAt)}',
      ));
    }
  }

  // Mood overview
  content.add(sectionHeader(labels.moodSection));
  if (data.moods.isEmpty) {
    content.add(pw.Text(labels.emptySection,
        style: const pw.TextStyle(fontSize: 10, color: muted)));
  } else {
    final counts = <int, int>{};
    for (final v in data.moods.values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    content.add(pw.Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (var i = 0; i < labels.moodNames.length; i++)
          if ((counts[i] ?? 0) > 0)
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF3EAFB),
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(
                '${labels.moodNames[i]}: ${counts[i]} ${labels.moodDaysSuffix}',
                style: const pw.TextStyle(fontSize: 10, color: ink),
              ),
            ),
      ],
    ));
  }

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 44),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(labels.documentTitle,
                  style: const pw.TextStyle(fontSize: 8, color: muted)),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: muted)),
      ),
      build: (ctx) => [
        // Cover block
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ASTRA',
                  style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: accent,
                      letterSpacing: 4)),
              pw.SizedBox(height: 6),
              pw.Text(labels.documentTitle,
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: ink)),
              pw.SizedBox(height: 2),
              pw.Text(labels.rangeLine,
                  style: const pw.TextStyle(fontSize: 10, color: muted)),
              pw.Text(labels.generatedOn,
                  style: const pw.TextStyle(fontSize: 9, color: muted)),
            ],
          ),
        ),
        ...content,
      ],
    ),
  );

  return doc.save();
}
