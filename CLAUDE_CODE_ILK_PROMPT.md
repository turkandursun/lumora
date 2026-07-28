# Claude Code'a Vereceğiniz İlk Prompt

Terminalde proje klasörünüzde `claude` komutunu çalıştırıp aşağıdakine benzer
bir mesajla başlayın. Ekli `pubspec.yaml` ve `PROJECT_STRUCTURE.md`
dosyalarını da aynı klasöre koyup Claude Code'un görmesini sağlayın.

---

**Prompt:**

> Flutter ile "Mindful Journal" adında, gizlilik odaklı ve AI destekli bir
> journaling uygulaması yazacağız. Hedef kitle: kişisel gelişim/mental
> wellness ilgilisi yetişkinler. Referans olarak Reflectly, Stoic ve Rosebud
> uygulamalarını düşün ama bizim öncelikli farkımız: (1) client-side
> şifreleme ile gerçek veri gizliliği, (2) daha derin AI destekli
> içgörü/analiz, (3) sade ve dikkat dağıtmayan tasarım, (4) CBT/Stoic
> temelli terapi-koçluk derinliği.
>
> Ekteki PROJECT_STRUCTURE.md'deki feature-first klasör mimarisini ve
> pubspec.yaml'daki bağımlılıkları kullan.
>
> Bu turda SADECE şunu yap:
> 1. `flutter create` ile projeyi oluştur (paket adı: com.mindfuljournal.app)
> 2. pubspec.yaml'ı verdiğim haliyle uygula, `flutter pub get` çalıştır
> 3. PROJECT_STRUCTURE.md'deki klasör iskeletini oluştur (boş dosyalar/placeholder'lar olsun)
> 4. main.dart ve app.dart'ı temel bir MaterialApp + go_router kurulumuyla çalışır hale getir
> 5. Supabase, AI, şifreleme gibi hassas entegrasyonlara HENÜZ dokunma — onları ayrı ayrı isteyeceğim
>
> İşin sonunda `flutter run -d chrome` ile açılabilen, boş ama hatasız
> çalışan bir uygulama olsun.

---

## Sonraki Adımlarda Kullanacağınız Promptlar (sırayla)

1. "Şimdi `features/auth` için Supabase email/magic-link girişini kur."
2. "Şimdi `features/journal` için offline-first yazma deneyimini kur (Drift ile), Supabase senkronizasyonu şimdilik basit tutulsun."
3. "Şimdi `core/services/encryption_service.dart` içinde AES şifreleme ekle, journal kaydından önce şifrele/sonra çöz."
4. "Şimdi backend tarafında (Supabase Edge Function) Claude API'ye istek atan bir AI analiz fonksiyonu yaz, `ai_service.dart` üzerinden Flutter'a bağla."

Her adımdan sonra çalıştırıp test edin, bir sonrakine öyle geçin.
