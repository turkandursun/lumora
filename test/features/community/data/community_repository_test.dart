import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindful_journal/features/community/data/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Safe Space feed uses the UUID-free RPC projection', () async {
    late http.Request capturedRequest;
    final httpClient = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode([
          {
            'id': 'share-1',
            'display_name': 'Sessiz Yildiz',
            'answer_text': 'Bugun kendime zaman ayirdim.',
            'created_at': '2026-08-20T09:30:00.000Z',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final client = SupabaseClient(
      'https://example.supabase.co',
      'publishable-key',
      httpClient: httpClient,
    );
    addTearDown(client.dispose);

    final shares = await CommunityRepository(client: client)
        .fetchSharesForDate(DateTime(2026, 8, 20));

    expect(
      capturedRequest.url.path,
      '/rest/v1/rpc/get_daily_question_shares_feed',
    );
    expect(
      jsonDecode(capturedRequest.body),
      {'p_question_date': '2026-08-20'},
    );
    expect(shares, hasLength(1));
    expect(shares.single.id, 'share-1');
    expect(capturedRequest.body, isNot(contains('user_id')));
  });
}
