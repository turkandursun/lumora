/// One PIN-lockable area of the app. Each value is independently toggleable
/// in App Lock settings — the same PIN protects whichever sections the user
/// turns on, but a section left off is reached with no PIN prompt at all.
enum AppSection {
  journalWriting,
  aiChat,
  dreamJournal,
}

/// Maps [AppSection] to/from the plain-string key it's persisted under in
/// [FlutterSecureStorage] (a stable wire format, independent of enum
/// declaration order so storage survives future reordering/additions).
extension AppSectionStorageKey on AppSection {
  String get storageKey {
    switch (this) {
      case AppSection.journalWriting:
        return 'journal_writing';
      case AppSection.aiChat:
        return 'ai_chat';
      case AppSection.dreamJournal:
        return 'dream_journal';
    }
  }

  static AppSection? fromStorageKey(String key) {
    switch (key) {
      case 'journal_writing':
        return AppSection.journalWriting;
      case 'ai_chat':
        return AppSection.aiChat;
      case 'dream_journal':
        return AppSection.dreamJournal;
      default:
        return null;
    }
  }
}
