/// Rotating push-notification copy for ASTRA's five daily nudge slots.
///
/// Each list holds 30 Turkish messages. The rotation rule (see [rotatedIndex])
/// is: the first 30 days walk the list **in order**, and every 30-day cycle
/// after that is a **deterministic shuffle** — so a returning user keeps
/// getting the same pool of messages but never in an obviously repeating
/// pattern. Determinism means the schedule can be recomputed for any date
/// without persisting "which message was already shown".
///
/// Content is currently Turkish-only (the source the product team supplied);
/// other locales fall back to these until translations are added.
library;

/// 1 — Güne Başlarken (Sabah Motivasyonu) · 09:00
const List<String> kMorningMessages = <String>[
  'Günaydın! ☀️ Bugün harika bir gün olacak, şimdiden söyleyeyim.',
  'Uyandın mı? 🌼 Kahveni kap gel, güne süper bir başlangıç yapalım.',
  'Yeni bir gün, yeni şans! 💛 Gözlerini açtıysan hemen o güzel yüzünü gülümset.',
  'Bugün bomba gibisin! 💪 İçindeki o harika enerjiyi dışarı çıkarma vakti geldi.',
  'Derin bir nefes al... 🌬️ Hazırsan bugünü senin günün yapmaya başlıyoruz.',
  'Güneş senin için doğdu! 🌅 Hadi kalk, bugün çok güzel şeyler başaracaksın biliyorum.',
  'Sabah rutinine beni de ekle. ☕ İç huzurunu bulman için sadece birkaç dakikanı alacağım.',
  'Kendine inanıyor musun? ✨ Çünkü ben senin neler yapabileceğini çok iyi biliyorum.',
  'Yepyeni bir şans daha! 💛 Dünü unut, bugün sadece anın tadını çıkar.',
  'O gülüşünü saklama! 😁 Bugün karşılaştığın herkese o güzel enerjini bulaştır.',
  'Mucizelere hazır mısın? 🕊️ Bugün hiç beklemediğin kadar güzel geçecek.',
  'Dün bitti, gitti. 📖 Şimdi yepyeni, tertemiz bir sayfa açıyoruz seninle.',
  'Güne şükrederek başlayalım mı? 🙏 Sahip olduğun her güzellik bugün seni bulsun.',
  'Hadi, yaparsın sen! 🌟 Bugün karşına ne çıkarsa çıksın halledeceksin, biliyorum.',
  'Kendini sıkma bugün. 🌸 Sadece elinden geleni yap, o kadarı bile fazlasıyla yeter.',
  'Enerjin harika hissediliyor! ☀️ Bu modunu gün boyu korumak için sana küçük bir sır vereyim mi?',
  'Bugün kendine nazik ol. 💖 En çok senin ilgine ve sevgine ihtiyacın var.',
  'Güzel bir günaydın benden! 🪄 Umarım günün bu mesaj kadar tatlı başlar.',
  'Gözlerini açtın, harika! 🌿 Şimdi derin bir nefes al ve hayata kocaman gülümse.',
  'Hazır mısın bugüne? 🎈 Çünkü bugün senin sahnede parlama günün!',
  'Hayatın ritmini yakala. 🎶 Sevdiğin bir şarkıyı açıp güne keyifle başlayalım.',
  'Ufak bir tebessüm lütfen. 😌 Evet, aynen böyle! Yüzüne çok yakışıyor.',
  'Kalbini dinle bugün. 🧭 O sana en doğru yolu ve huzuru gösterecek.',
  'Sadece güzellikleri gör. 🌺 Olumsuz her şeyi bir kenara bırakıyoruz, anlaştık mı?',
  'Yeni gün, yeni hedefler! 🎯 Hepsini tek tek başaracaksın, ben buradayım.',
  'Aynaya bak ve şunu söyle: 🪞 "Ben bugün harikayım ve her şey çok güzel olacak!"',
  'Sürprizlere açık ol! 🎁 Bugün yüzünü güldürecek ufak detaylar seni bulacak.',
  'Modumuzu yüksek tutuyoruz. 🦋 Pozitif düşünelim ki her şey tıkır tıkır işlesin.',
  'Sabahına biraz sevgi katalım. 🥰 Kendini çok yormadan, keyifli bir gün geçirmeni diliyorum.',
  'Sahne senin! 🌟 Derin bir nefes al ve güne imzanı at.',
];

