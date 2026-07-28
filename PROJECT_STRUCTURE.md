# Proje Klasör Mimarisi — Mindful Journal

Feature-first (özellik bazlı) yapı kullanıyoruz. Her özellik kendi klasöründe
data / domain / presentation katmanlarını barındırır. Bu sayede uygulama
büyüdükçe (yeni özellikler eklendikçe) kod tabanı dağılmaz.

```
lib/
├── main.dart
├── app.dart                        # MaterialApp / router kurulumu
│
├── core/                           # Ortak, feature'a özel olmayan kod
│   ├── config/
│   │   ├── env.dart                 # Supabase URL/key gibi ortam değişkenleri
│   │   └── theme.dart               # Renk paleti, tipografi (sade/minimal tasarım)
│   ├── router/
│   │   └── app_router.dart          # go_router tanımları
│   ├── services/
│   │   ├── encryption_service.dart  # Client-side AES şifreleme
│   │   ├── supabase_service.dart    # Supabase client wrapper
│   │   └── ai_service.dart          # Backend AI endpoint'ine istek atan servis
│   └── widgets/                     # Paylaşılan UI bileşenleri (buton, kart vb.)
│
├── features/
│   ├── auth/
│   │   ├── data/                    # Repository implementasyonları
│   │   ├── domain/                  # Modeller, interface'ler
│   │   └── presentation/
│   │       ├── screens/             # login_screen.dart, signup_screen.dart
│   │       └── providers/           # Riverpod auth state
│   │
│   ├── journal/
│   │   ├── data/
│   │   │   ├── local/                # Drift tabloları (offline yazım)
│   │   │   └── remote/               # Supabase repository
│   │   ├── domain/
│   │   │   └── journal_entry.dart    # Freezed model
│   │   └── presentation/
│   │       ├── screens/              # journal_editor_screen.dart, journal_list_screen.dart
│   │       └── providers/
│   │
│   ├── insights/                     # AI analiz / duygu-durum trendleri
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/              # mood_trend_screen.dart
│   │       └── widgets/              # fl_chart grafik bileşenleri
│   │
│   ├── prompts/                      # CBT / Stoic yansıtıcı soru kütüphanesi
│   │   ├── data/                     # Yerel prompt havuzu (JSON/asset)
│   │   └── presentation/
│   │
│   └── settings/
│       ├── presentation/
│       │   └── screens/              # privacy_settings_screen.dart, export_data_screen.dart
│
└── l10n/                              # Çoklu dil desteği (TR/EN)
```

## Katman Sorumlulukları

- **data/**: Supabase, Drift (SQLite) veya API çağrılarının somut implementasyonu.
- **domain/**: Saf Dart modelleri ve iş kuralları — hiçbir Flutter/UI bağımlılığı yok.
- **presentation/**: Ekranlar, widget'lar ve Riverpod provider'ları.

## İlk Aşamada Kurulacak Sıra (Claude Code ile)

1. `core/config` + `core/router` — boş ama çalışan bir uygulama iskeleti.
2. `features/auth` — Supabase email/OTP girişi.
3. `features/journal` — offline yazım + Supabase senkronizasyonu (şifreleme olmadan, önce çalışsın).
4. `core/services/encryption_service.dart` — journal verisine şifreleme entegrasyonu.
5. `features/insights` + `core/services/ai_service.dart` — AI analiz backend'e bağlanır.
6. `features/prompts`, `features/settings` — derinlik ve gizlilik kontrolleri.
