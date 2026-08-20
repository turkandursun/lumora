import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Safe Space RPC projection cannot return user_id', () async {
    final sql = await File(
      'supabase/sql/daily_question_shares_anonymous_feed.sql',
    ).readAsString();
    final returnColumns = RegExp(
      r'returns\s+table\s*\((.*?)\)\s*language',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql)?.group(1);

    expect(returnColumns, isNotNull);
    expect(returnColumns!.toLowerCase(), isNot(contains('user_id')));
    expect(sql, contains('using (auth.uid() = user_id)'));
    expect(sql, contains("set search_path = ''"));
    expect(sql, contains("raise exception 'Authentication required'"));
  });

  test('legacy social DB migrations revoke access without deleting data',
      () async {
    for (final path in [
      'supabase/sql/legacy_community_posts_decommission.sql',
      'supabase/sql/legacy_activity_posts_decommission.sql',
    ]) {
      final sql = (await File(path).readAsString()).toLowerCase();
      expect(sql, contains('revoke all privileges'));
      expect(sql, isNot(contains('delete from')));
      expect(sql, isNot(contains('drop table')));
      expect(sql, isNot(contains('truncate')));
    }
  });

  test('legacy activity bucket becomes private without deleting objects',
      () async {
    final sql = (await File(
      'supabase/sql/legacy_activity_posts_storage_lockdown.sql',
    ).readAsString())
        .toLowerCase();

    expect(sql, contains('set public = false'));
    expect(sql, contains('drop policy'));
    expect(sql, isNot(contains('delete from storage.objects')));
    expect(sql, isNot(contains('drop bucket')));
  });

  test('Android release signing cannot fall back to the debug key', () async {
    final gradle = await File('android/app/build.gradle.kts').readAsString();

    expect(gradle, contains('releaseSigningRequested'));
    expect(gradle, contains('throw GradleException'));
    expect(gradle, contains('configuredStoreFile.isFile'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });
}