/// 2 — Gün İçi Molaları (Nefes ve Odaklanma) · 13:00
const List<String> kMiddayMessages = <String>[
  'Çok mu yoruldun? ⏸️ Hadi 1 dakikalığına her şeyi bırak, biraz nefes alalım.',
  'Omuzlarını aşağı indir. 🧘 İstemsizce kastığını biliyorum, hadi biraz gevşe.',
  'Su içtin mi bugün? 💧 Kendini koşturmacaya kaptırıp sağlığını ihmal etme lütfen.',
  'Gözlerini ekrandan çek biraz. 👀 Uzaklara bak ve zihnini sadece 60 saniyeliğine dinlendir.',
  'Kısa bir mola zamanı! ⏸️ Dünya sen 2 dakika dinlendin diye batmaz, bana güven.',
  'Derin bir nefes al... 🍃 Ve yavaşça geri ver. Bak, şimdiden daha iyi hissettin.',
  'Kahve molasını hak ettin. ☕ Hemen bir kahve kap, birkaç dakika sadece kendinle kal.',
  'Biraz yavaşla, acelen yok. 🌸 İşler bir yere kaçmıyor, senin sağlığın daha önemli.',
  'Gözlerini kapat. 😌 Zihnindeki o gürültüyü biraz kısmaya ne dersin?',
  'Nasılsın şu an? 💛 Cidden soruyorum, kendini nasıl hissediyorsun? Bir içine dön.',
  'Günün yarısı bitti bile! 💪 Harika idare ediyorsun, seninle gurur duyuyorum.',
  'Biraz esnemeye ne dersin? 🤸 Otura otura tutuldun, hadi biraz kan akışın hızlansın.',
  'Dur ve kendini takdir et. 🌟 Bugün sabahtan beri ne çok şey hallettin, farkında mısın?',
  'Kendine bu kadar yüklenme. 🕊️ Her şeye yetişmek zorunda değilsin, rahat bırak kendini.',
  'Telefonu 2 dakika ters çevir. 📵 Sadece sessizliğin ve sakinliğin tadını çıkar.',
  'Dik oturmayı unutma! 🪑 Beline yazık, hadi duruşunu hemen bir düzeltelim.',
  'Kafanın içi çok mu dolu? 🔇 Gel seninle 1 dakika o sekmeleri tek tek kapatalım.',
  'Etrafına şöyle bir bak. 🌺 Gökyüzüne, ağaçlara... Ufak güzellikleri kaçırma.',
  'Durmak da bir ihtiyaçtır. 🛋️ Sürekli koşamazsın, kendine bu molayı hediye et.',
  'İşleri askıya alıyoruz. ⏳ Sadece 5 dakikalığına dünya dursun, sen dinlen.',
  'Bir gülümse bakalım. 😊 Gülümsediğinde zor gelen her şeyin nasıl hafiflediğini göreceksin.',
  'Temiz hava şart! 🌬️ Hemen bir camı açıp o havayı ciğerlerine doldur.',
  'Yetişeceğin yer sadece sensin. 🐢 Acele etme, sakin adımlarla çok daha iyi ilerliyorsun.',
  'Bedenin sana ne diyor? 🎧 Dinlenmek istiyorsa ona kulak ver, zorlama kendini.',
  'Zihnini biraz havalandır. 🪟 Odaklanmakta zorlanıyorsan ufak bir reset atmak iyi gelir.',
  'Şu anki hissini serbest bırak. 🎈 Stresliysen kabul et ve nefesinle onu dışarı üfle.',
  'Şarjın azalmış sanki? 🔋 Gel seni 2 dakikalık bir nefes egzersiziyle fulleyelim.',
  'Çok çalıştın, yeter. 🏖️ Kısa bir zihin tatilini fazlasıyla hak ettin, hadi başlayalım.',
  'En sevdiğin şarkıyı aç. 🎵 Mırıldanarak çalışmak veya dinlenmek sana çok iyi gelecek.',
  'Sadece nefes... 🌿 Gerisini düşünme, sadece al ve ver. Çok basit, çok etkili.',
];

