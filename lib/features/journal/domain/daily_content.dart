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
