/// A localized quote from the app-wide quote catalogue.
class Quote {
  const Quote({
    required this.id,
    required this.textTr,
    required this.textEn,
    required this.isActive,
    required this.source,
    required this.updatedAt,
    this.author,
    this.rotationOrder,
  });

  final String id;
  final String textTr;
  final String textEn;
  final String? author;
  final int? rotationOrder;
  final bool isActive;
  final String source;
  final DateTime updatedAt;

  /// Returns the Turkish or English copy for the active app language.
  String text(bool isTr) => isTr ? textTr : textEn;
}