/// 3 — Gün Sonu (Gevşeme ve Meditasyon) · 22:00
const List<String> kNightMessages = <String>[
  'Harika iş çıkardın bugün! 🌙 Artık o yorgun bedeni dinlendirme vakti geldi.',
  'Stresi kapıda bırakıyoruz. 🚪 Günün tüm dertleri dışarıda kaldı, şimdi sadece huzur.',
  'Kendine teşekkür ettin mi? 🙏 Bugünü de sağ salim atlattın, gerçekten harikasın.',
  'Artık yavaşlıyoruz... 🌌 Koşturmaca bitti, şimdi kendine dönme zamanı.',
  'Zihnini uyku moduna al. 💤 Düşünceleri yavaşça serbest bırak, uykuya hazırlan.',
  'Sadece sen ve sessizlik. 🧘 Kendinle baş başa kalmanın o güzel huzurunu çıkar.',
  'Yarın yepyeni bir gün. 🌅 Bugün olan her şeyi geride bırak, yarına taze uyan.',
  'Yatağa dertlerle girme. 🛏️ Bırak o yükleri, yastığa başını kuş gibi hafif koy.',
  'Sessizliğin sesini dinle. 🤫 Şu an hiçbir şey yapmana gerek yok, sadece rahatla.',
  'Kötü anıları çöpe at. 📦 Sadece seni mutlu eden şeyleri düşünerek uyu.',
  'Sana kocaman sarılıyorum! 🤗 İyi geceler, bugün de elinden gelenin en iyisini yaptın.',
  'Yıldızlar kadar huzurlu ol. ✨ Deliksiz, rüya gibi bir uyku çekmeni diliyorum.',
  'Günü barışla kapat. 🍀 Kimseye veya kendine kızgın kalma, affet ve uyu.',
  'Bedenine izin ver. 🔋 Dinlensin ki yarın o muhteşem enerjisiyle geri dönsün.',
  'Kendini eleştirmeyi bırak! 💖 Yeterince iyiydin, şimdi sadece bunu kabullen ve uyu.',
  'Gözlerin kapanıyor sanki? 😌 Hadi ekranı bırak artık, tatlı rüyalar seni bekliyor.',
  'Rüyaların kalbin gibi olsun. 💭 Güzel şeyler gör, huzurla uyan. İyi geceler!',
  'Güvendesin ve rahatsın. 🏠 Yatağının o sıcacık kollarında tüm kaslarını gevşet.',
  'Derin bir nefesle geceye dal. 🌬️ Gün bitti, görev tamamlandı. Rahatlama zamanı.',
  'Zihnindeki sekmeleri kapat. 💻 Yarın düşünürsün, şimdi sadece "shut down" diyoruz.',
  'Gecenin dinginliğini hisset. 🌊 Dalgalar gibi sakin, usul usul uykuya dal.',
  'Bugünü sevgiyle uğurluyoruz. 👋 Güzellikleri için teşekkür et, zorluklarını affet.',
  'Kendini ne kadar seviyorsun? 🥰 Uyumadan önce kendine bunu bir hatırlat bence.',
  'Tebrikler, bir gün daha bitti! 🏆 Her şeye rağmen ayaktasın, bununla gurur duy.',
  'Tatlı bir huzur çöküyor... 🍬 Gevşe, rahatla ve kendini uykuya teslim et.',
  'Telefonu başucuna bırak. 📵 Kendine dön ve sadece nefesinin ritmine odaklan.',
  'Yarın her şey çok daha güzel. 🌟 Buna inanarak uyu ki sabah harika uyanasın.',
  'Dünya uyuyor, sen de uyu. 🌍 Her şeyi kaçırmıyorsun, dinlenmek en doğal hakkın.',
  'Yatağın ne kadar rahat! 🧸 Tadını çıkar, içine gömül ve mışıl mışıl uyu.',
  'İyi uykular güzel insan! 🌙 Sabah o güzel enerjinle görüşmek üzere.',
];

