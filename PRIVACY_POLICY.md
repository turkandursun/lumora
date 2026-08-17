# Astra — Gizlilik Politikası

**Son güncelleme:** [GG.AA.YYYY — yayına vermeden önce doldur]
**Geçerlilik tarihi:** [GG.AA.YYYY]

> ⚠️ **Doldurman gereken yerler köşeli parantez `[...]` içindedir.** Bu metin bir
> taslaktır; özellikle ruh sağlığıyla ilişkili bir uygulama olduğu için
> yayınlamadan önce bir hukuk danışmanına gözden geçirtmen önerilir.

Bu Gizlilik Politikası, **Astra** ("Uygulama", "biz") uygulamasını kullandığında
hangi kişisel verileri işlediğimizi, nasıl kullandığımızı ve haklarını açıklar.
Astra; günlük tutma, ruh hâli takibi, rüya yorumlama ve "Luma" adlı yapay zekâ
asistanıyla sohbet gibi kişisel gelişim ve iyi oluş özellikleri sunar.

**Veri sorumlusu:** [Geliştirici / şirket yasal adı]
**İletişim:** [gizlilik@senindomainin.com — geçerli bir iletişim e-postası]
**Adres:** [varsa açık adres / ülke — ör. Türkiye]

---

## 1. Topladığımız veriler

Yalnızca Uygulama'nın çalışması için gereken veriyi işleriz.

**a) Hesap bilgileri**
- E-posta adresi ve şifre (şifre, kimlik sağlayıcımız tarafından şifrelenmiş/karma
  olarak saklanır; biz düz metin şifreni görmeyiz).
- Google ile giriş yaparsan, Google hesabından temel kimlik bilgisi (e-posta, ad).
- İsteğe bağlı olarak sağladığın ad/takma ad.

**b) Senin oluşturduğun içerik**
- Günlük kayıtları (başlık ve metin).
- Sesli günlük kayıtları (ses dosyaları).
- Günlüklere eklediğin fotoğraflar.
- Ruh hâli seçimlerin.
- Rüya kayıtların ve Luma ile yaptığın sohbet mesajları.

Bu içerik **hassas nitelikte** olabilir. Yalnızca sana hizmet sunmak için işlenir;
reklam veya profilleme için kullanılmaz, satılmaz.

**c) Teknik veriler**
- Oturum/kimlik doğrulama jetonları (giriş yapılı kalman için).
- Uygulama tercihlerin (tema, hatırlatıcı ayarları gibi).

**Toplamadığımız veriler:** Konum verisi toplamıyoruz. Üçüncü taraf reklam veya
analitik/izleme araçları (Google Analytics, Facebook SDK vb.) kullanmıyoruz.
Kişisel verini üçüncü taraflara satmıyoruz.

---

## 2. Verileri nasıl kullanıyoruz

- Günlüklerini kaydetmek ve cihazların arasında senkronize etmek.
- Yapay zekâ destekli yansımalar üretmek (aşağıya bakınız).
- Hatırlatıcı bildirimleri göndermek (etkinleştirdiysen).
- Hesabını yönetmek ve güvenliğini sağlamak.

Verini yalnızca yukarıdaki amaçlarla, sözleşmenin ifası ve senin açık kullanımın
(rızan) temelinde işleriz.

---

## 3. Yapay zekâ (AI) işleme — önemli

Bazı özellikler (günlük ton geri bildirimi, rüya yorumu, Luma sohbeti, günün
sorusu) için ilgili metin içeriğin, yanıt üretebilmek amacıyla güvenli bir
sunucu üzerinden **Google'ın Gemini API'sine** gönderilir.

- Gönderilen içerik: analiz ettiğin günlük/rüya metni, ruh hâli bağlamı veya
  Luma'ya yazdığın mesaj.
- Bu işleme yalnızca sana anlık bir yanıt döndürmek için yapılır; yanıtlar
  Uygulama tarafından kalıcı olarak saklanmaz.
