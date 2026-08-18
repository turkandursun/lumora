import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/profile/data/profile_repository.dart';

void main() {
  test('fresh profile payload explicitly starts soft lilac and light', () {
    final updatedAt = DateTime.utc(2026, 8, 18, 9, 30);

    final payload = ProfileRepository.buildFreshProfilePayload(
      userId: 'new-user',
      email: 'new@example.com',
      fullName: '  Astra User  ',
      updatedAt: updatedAt,
    );

    expect(payload['id'], 'new-user');
    expect(payload['email'], 'new@example.com');
    expect(payload['full_name'], 'Astra User');
    expect(payload['palette_id'], 'soft_lilac_mist');
    expect(payload['theme_preference'], 'light');
    expect(payload['updated_at'], updatedAt.toIso8601String());
  });

  test('fresh profile payload does not invent an empty full name', () {
    final payload = ProfileRepository.buildFreshProfilePayload(
      userId: 'new-user',
      email: null,
      fullName: '   ',
      updatedAt: DateTime.utc(2026, 8, 18),
    );

    expect(payload, isNot(contains('full_name')));
    expect(payload['theme_preference'], defaultProfileThemePreference);
  });
}