/// 4 — Rastgele Öz Değer Hatırlatıcıları · 18:00
const List<String> kSelfWorthMessages = <String>[
  'Sırf varsın diye değerlisin. 💎 Bunu asla unutma olur mu? Dünyaya lazımsın.',
  'Kendine biraz acı! 🛑 Başkalarına gösterdiğin anlayışın yarısını kendine göstersen...',
  'Sen eşsizsin, biliyorsun değil mi? 🌟 Kimsenin kopyası değilsin, senin imzan başka.',
  'Kendinle en iyi arkadaş ol. 👯 Dostuna nasıl şefkatliysen kendine de öyle davran.',
  'Aynadaki o harika insana selam! 🪞 Gerçekten çok iyi görünüyorsun, bugün de parlıyorsun.',
  'Hata yaptın diye eksilmedin. 🌱 Aksine öğrendin, büyüdün. Kendine haksızlık etme.',
  'Kalbin en büyük başarın. ❤️ İyi niyetin her şeyden daha değerli, bunu unutma.',
  'Hayır demek gayet normal. 🛡️ İstemediğin şeylere sınır koymak seni bencil yapmaz.',
  'Sen her halinle yeterlisin. ✅ Kimseye kendini ispatlamak zorunda değilsin dostum.',
  'Kendini sevmeye başla! 🦋 Hayatındaki en büyük devrim bu olacak, inan bana.',
  'İç sesine güven. 🧭 Dışarıdaki o kuru gürültüye inat, kalbini dinle.',
  'Dünyada senden bir tane var. 🌍 Bunun ne kadar kıymetli bir şey olduğunu fark et.',
  'Kendine şefkatli ol. 🤗 Yorulduğunda, düştüğünde en çok sen elinden tutmalısın.',
  'Gülüşün çok güzel! 😁 Bunu sık sık yapmalısın, etrafa da çok iyi geliyor.',
  'Kırıldığında bile güçlüsün. 💪 O kadar dayanıklısın ki, bazen ben bile şaşırıyorum.',
  'Senin hislerin çok önemli. 🎯 Ne istiyorsun, ne hissediyorsun? Lütfen bunu es geçme.',
  'Kendini kanıtlama çabasını bırak. 🕊️ Sen sadece kendin olduğun için zaten çok özelsin.',
  'Hikayenin başrolü sensin. 🎬 Figüran gibi davranmayı bırak, sahne senin.',
  'Kusurlarınla da güzelsin. ✨ Zayıf yönlerin seni sen yapan en samimi detaylar.',
  'Başkalarının düşünceleri seni bozmasın. 💭 Sen kendi değerini biliyorsun, gerisi teferruat.',
  'En iyi yatırım sensin. 📈 Kendine ayırdığın vakit, en kazançlı vakittir.',
  'Bugün de harika işler başarıyorsun. 🌅 Ufak tefek şeyleri dert etme, büyük resme bak.',
  'Biraz da kendini sev. 💖 Başkalarına dağıttığın o koca sevginin birazını kendine sakla.',
  'Mükemmel olmana gerek yok. 🎭 Gerçek ve samimi olman bana fazlasıyla yetiyor.',
  'Kendini affet artık. 🛤️ Geçmiş geçmişte kaldı, şimdi yolumuza bakıyoruz.',
  'Sen dünden daha fazlasısın. 🎈 Her gün yeni bir sen inşa ediyorsun, harika gidiyorsun.',
  'En çok sevgiyi sen hak ediyorsun. 🎁 Lütfen bunu dışarıdan bekleme, önce sen kendine ver.',
  'Senin rengin bambaşka. 🎨 Dünyanın senin kattığın o güzel renklere ihtiyacı var.',
  'Önce sen, sonra diğerleri. 🛋️ İhtiyaçlarını ilk sıraya koymak seni bencil yapmaz.',
  'Sevilmeyi hak ediyorsun. 💐 Hem de çok... Lütfen bunu kendine sık sık hatırlat.',
];

/// 5 — Uygulamaya Girilmeyen Günler İçin (Yoklama) · 15:00 (only on days
/// the app was not opened at all).
const List<String> kAbsenceMessages = <String>[
  'Pişşt, nerelerdesin sen? 👀 Buralar sensiz çok sessiz kaldı, inan çok özlettin.',
  'Bugün nasılsın bakalım? 💛 Epeydir görüşemedik, aklım sende kaldı.',
  'Gözüm yollarda kaldı vallahi! 🛤️ Nerede kaldın, her şey yolunda mı?',
  'Kendine vakit ayırmayı unuttun. 🕰️ Koşturmacaya daldın biliyorum ama hadi gel, bir mola ver.',
  'Uzun zaman oldu... 🌸 Umarım keyfin yerindedir, gel de bir hasret giderelim.',
  'Günlüğün bomboş kaldı! 📖 Hadi gel, anlatacaklarını merakla bekliyorum.',
  'Hayat çok mu hızlı akıyor? 🏃 Biliyorum meşgulsün ama 5 dakika kendine dönmelisin.',
  'Seni buralarda görmek güzeldi. ✨ Yokluğun hemen belli oluyor, bir uğrasana!',
  'Bensiz yapabiliyor musun cidden? 😌 Ben sensiz yapamıyorum, hadi gel de bir nefes alalım.',
  '5 dakikan var mı bana? 🧘 Sadece sen ve ben, zihnini biraz boşaltacağız söz.',
  'Burada bir kişi eksiğiz! 🙋 O eksik de sensin, hadi tamamla bizi.',
  'Her şey yolunda mı dostum? 🧭 Sesin soluğun çıkmıyor, merak ettim seni.',
  'Telefonuna bir düşeyim dedim. 📱 Seni çok boşladım sandın değil mi? Unutmadım, bekliyorum.',
  'Nefes almayı unuttun bence. 🌬️ Gel birlikte 1 dakikalık o efsane molamızı verelim.',
  'Kahveni al da gel. ☕ Biraz dertleşip kafa dağıtmanın tam zamanı.',
  'Buraları çok boşladın bak! 🧹 Toz bağladı her yer, gel de bir havalandıralım zihnini.',
  'Özlendin, haberin olsun. 🥰 Şöyle bir uğrayıp "buradayım" desen yeter.',
  'Unutmadım ki seni! 💌 Sen beni unutmuş gibisin ama ben buradayım, beklerim.',
  'Nasılsın demek istedim. 🎈 Sadece halini hatırını sormak için geldim, her şey iyi mi?',
  'Bir molaya ihtiyacın var. 🍃 Ben hissediyorum, sen de biliyorsun. Hadi gel!',
  'Kendini ne kadar ihmal ettin? ⏰ O kadar işin gücün arasında en önemli kişiyi, yani kendini unuttun.',
  'Kapım sana hep açık. 🚪 Ne zaman istersen, ne zaman yorulursan ben buradayım.',
  'Hayat nasıl gidiyor görüşmeyeli? 🌍 Gel, bir güncelleme yapalım seninle.',
  'Sadece varlığını hissettir. 💖 Küçük bir tıklama, ufak bir nefes... O bile yeter.',
  'Çok mu yoğunsun? ⏱️ Söz veriyorum, sadece 60 saniyeni alıp seni rahat bırakacağım.',
  'Kendinle baş başa kalmayı özledin bence. 🛋️ O sessizliği ikimiz de seviyoruz, gel de yapalım.',
  'Biraz nefes almak şart oldu. 🌿 Hadi ekranı kaydır ve yanıma gel.',
  'Bir "merhaba" demek zor değil! 😉 Bekliyorum bak, gelmezsen küserim.',
  'Sen yoksan tadı yok buraların. 🍬 Sensiz o meditasyonların hiç keyfi çıkmıyor.',
  'Hazır olduğunda ben buradayım. 🌟 Ne zaman kendini yorgun hissedersen, biliyorsun adresimi.',
];