- Google'ın bu verileri işleme koşulları Google'ın kendi şartlarına tabidir.
  [Kullandığın Gemini API katmanının veri kullanım/eğitim koşullarını doğrula ve
  gerekiyorsa buraya Google'ın ilgili gizlilik/şartlar bağlantısını ekle:
  https://ai.google.dev/gemini-api/terms ]

AI yanıtları bilgilendirme amaçlıdır; tıbbi, psikolojik veya profesyonel tavsiye
niteliği taşımaz (bkz. Bölüm 9).

---

## 4. Verilerin nerede saklandığı ve üçüncü taraflar

Astra aşağıdaki hizmet sağlayıcıları (veri işleyenleri) kullanır:

| Sağlayıcı | Amaç | İşlenen veri |
|---|---|---|
| **Supabase** | Kimlik doğrulama, veritabanı, dosya depolama | Hesap, günlük içeriği, ses/fotoğraf |
| **Google** | Gemini AI (yansımalar) ve "Google ile giriş" | AI'ya gönderilen metin; giriş kimliği |

- Veriler aktarım sırasında **HTTPS/TLS ile şifrelenir**.
- Sunucular yurt dışında (ör. Supabase'in barındırma bölgeleri) bulunabilir;
  bu, verinin uluslararası aktarımı anlamına gelebilir. [Barındırma bölgeni
  Supabase panelinden teyit edip gerekirse buraya yaz.]
- Günlüklerin ayrıca **cihazında yerel olarak** da saklanır (çevrimdışı erişim
  için).

---

## 5. Veri saklama ve silme

- Verilerini, hesabın aktif olduğu sürece saklarız.
- **Hesabını uygulama içinden silebilirsin** (Profil → Hesabımı sil). Hesap
  silindiğinde; hesabın, günlüklerin, ses/fotoğraf dosyaların ve ilgili
  verilerin kalıcı olarak silinir. Cihazındaki yerel kopyalar da temizlenir.
- Silme talebini [gizlilik@senindomainin.com] adresine e-posta ile de
  iletebilirsin.

---

## 6. Güvenlik

Verini korumak için makul teknik ve idari önlemler uygularız: aktarımda şifreleme,
kimlik doğrulama jetonlarının cihazda güvenli depolanması ve erişimin yalnızca
hesap sahibiyle sınırlandırılması. Hiçbir sistem %100 güvenli olmasa da verini
korumaya özen gösteririz.

---

## 7. Senin hakların

Bulunduğun yere göre (ör. Türkiye — **KVKK**; Avrupa Birliği — **GDPR**) şu
haklara sahip olabilirsin:
- Verine erişme ve bir kopyasını isteme,
- Düzeltilmesini veya silinmesini isteme,
- İşlemeye itiraz etme veya rızanı geri çekme,
- Verini taşınabilir bir formatta alma.

Bu hakları kullanmak için [gizlilik@senindomainin.com] ile iletişime geç.

---

## 8. Çocukların gizliliği

Astra 13 yaşın (veya bulunduğun ülkedeki geçerli asgari yaşın) altındaki
çocuklara yönelik değildir ve bilerek onlardan veri toplamayız. Bir çocuğun bize
veri sağladığını düşünüyorsan lütfen bizimle iletişime geç.

---

## 9. Sağlık ve kriz desteği hakkında uyarı

Astra bir **iyi oluş ve günlük tutma** uygulamasıdır; tıbbi cihaz veya sağlık
hizmeti **değildir**. Uygulamadaki içerik ve AI yanıtları teşhis, tedavi veya
profesyonel psikolojik/tıbbi tavsiye yerine geçmez. Kriz destek özelliği, acil
durum hizmetlerinin yerini tutmaz. Acil bir durumdaysan lütfen yerel acil
servisleri veya bir uzmanı ara.

---

## 10. Bu politikadaki değişiklikler

Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişikliklerde Uygulama
içinden veya bu sayfada bildiririz. "Son güncelleme" tarihi en güncel sürümü
gösterir.

---

## 11. İletişim

Gizlilikle ilgili soruların için:
**[Geliştirici / şirket adı]** — **[gizlilik@senindomainin.com]**
