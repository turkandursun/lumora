import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('special days migration enforces owner RLS and one birthday', () async {
    final sql = (await File('supabase/sql/special_days.sql').readAsString())
        .toLowerCase();

    expect(sql, contains('enable row level security'));
    expect(sql, contains('force row level security'));
    expect(sql, contains('(select auth.uid()) = user_id'));
    expect(sql, contains('special_days_one_birthday_per_user'));
    expect(sql, contains("where day_type = 'birthday'"));
    expect(sql, contains('on delete cascade'));
    expect(sql, contains('revoke all on table public.special_days'));
    expect(sql, isNot(contains('grant all')));
  });
}