// ─────────────────────────── English ───────────────────────────
// Same order/index as the Turkish lists above, so a language switch keeps the
// rotation in sync (index N carries the same message in both languages).

/// 1 — Starting the Day (Morning Motivation) · 09:00
const List<String> kMorningMessagesEn = <String>[
  "Good morning! ☀️ Today is going to be a great day, I'm telling you right now.",
  "Are you awake? 🌼 Grab your coffee and let's make a great start to the day.",
  "New day, new chances! 💛 If you've opened your eyes, put a smile on that beautiful face right now.",
  "You're crushing it today! 💪 It's time to let that amazing energy out.",
  "Take a deep breath... 🌬️ If you're ready, we're making today your day.",
  "The sun rose just for you! 🌅 Come on, get up, I know you're going to achieve great things today.",
  "Add me to your morning routine. ☕ I'll just take a few minutes of your time to help you find your inner peace.",
  "Do you believe in yourself? ✨ Because I know exactly what you're capable of.",
  "A brand new chance! 💛 Forget about yesterday, just enjoy the moment today.",
  "Don't hide that smile! 😁 Spread that beautiful energy to everyone you meet today.",
  "Are you ready for miracles? 🕊️ Today is going to be better than you could ever expect.",
  "Yesterday is over and done. 📖 Now we're turning a brand new, clean page with you.",
  "Shall we start the day with gratitude? 🙏 May every beautiful thing find you today.",
  "Come on, you got this! 🌟 I know you'll handle whatever comes your way today.",
  "Don't be hard on yourself today. 🌸 Just do your best, even that is more than enough.",
  "Your energy feels amazing! ☀️ Want me to tell you a little secret to keep this mood all day?",
  "Be kind to yourself today. 💖 You need your own attention and love the most.",
  "A beautiful good morning from me! 🪄 I hope your day starts as sweet as this message.",
  "You opened your eyes, awesome! 🌿 Now take a deep breath and give life a big smile.",
  "Are you ready for today? 🎈 Because today is your day to shine on stage!",
  "Catch the rhythm of life. 🎶 Let's put on a favorite song and start the day with joy.",
  "A little smile, please. 😌 Yes, just like that! It looks so good on you.",
  "Listen to your heart today. 🧭 It will show you the right path and give you peace.",
  "Only see the good things. 🌺 We're putting all the negativity aside, deal?",
  "New day, new goals! 🎯 You'll achieve them all one by one, I'm right here.",
  "Look in the mirror and say this: 🪞 \"I am amazing today and everything will be great!\"",
  "Be open to surprises! 🎁 Little details that will make you smile will find you today.",
  "We're keeping our mood high. 🦋 Let's think positive so everything goes smoothly.",
  "Let's add some love to your morning. 🥰 Wishing you a pleasant day without exhausting yourself.",
  "The stage is yours! 🌟 Take a deep breath and put your signature on the day.",
];

