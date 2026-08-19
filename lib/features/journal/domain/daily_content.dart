/// Curated daily content for the Home deck: correctly-attributed quotes from
/// well-known thinkers, writers and poets (leaning on public-domain / classical
/// figures so attributions are trustworthy), plus a rotating set of gentle
/// daily intentions. Both rotate by day of year via [dailyStartIndex], so the
/// content changes every day without a server round-trip or the misattribution
/// risk of generating quotes with AI.
library;

/// A famous quote with a reliable attribution.
class FamousQuote {
  const FamousQuote({required this.id, required this.tr, required this.en, required this.author});

  final String id;
  final String tr;
  final String en;
  final String author;

  String text(bool isTr) => isTr ? tr : en;
}

const List<FamousQuote> famousQuotes = [
  FamousQuote(id: 'fq_rumi_1', author: 'Mevlânâ', tr: 'Ne olursan ol yine gel.', en: 'Come, come, whoever you are.'),
  FamousQuote(id: 'fq_aurelius_1', author: 'Marcus Aurelius', tr: 'Hayatımız, düşüncelerimizin ona kattığıdır.', en: 'Our life is what our thoughts make it.'),
  FamousQuote(id: 'fq_laotzu_1', author: 'Lao Tzu', tr: 'Bin millik yolculuk tek bir adımla başlar.', en: 'The journey of a thousand miles begins with a single step.'),
  FamousQuote(id: 'fq_confucius_1', author: 'Konfüçyüs', tr: 'Yavaş gitmen önemli değil, yeter ki durma.', en: 'It does not matter how slowly you go, so long as you do not stop.'),
  FamousQuote(id: 'fq_aristotle_1', author: 'Aristoteles', tr: 'Kendini bilmek, tüm bilgeliğin başlangıcıdır.', en: 'Knowing yourself is the beginning of all wisdom.'),
  FamousQuote(id: 'fq_yunus_1', author: 'Yunus Emre', tr: 'Sevelim sevilelim, bu dünya kimseye kalmaz.', en: 'Let us love and be loved; this world remains to no one.'),
  FamousQuote(id: 'fq_emerson_1', author: 'Ralph Waldo Emerson', tr: 'İçimizdekiler, önümüzde ve arkamızda olanların yanında büyüktür.', en: 'What lies within us is greater than what lies behind or before us.'),
  FamousQuote(id: 'fq_thoreau_1', author: 'Henry David Thoreau', tr: 'Hayallerinin yönünde güvenle ilerle.', en: 'Go confidently in the direction of your dreams.'),
  FamousQuote(id: 'fq_goethe_1', author: 'Goethe', tr: 'Acele etmeden, ama durmadan.', en: 'Without haste, but without rest.'),
  FamousQuote(id: 'fq_rilke_1', author: 'Rainer Maria Rilke', tr: 'Kalbindeki çözülmemiş her şeye karşı sabırlı ol.', en: 'Be patient toward all that is unsolved in your heart.'),
  FamousQuote(id: 'fq_tagore_1', author: 'Rabindranath Tagore', tr: 'İnanç, şafak karanlıkken ışığı hisseden kuştur.', en: 'Faith is the bird that feels the light when the dawn is still dark.'),
  FamousQuote(id: 'fq_epictetus_1', author: 'Epiktetos', tr: 'Seni olaylar değil, olaylara bakışın üzer.', en: "It is not what happens to you, but how you react that matters."),
  FamousQuote(id: 'fq_buddha_1', author: 'Buda', tr: 'Geçmişe takılma, geleceği düşleme; zihnini şimdiye ver.', en: 'Do not dwell in the past or dream of the future; concentrate the mind on the present.'),
  FamousQuote(id: 'fq_nietzsche_1', author: 'Friedrich Nietzsche', tr: "Yaşamak için bir 'neden'i olan, hemen her 'nasıl'a katlanır.", en: 'He who has a why to live can bear almost any how.'),
  FamousQuote(id: 'fq_heraclitus_1', author: 'Herakleitos', tr: 'Değişmeyen tek şey, değişimin kendisidir.', en: 'The only constant in life is change.'),
  FamousQuote(id: 'fq_rumi_2', author: 'Mevlânâ', tr: 'Dün akıllıydım, dünyayı değiştirmek istedim; bugün bilgeyim, kendimi değiştiriyorum.', en: 'Yesterday I was clever, so I wanted to change the world; today I am wise, so I am changing myself.'),
  FamousQuote(id: 'fq_seneca_1', author: 'Seneca', tr: 'Her yeni başlangıç, başka bir sonun içinden doğar.', en: "Every new beginning comes from some other beginning's end."),
  FamousQuote(id: 'fq_cicero_1', author: 'Cicero', tr: 'Yaşadığın sürece nasıl yaşanacağını öğrenmeye devam et.', en: 'As long as you live, keep learning how to live.'),
  FamousQuote(id: 'fq_james_1', author: 'William James', tr: 'İnsan, tutumunu değiştirerek hayatını değiştirebilir.', en: 'You can change your life by changing your attitude.'),
  FamousQuote(id: 'fq_socrates_1', author: 'Sokrates', tr: 'Bilgelik, hayret etmekle başlar.', en: 'Wisdom begins in wonder.'),
  FamousQuote(id: 'fq_laotzu_2', author: 'Lao Tzu', tr: 'Başkalarını tanıyan bilgedir; kendini tanıyan aydınlanmıştır.', en: 'Knowing others is wisdom; knowing yourself is enlightenment.'),
  FamousQuote(id: 'fq_montaigne_1', author: 'Montaigne', tr: 'Hayatım korkunç talihsizliklerle doluydu, çoğu hiç başıma gelmedi.', en: 'My life has been full of terrible misfortunes, most of which never happened.'),
  FamousQuote(id: 'fq_aristotle_2', author: 'Aristoteles', tr: 'Mutluluk kendimize bağlıdır.', en: 'Happiness depends upon ourselves.'),
  FamousQuote(id: 'fq_gandhi_1', author: 'Mahatma Gandhi', tr: 'Dünyada görmek istediğin değişimin kendisi ol.', en: 'Be the change that you wish to see in the world.'),
  FamousQuote(id: 'fq_gandhi_2', author: 'Mahatma Gandhi', tr: 'Yarın ölecekmiş gibi yaşa, sonsuza dek yaşayacakmış gibi öğren.', en: 'Live as if you were to die tomorrow. Learn as if you were to live forever.'),
  FamousQuote(id: 'fq_einstein_1', author: 'Albert Einstein', tr: 'Hayatı yaşamanın iki yolu vardır: hiçbir şey mucize değilmiş gibi ya da her şey mucizeymiş gibi.', en: 'There are two ways to live: as though nothing is a miracle, or as though everything is a miracle.'),
  FamousQuote(id: 'fq_einstein_2', author: 'Albert Einstein', tr: 'Hayat bisiklet sürmek gibidir; dengeni korumak için hareket etmeye devam etmelisin.', en: 'Life is like riding a bicycle. To keep your balance, you must keep moving.'),
  FamousQuote(id: 'fq_mandela_1', author: 'Nelson Mandela', tr: 'En büyük zafer hiç düşmemek değil, her düştüğünde ayağa kalkmaktır.', en: 'The greatest glory in living lies not in never falling, but in rising every time we fall.'),
  FamousQuote(id: 'fq_mandela_2', author: 'Nelson Mandela', tr: 'Bir şey başarılana kadar hep imkânsız görünür.', en: 'It always seems impossible until it is done.'),
  FamousQuote(id: 'fq_mandela_3', author: 'Nelson Mandela', tr: 'Eğitim, dünyayı değiştirmek için kullanabileceğin en güçlü silahtır.', en: 'Education is the most powerful weapon which you can use to change the world.'),
  FamousQuote(id: 'fq_keller_1', author: 'Helen Keller', tr: 'Hayat ya cüretkâr bir maceradır ya da hiçbir şey.', en: 'Life is either a daring adventure or nothing at all.'),
  FamousQuote(id: 'fq_keller_2', author: 'Helen Keller', tr: 'Dünyanın en güzel şeyleri görülmez ya da dokunulmaz; kalple hissedilir.', en: 'The best and most beautiful things in the world cannot be seen or even touched — they must be felt with the heart.'),
  FamousQuote(id: 'fq_angelou_1', author: 'Maya Angelou', tr: 'İnsanlar ne dediğini unutur, ama onlara ne hissettirdiğini asla unutmaz.', en: 'People will forget what you said, but people will never forget how you made them feel.'),
  FamousQuote(id: 'fq_wilde_1', author: 'Oscar Wilde', tr: 'Kendin ol; diğer herkes zaten alınmış.', en: 'Be yourself; everyone else is already taken.'),
  FamousQuote(id: 'fq_confucius_2', author: 'Konfüçyüs', tr: 'Sevdiğin bir işi seç; ömür boyu bir gün bile çalışmak zorunda kalmazsın.', en: 'Choose a job you love, and you will never have to work a day in your life.'),
  FamousQuote(id: 'fq_confucius_3', author: 'Konfüçyüs', tr: 'Değerli taş sürtünme olmadan, insan da denenmeden parlamaz.', en: 'The gem cannot be polished without friction, nor a person perfected without trials.'),
  FamousQuote(id: 'fq_laotzu_3', author: 'Lao Tzu', tr: 'Başkalarına hükmeden güçlüdür; kendine hükmeden gerçekten kudretlidir.', en: 'Mastering others is strength; mastering yourself is true power.'),
  FamousQuote(id: 'fq_laotzu_4', author: 'Lao Tzu', tr: 'Sahip olduklarınla yetin; işlerin olduğu gibi olmasından hoşnut ol.', en: 'Be content with what you have; rejoice in the way things are.'),
  FamousQuote(id: 'fq_seneca_2', author: 'Seneca', tr: 'Cesaret edemediğimiz için zor değil, zor olduğunu sandığımız için cesaret edemiyoruz.', en: 'It is not because things are difficult that we do not dare; it is because we do not dare that things are difficult.'),
  FamousQuote(id: 'fq_seneca_3', author: 'Seneca', tr: 'Yoksul, az şeyi olan değil, daha fazlasını arzulayandır.', en: 'It is not the man who has too little, but the man who craves more, that is poor.'),
  FamousQuote(id: 'fq_aurelius_2', author: 'Marcus Aurelius', tr: 'Mutlu bir hayat için çok az şey gerekir; her şey senin içinde, düşünce biçimindedir.', en: 'Very little is needed to make a happy life; it is all within yourself, in your way of thinking.'),
  FamousQuote(id: 'fq_aurelius_3', author: 'Marcus Aurelius', tr: 'Zihnin üzerinde gücün var, dış olaylar üzerinde değil. Bunu fark et, güç bulacaksın.', en: 'You have power over your mind — not outside events. Realize this, and you will find strength.'),
  FamousQuote(id: 'fq_epictetus_2', author: 'Epiktetos', tr: 'Özgürlük, arzularımızı gerçekleştirerek değil, arzularımızın esaretinden kurtularak elde edilir.', en: 'Freedom is secured not by the fulfilling of one\'s desires, but by the removal of desire.'),
  FamousQuote(id: 'fq_frankl_1', author: 'Viktor Frankl', tr: 'Uyaran ile tepki arasında bir boşluk vardır; o boşlukta seçme gücümüz yatar.', en: 'Between stimulus and response there is a space. In that space is our power to choose our response.'),
  FamousQuote(id: 'fq_jung_1', author: 'Carl Jung', tr: 'Dışarı bakan düş görür; içeri bakan uyanır.', en: 'Who looks outside, dreams; who looks inside, awakes.'),
  FamousQuote(id: 'fq_nietzsche_2', author: 'Friedrich Nietzsche', tr: 'Dans eden bir yıldız doğurabilmek için insanın içinde hâlâ kaos olmalı.', en: 'One must still have chaos in oneself to be able to give birth to a dancing star.'),
  FamousQuote(id: 'fq_emerson_2', author: 'Ralph Waldo Emerson', tr: 'Olmaya karar verdiğin kişi, olman gereken tek kişidir.', en: 'The only person you are destined to become is the person you decide to be.'),
  FamousQuote(id: 'fq_emerson_3', author: 'Ralph Waldo Emerson', tr: 'Coşku olmadan hiçbir büyük şey başarılmamıştır.', en: 'Nothing great was ever achieved without enthusiasm.'),
  FamousQuote(id: 'fq_annefrank_1', author: 'Anne Frank', tr: 'Dünyayı düzeltmeye başlamak için bir an bile beklemene gerek olmaması ne güzel.', en: 'How wonderful it is that nobody need wait a single moment before starting to improve the world.'),
  FamousQuote(id: 'fq_annefrank_2', author: 'Anne Frank', tr: 'Her şeye rağmen, insanların kalben gerçekten iyi olduğuna hâlâ inanıyorum.', en: 'In spite of everything, I still believe that people are really good at heart.'),
  FamousQuote(id: 'fq_vangogh_1', author: 'Vincent van Gogh', tr: 'Büyük işler, bir araya getirilen küçük şeylerle yapılır.', en: 'Great things are done by a series of small things brought together.'),
  FamousQuote(id: 'fq_jobs_1', author: 'Steve Jobs', tr: 'Zamanın sınırlı; başkasının hayatını yaşayarak boşa harcama.', en: 'Your time is limited, so don\'t waste it living someone else\'s life.'),
  FamousQuote(id: 'fq_jobs_2', author: 'Steve Jobs', tr: 'Harika işler yapmanın tek yolu, yaptığın işi sevmektir.', en: 'The only way to do great work is to love what you do.'),
  FamousQuote(id: 'fq_disney_1', author: 'Walt Disney', tr: 'Hayal edebiliyorsan, yapabilirsin.', en: 'If you can dream it, you can do it.'),
  FamousQuote(id: 'fq_disney_2', author: 'Walt Disney', tr: 'Başlamanın yolu, konuşmayı bırakıp yapmaya başlamaktır.', en: 'The way to get started is to quit talking and begin doing.'),
  FamousQuote(id: 'fq_eleanor_1', author: 'Eleanor Roosevelt', tr: 'Gelecek, hayallerinin güzelliğine inananlarındır.', en: 'The future belongs to those who believe in the beauty of their dreams.'),
  FamousQuote(id: 'fq_eleanor_2', author: 'Eleanor Roosevelt', tr: 'Hiç kimse senin izin vermeden kendini değersiz hissettiremez.', en: 'No one can make you feel inferior without your consent.'),
  FamousQuote(id: 'fq_churchill_1', author: 'Winston Churchill', tr: 'Başarı kesin değildir, başarısızlık ölümcül değildir; önemli olan devam etme cesaretidir.', en: 'Success is not final, failure is not fatal: it is the courage to continue that counts.'),
  FamousQuote(id: 'fq_churchill_2', author: 'Winston Churchill', tr: 'Cehennemin içinden geçiyorsan, yürümeye devam et.', en: 'If you are going through hell, keep going.'),
  FamousQuote(id: 'fq_dalai_1', author: 'Dalai Lama', tr: 'Mutluluk hazır bir şey değildir; kendi eylemlerinden doğar.', en: 'Happiness is not something ready made. It comes from your own actions.'),
  FamousQuote(id: 'fq_dalai_2', author: 'Dalai Lama', tr: 'Bazen istediğini elde edememek, harika bir şans olabilir.', en: 'Remember that sometimes not getting what you want is a wonderful stroke of luck.'),
  FamousQuote(id: 'fq_thich_1', author: 'Thich Nhat Hanh', tr: 'Mutluluğa giden bir yol yoktur; mutluluk yolun kendisidir.', en: 'There is no way to happiness — happiness is the way.'),
  FamousQuote(id: 'fq_teresa_1', author: 'Rahibe Teresa', tr: 'Küçük şeyleri büyük bir sevgiyle yap.', en: 'Do small things with great love.'),
  FamousQuote(id: 'fq_buddha_2', author: 'Buda', tr: 'Zihin her şeydir. Ne düşünürsen o olursun.', en: 'The mind is everything. What you think you become.'),
  FamousQuote(id: 'fq_buddha_3', author: 'Buda', tr: 'Bir mumdan binlerce mum yakılabilir ve o mumun ömrü kısalmaz. Mutluluk paylaşıldıkça azalmaz.', en: 'Thousands of candles can be lit from a single candle, and the life of the candle will not be shortened. Happiness never decreases by being shared.'),
  FamousQuote(id: 'fq_plato_1', author: 'Platon', tr: 'İyi bir başlangıç, işin en önemli parçasıdır.', en: 'The beginning is the most important part of the work.'),
  FamousQuote(id: 'fq_shakespeare_1', author: 'William Shakespeare', tr: 'Her şeyin üstünde şu: kendine karşı dürüst ol.', en: 'This above all: to thine own self be true.'),
  FamousQuote(id: 'fq_hugo_1', author: 'Victor Hugo', tr: 'Geleceğin pek çok adı vardır: zayıflar için ulaşılmaz, korkaklar için bilinmez, cesurlar için fırsattır.', en: 'The future has many names: for the weak, it is the unattainable; for the fearful, the unknown; for the courageous, opportunity.'),
  FamousQuote(id: 'fq_davinci_1', author: 'Leonardo da Vinci', tr: 'Sadelik, inceliğin en üst hâlidir.', en: 'Simplicity is the ultimate sophistication.'),
  FamousQuote(id: 'fq_franklin_1', author: 'Benjamin Franklin', tr: 'Bugün yapabileceğini asla yarına bırakma.', en: 'Never leave that till tomorrow which you can do today.'),
  FamousQuote(id: 'fq_ford_1', author: 'Henry Ford', tr: 'İster yapabileceğine inan ister yapamayacağına — her iki durumda da haklısın.', en: 'Whether you think you can, or you think you can\'t — you\'re right.'),
  FamousQuote(id: 'fq_troosevelt_1', author: 'Theodore Roosevelt', tr: 'Olduğun yerde, elindekiyle, yapabileceğini yap.', en: 'Do what you can, with what you have, where you are.'),
  FamousQuote(id: 'fq_twain_1', author: 'Mark Twain', tr: 'Yirmi yıl sonra yaptıkların için değil, yapmadıkların için pişman olacaksın.', en: 'Twenty years from now you will be more disappointed by the things that you didn\'t do than by the ones you did do.'),
  FamousQuote(id: 'fq_rogers_1', author: 'Carl Rogers', tr: 'İşin tuhafı: kendimi olduğum gibi kabul ettiğimde değişebiliyorum.', en: 'The curious paradox is that when I accept myself just as I am, then I can change.'),
  FamousQuote(id: 'fq_rumi_3', author: 'Mevlânâ', tr: 'Yara, ışığın sana girdiği yerdir.', en: 'The wound is the place where the Light enters you.'),
  FamousQuote(id: 'fq_rumi_4', author: 'Mevlânâ', tr: 'Sen okyanustaki bir damla değilsin; bir damladaki koca okyanussun.', en: 'You are not a drop in the ocean. You are the entire ocean in a drop.'),
  FamousQuote(id: 'fq_rumi_5', author: 'Mevlânâ', tr: 'Dün dünde kaldı cancağızım; bugün yeni şeyler söylemek lazım.', en: 'Yesterday has passed away with all that was in it; today it is needful to say new things.'),
  FamousQuote(id: 'fq_gibran_1', author: 'Halil Cibran', tr: 'Sevincin, maskesi düşmüş kederindir.', en: 'Your joy is your sorrow unmasked.'),
  FamousQuote(id: 'fq_gibran_2', author: 'Halil Cibran', tr: 'Acın, anlayışını çevreleyen kabuğun kırılmasıdır.', en: 'Your pain is the breaking of the shell that encloses your understanding.'),
  FamousQuote(id: 'fq_aesop_1', author: 'Ezop', tr: 'Hiçbir nazik davranış, ne kadar küçük olursa olsun, boşa gitmez.', en: 'No act of kindness, no matter how small, is ever wasted.'),
  FamousQuote(id: 'fq_ovid_1', author: 'Ovidius', tr: 'Sabırlı ve güçlü ol; bir gün bu acı sana iyi gelecek.', en: 'Be patient and tough; someday this pain will be useful to you.'),
  FamousQuote(id: 'fq_nin_1', author: 'Anaïs Nin', tr: 'Ve gün geldi ki, tomurcuk hâlinde kalmanın riski, açmanın riskinden daha acı verici oldu.', en: 'And the day came when the risk to remain tight in a bud was more painful than the risk it took to blossom.'),
  FamousQuote(id: 'fq_lewis_1', author: 'C. S. Lewis', tr: 'Yeni bir hedef koymak ya da yeni bir hayal kurmak için asla çok yaşlı değilsin.', en: 'You are never too old to set another goal or to dream a new dream.'),
  FamousQuote(id: 'fq_tolkien_1', author: 'J. R. R. Tolkien', tr: 'Altın olan her şey parlamaz; başıboş gezen herkes kaybolmuş değildir.', en: 'All that is gold does not glitter; not all those who wander are lost.'),
  FamousQuote(id: 'fq_mlk_1', author: 'Martin Luther King Jr.', tr: 'Karanlık, karanlığı kovamaz; bunu yalnızca ışık yapabilir. Nefret nefreti kovamaz; bunu yalnızca sevgi yapar.', en: 'Darkness cannot drive out darkness; only light can do that. Hate cannot drive out hate; only love can do that.'),
  FamousQuote(id: 'fq_mlk_2', author: 'Martin Luther King Jr.', tr: 'Bütün merdiveni görmesen de ilk adımı at; işte inanç budur.', en: 'Faith is taking the first step even when you don\'t see the whole staircase.'),
  FamousQuote(id: 'fq_schweitzer_1', author: 'Albert Schweitzer', tr: 'Başarı mutluluğun anahtarı değildir; mutluluk başarının anahtarıdır. Yaptığın işi seversen başarılı olursun.', en: 'Success is not the key to happiness. Happiness is the key to success. If you love what you are doing, you will be successful.'),
  FamousQuote(id: 'fq_nazim_1', author: 'Nâzım Hikmet', tr: 'En güzel deniz henüz gidilmemiş olanıdır; en güzel günlerimiz henüz yaşamadıklarımızdır.', en: 'The most beautiful sea hasn\'t been crossed yet; the most beautiful of our days we haven\'t lived yet.'),
  FamousQuote(id: 'fq_nazim_2', author: 'Nâzım Hikmet', tr: 'Yaşamak bir ağaç gibi tek ve hür, bir orman gibi kardeşçesine.', en: 'To live like a tree, single and free, and brotherly like a forest.'),
  FamousQuote(id: 'fq_yunus_2', author: 'Yunus Emre', tr: 'Bir kez gönül yıktın ise, bu kıldığın namaz değil.', en: 'If you have broken a single heart, the prayer you offered is not prayer.'),
];

