import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/cloud_backup_service.dart';

void main() {
  test('goals Drift table is owned by dedicated sync and excluded from backup',
      () {
    expect(CloudBackupService.isDedicatedSyncTable('goals'), isTrue);
  });

  test('focus sessions use dedicated sync and are excluded from backup', () {
    expect(
      CloudBackupService.isDedicatedSyncTable('focus_sessions'),
      isTrue,
    );
    expect(
      CloudBackupService.isDedicatedSyncTable('special_days'),
      isTrue,
    );
  });

  test('persistent content outboxes are excluded from generic backup', () {
    for (final table in const [
      'journal_entries',
      'dreams',
      'activities',
      'letters',
    ]) {
      expect(
        CloudBackupService.isDedicatedSyncTable(table),
        isTrue,
        reason: table,
      );
    }
  });

  test('legacy goal seed and generic streak keys are ignored on restore', () {
    expect(
      CloudBackupService.isDedicatedSyncPreference('goals_seeded'),
      isTrue,
    );
    expect(
      CloudBackupService.isDedicatedSyncPreference('goals_streak_count'),
      isTrue,
    );
    expect(
      CloudBackupService.isDedicatedSyncPreference(
        'goals_streak_last_active_date',
      ),
      isTrue,
    );
  });
}
