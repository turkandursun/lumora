import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Supabase Flutter'ın varsayılan anahtarıyla aynı public local storage.
///
/// Aynı instance'ı initialize ve kalıcı hesap silme akışında kullanmak,
/// silinen bir hesabın tokenının uygulama yeniden açıldığında yüklenmemesini
/// desteklenen SDK API'si üzerinden garanti eder.
final SharedPreferencesLocalStorage supabaseAuthLocalStorage =
    SharedPreferencesLocalStorage(
  persistSessionKey:
      'sb-${Uri.parse(Env.supabaseUrl).host.split('.').first}-auth-token',
);