/// Which item today's rotation lands on — shared with the quote deck so a
/// user sees the same "of the day" content without a server.
int dailyRotationIndex(DateTime now, int length) {
  final dayOfYear = int.parse(
    '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
  );
  return dayOfYear % length;
}

/// Gentle, one-line daily intentions — the "set your intention" beat leading
/// wellbeing apps (Stoic, Balance, Fabulous) open the day with.
const List<(String tr, String en)> dailyIntentions = [
  ('Bugün kendime nazik davranacağım.', 'Today, I will be kind to myself.'),
  ('Bugün küçük bir şey için minnettar olacağım.', "Today, I'll be grateful for one small thing."),
  ('Bugün bir nefes molası vereceğim.', "Today, I'll pause for a breath."),
  ('Bugün olduğum anda bulunmaya çalışacağım.', "Today, I'll try to be where I am."),
  ('Bugün birine küçük bir iyilik yapacağım.', "Today, I'll do one small kindness."),
  ("Bugün 'yeterince iyi'nin yettiğini hatırlayacağım.", 'Today, I\'ll remember that good enough is enough.'),
  ('Bugün duygularıma yer açacağım.', "Today, I'll make space for my feelings."),
  ('Bugün küçük bir adım atacağım.', "Today, I'll take one small step."),
  ('Bugün gerektiğinde hayır demeyi deneyeceğim.', "Today, I'll practice saying no when I need to."),
  ('Bugün bedenimi dinleyeceğim.', "Today, I'll listen to my body."),
  ('Bugün mükemmel değil, gerçek olmaya çalışacağım.', "Today, I'll aim for real, not perfect."),
  ('Bugün geçmişi bırakıp şimdiye döneceğim.', "Today, I'll let go of the past and return to now."),
  ('Bugün kendime bir arkadaş gibi davranacağım.', "Today, I'll treat myself like a friend."),
  ('Bugün küçük sevinçleri fark edeceğim.', "Today, I'll notice small joys."),
  ('Bugün acele etmeden ilerleyeceğim.', "Today, I'll move without rushing."),
];