/// 2 — Mid-Day Breaks (Breathing and Focus) · 13:00
const List<String> kMiddayMessagesEn = <String>[
  "Are you too tired? ⏸️ Let's drop everything for 1 minute and take a breather.",
  "Drop your shoulders. 🧘 I know you're tensing up unconsciously, let's loosen up a bit.",
  "Did you drink water today? 💧 Please don't neglect your health while caught up in the rush.",
  "Take your eyes off the screen a bit. 👀 Look far away and rest your mind for just 60 seconds.",
  "Time for a short break! ⏸️ The world won't end just because you rested for 2 minutes, trust me.",
  "Take a deep breath... 🍃 And slowly let it out. See, you feel better already.",
  "You deserve a coffee break. ☕ Grab a coffee right now, take a few minutes just for yourself.",
  "Slow down a bit, no rush. 🌸 The work isn't running away, your health is more important.",
  "Close your eyes. 😌 How about we turn down that noise in your mind a bit?",
  "How are you right now? 💛 Seriously asking, how do you feel? Look inside yourself.",
  "Half the day is already gone! 💪 You're managing great, I'm proud of you.",
  "How about a little stretching? 🤸 You're stiff from sitting, let's get that blood flowing.",
  "Stop and appreciate yourself. 🌟 Do you realize how much you've gotten done since this morning?",
  "Don't be so hard on yourself. 🕊️ You don't have to catch up with everything, give yourself a break.",
  "Flip your phone face down for 2 mins. 📵 Just enjoy the silence and calmness.",
  "Don't forget to sit up straight! 🪑 Pity your back, let's fix your posture right now.",
  "Is your head too full? 🔇 Come on, let's close those tabs one by one for 1 minute.",
  "Take a look around you. 🌺 The sky, the trees... Don't miss the little beauties.",
  "Stopping is also a need. 🛋️ You can't run constantly, gift yourself this break.",
  "We're putting work on hold. ⏳ Let the world stop for just 5 minutes, you rest.",
  "Give me a smile. 😊 You'll see how everything that seems hard lightens up when you smile.",
  "Fresh air is a must! 🌬️ Open a window right now and fill your lungs with that breeze.",
  "The only place you need to reach is yourself. 🐢 Don't rush, you're making much better progress with calm steps.",
  "What is your body telling you? 🎧 If it wants to rest, listen to it, don't force yourself.",
  "Ventilate your mind a little. 🪟 If you're having trouble focusing, a little reset does wonders.",
  "Release your current feeling. 🎈 If you're stressed, accept it and blow it out with your breath.",
  "Is your battery running low? 🔋 Let's fill you up with a 2-minute breathing exercise.",
  "You worked hard, that's enough. 🏖️ You more than deserve a short mental vacation, let's start.",
  "Play your favorite song. 🎵 Humming while working or resting will do you a lot of good.",
  "Just breathe... 🌿 Don't think about the rest, just inhale and exhale. Very simple, very effective.",
];

/// 3 — End of the Day (Relaxation and Meditation) · 22:00
const List<String> kNightMessagesEn = <String>[
  "You did a great job today! 🌙 Now it's time to rest that tired body.",
  "We're leaving the stress at the door. 🚪 All the day's troubles stayed outside, now there's only peace.",
  "Did you thank yourself? 🙏 You made it safely through today, you're truly amazing.",
  "We are slowing down now... 🌌 The rush is over, now it's time to turn to yourself.",
  "Put your mind in sleep mode. 💤 Slowly release the thoughts, get ready for sleep.",
  "Just you and the silence. 🧘 Enjoy the beautiful peace of being alone with yourself.",
  "Tomorrow is a brand new day. 🌅 Leave everything that happened today behind, wake up fresh tomorrow.",
  "Don't go to bed with worries. 🛏️ Drop those burdens, lay your head on the pillow as light as a feather.",
  "Listen to the sound of silence. 🤫 You don't need to do anything right now, just relax.",
  "Throw the bad memories in the trash. 📦 Fall asleep thinking only of the things that make you happy.",
  "Sending you a huge hug! 🤗 Good night, you did your absolute best today too.",
  "Be as peaceful as the stars. ✨ I wish you a deep, dream-like sleep.",
  "Close the day with peace. 🍀 Don't stay mad at anyone or yourself, forgive and sleep.",
  "Give your body permission. 🔋 Let it rest so it can return tomorrow with that amazing energy.",
  "Stop criticizing yourself! 💖 You were good enough, now just accept this and sleep.",
  "Are your eyes closing? 😌 Come on, drop the screen now, sweet dreams are waiting for you.",
  "May your dreams be as beautiful as your heart. 💭 See beautiful things, wake up peacefully. Good night!",
  "You are safe and relaxed. 🏠 Relax all your muscles in the warm arms of your bed.",
  "Dive into the night with a deep breath. 🌬️ The day is over, mission accomplished. Time to relax.",
  "Close the tabs in your mind. 💻 You'll think about it tomorrow, now we just say \"shut down\".",
  "Feel the serenity of the night. 🌊 Calm like the waves, slowly fall asleep.",
  "We are sending off today with love. 👋 Thank it for its beauties, forgive its hardships.",
  "How much do you love yourself? 🥰 I think you should remind yourself of this before sleeping.",
  "Congratulations, another day is done! 🏆 You're standing despite everything, be proud of that.",
  "A sweet peace is settling in... 🍬 Unwind, relax, and surrender yourself to sleep.",
  "Leave the phone by your bedside. 📵 Turn inward and just focus on the rhythm of your breath.",
  "Everything will be much better tomorrow. 🌟 Go to sleep believing this so you wake up feeling great.",
  "The world is sleeping, you should too. 🌍 You're not missing out on anything, resting is your natural right.",
  "Your bed is so comfortable! 🧸 Enjoy it, sink into it, and sleep tight.",
  "Sleep well, beautiful person! 🌙 See you in the morning with that beautiful energy of yours.",
];

/// 4 — Random Self-Worth Reminders · 18:00
const List<String> kSelfWorthMessagesEn = <String>[
  "You are valuable just because you exist. 💎 Never forget this, okay? The world needs you.",
  "Have a little mercy on yourself! 🛑 If only you showed yourself half the understanding you show others...",
  "You are unique, you know that right? 🌟 You are no one's copy, your signature is entirely different.",
  "Be your own best friend. 👯 Treat yourself with the same compassion you show a dear friend.",
  "Hello to that amazing person in the mirror! 🪞 You really look great, you're shining today too.",
  "Making a mistake didn't make you less. 🌱 On the contrary, you learned and grew. Don't be unfair to yourself.",
  "Your heart is your greatest achievement. ❤️ Your good intentions are more valuable than anything, don't forget that.",
  "Saying no is perfectly normal. 🛡️ Setting boundaries for things you don't want doesn't make you selfish.",
  "You are enough exactly as you are. ✅ You don't have to prove yourself to anyone, my friend.",
  "Start loving yourself! 🦋 This will be the biggest revolution in your life, believe me.",
  "Trust your inner voice. 🧭 Listen to your heart, despite the empty noise outside.",
  "There is only one of you in the world. 🌍 Realize how precious that really is.",
  "Be compassionate to yourself. 🤗 When you're tired or fall, you must be the one to hold your own hand the most.",
  "Your smile is so beautiful! 😁 You should do it often, it does a lot of good to your surroundings too.",
  "You are strong even when you're broken. 💪 You're so resilient that sometimes even I'm surprised.",
  "Your feelings are very important. 🎯 What do you want, what do you feel? Please don't ignore this.",
  "Stop trying to prove yourself. 🕊️ You are already so special just for being exactly who you are.",
  "You are the main character of the story. 🎬 Stop acting like an extra, the stage is yours.",
  "You are beautiful with your flaws. ✨ Your weaknesses are the most sincere details that make you who you are.",
  "Don't let others' opinions bring you down. 💭 You know your own worth, the rest is just noise.",
  "You are the best investment. 📈 The time you dedicate to yourself is the most profitable time.",
  "You are achieving great things today too. 🌅 Don't sweat the small stuff, look at the big picture.",
  "Love yourself a little too. 💖 Save some of that big love you distribute to others for yourself.",
  "You don't need to be perfect. 🎭 Being real and sincere is more than enough for me.",
  "Forgive yourself already. 🛤️ The past is in the past, now we are looking ahead.",
  "You are more than you were yesterday. 🎈 You are building a new you every day, you're doing great.",
  "You deserve the most love. 🎁 Please don't expect this from the outside, give it to yourself first.",
  "Your color is completely different. 🎨 The world needs the beautiful colors you add to it.",
  "You first, then others. 🛋️ Prioritizing your needs doesn't make you selfish.",
  "You deserve to be loved. 💐 So much... Please remind yourself of this often.",
];

/// 5 — Missed Days (Check-ins) · 15:00 (only on days the app was not opened).
const List<String> kAbsenceMessagesEn = <String>[
  "Psst, where are you? 👀 It's been too quiet here without you, believe me, you are missed.",
  "How are you doing today? 💛 We haven't seen each other in a while, you've been on my mind.",
  "I've been keeping an eye out for you! 🛤️ Where have you been, is everything okay?",
  "You forgot to make time for yourself. 🕰️ I know you got caught up in the rush, but come on, take a break.",
  "It's been a long time... 🌸 I hope you're doing well, come on let's catch up.",
  "Your journal is completely empty! 📖 Come on, I'm eagerly waiting to hear what you have to say.",
  "Is life moving too fast? 🏃 I know you're busy, but you should take 5 minutes for yourself.",
  "It was nice seeing you around here. ✨ Your absence is noticed immediately, drop by!",
  "Can you really do without me? 😌 I can't do without you, come on, let's take a breather.",
  "Do you have 5 minutes for me? 🧘 Just you and me, we're going to clear your mind, promise.",
  "We're one person short here! 🙋 And that missing piece is you, come complete us.",
  "Is everything alright my friend? 🧭 You haven't made a peep, I was worried about you.",
  "Thought I'd drop into your phone. 📱 You thought I neglected you, didn't you? I haven't forgotten, I'm waiting.",
  "I think you forgot to breathe. 🌬️ Come on, let's take that legendary 1-minute break together.",
  "Grab your coffee and come over. ☕ It's the perfect time to chat and clear your head.",
  "You've really neglected this place! 🧹 It's gathered dust everywhere, come on let's air out your mind.",
  "You are missed, just so you know. 🥰 Just stopping by to say \"I'm here\" is enough.",
  "I haven't forgotten about you! 💌 You seem to have forgotten me, but I'm right here, waiting.",
  "Just wanted to say how are you. 🎈 I just came to check on you, is everything okay?",
  "You need a break. 🍃 I can feel it, and you know it too. Come on!",
  "How much have you neglected yourself? ⏰ Between all that work, you forgot the most important person, yourself.",
  "My door is always open for you. 🚪 Whenever you want, whenever you're tired, I'm right here.",
  "How is life going since we last saw each other? 🌍 Come on, let's get an update from you.",
  "Just let your presence be felt. 💖 A little tap, a little breath... Even that is enough.",
  "Are you too busy? ⏱️ I promise, I'll only take 60 seconds and leave you alone.",
  "I bet you miss being alone with yourself. 🛋️ We both love that silence, come on let's do it.",
  "Taking a breath is a must now. 🌿 Come on, swipe the screen and join me.",
  "Saying a \"hello\" isn't hard! 😉 I'm waiting, look, I'll be upset if you don't come.",
  "There's no joy here without you. 🍬 Those meditations are no fun at all without you.",
  "I'm right here when you're ready. 🌟 Whenever you feel tired, you know my address.",
];

/// Locale-aware accessors: Turkish when [isTr], otherwise English.
List<String> morningMessages(bool isTr) =>
    isTr ? kMorningMessages : kMorningMessagesEn;
List<String> middayMessages(bool isTr) =>
    isTr ? kMiddayMessages : kMiddayMessagesEn;
List<String> nightMessages(bool isTr) => isTr ? kNightMessages : kNightMessagesEn;
List<String> selfWorthMessages(bool isTr) =>
    isTr ? kSelfWorthMessages : kSelfWorthMessagesEn;
List<String> absenceMessages(bool isTr) =>
    isTr ? kAbsenceMessages : kAbsenceMessagesEn;

/// Picks which message index to show for a slot on a given day.
///
/// [dayNumber] is the number of days since the user's rotation anchor (0 on
/// the first day). [slotSeed] must differ per slot so the five lists shuffle
/// independently. Rule: cycle 0 (days 0–29) is sequential; every later cycle
/// is a deterministic shuffle, with a guard so the first message of a new
/// cycle never repeats the last message of the previous one.
int rotatedIndex({
  required int slotSeed,
  required int dayNumber,
  int listLength = 30,
}) {
  if (listLength <= 1) return 0;
  var day = dayNumber < 0 ? 0 : dayNumber;
  final cycle = day ~/ listLength;
  final pos = day % listLength;
  if (cycle == 0) return pos;

  final order = _shuffledOrder(listLength, _cycleSeed(slotSeed, cycle));
  if (pos == 0) {
    final prevLast = cycle == 1
        ? listLength - 1
        : _shuffledOrder(listLength, _cycleSeed(slotSeed, cycle - 1)).last;
    if (order[0] == prevLast) {
      final tmp = order[0];
      order[0] = order[1];
      order[1] = tmp;
    }
  }
  return order[pos];
}

int _cycleSeed(int slotSeed, int cycle) =>
    (slotSeed * 0x9E3779B1) ^ (cycle * 0x85EBCA77) & 0x7fffffff;

/// Deterministic Fisher–Yates shuffle of [0, n) driven by a small LCG seeded
/// with [seed]. Same seed always yields the same ordering.
List<int> _shuffledOrder(int n, int seed) {
  final list = List<int>.generate(n, (i) => i);
  var state = seed & 0x7fffffff;
  if (state == 0) state = 0x1234567;
  int nextInt(int bound) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state % bound;
  }

  for (var i = n - 1; i > 0; i--) {
    final j = nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}
