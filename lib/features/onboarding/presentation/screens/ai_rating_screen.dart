import 'package:flutter/material.dart';

import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';

/// EKRAN 5 — "Yıldızlı AI Özelliği" değerlendirme ekranı.
///
/// ASTRA görsel diline uyumlu: seçili palet gradyanı arka plan, üstte Luma'nın
/// gülen yıldızı (tek mascot), okunur koyu yazı, 5 tıklanabilir sarı yıldız,
/// altta tam genişlik buton ve nokta göstergesi.
class AiRatingScreen extends StatefulWidget {
  const AiRatingScreen({
    super.key,
    this.onBack,
    required this.onSubmit,
  });

  /// Sol üstteki geri oku. null ise ok gizlenir.
  final VoidCallback? onBack;

  /// Butona basınca seçilen puanla (1–5) çağrılır.
  final ValueChanged<int> onSubmit;

  @override
  State<AiRatingScreen> createState() => _AiRatingScreenState();
}

class _AiRatingScreenState extends State<AiRatingScreen> {
  int _rating = 0;

  static const _starGold = Color(0xFFFFC53D);

  @override
  Widget build(BuildContext context) {
    final canSubmit = _rating > 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Üst bar: solda geri oku, ortada Yıldız.
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.onBack == null
                          ? const SizedBox(width: 24)
                          : IconButton(
                              onPressed: widget.onBack,
                              icon: Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20, color: AstraText.muted),
                            ),
                    ),
                    const LumaAvatar(size: 100),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'AI ile ilk deneyimini nasıl buldun?',
                  textAlign: TextAlign.center,
                  style: AstraKit.heading1(false, fontSize: 25)
                      .copyWith(height: 1.25),
                ),
                const SizedBox(height: 12),
                Text(
                  'GÖRÜŞLERİN KENDİMİZİ GELİŞTİRMEMİZE YARDIMCI OLUYOR',
                  textAlign: TextAlign.center,
                  style: AstraKit.mutedText(false, fontSize: 12).copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => setState(() => _rating = i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            i <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 48,
                            color: i <= _rating
                                ? _starGold
                                : AstraText.muted.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                AstraGoldButton(
                  isDark: false,
                  label: 'DEĞERLENDİR VE DEVAM ET',
                  enabled: canSubmit,
                  onTap: () => widget.onSubmit(_rating),
                ),
                const SizedBox(height: 22),
                _PageDots(count: 4, activeIndex: 3),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Alt sayfa göstergesi noktaları (koyu — pastel arka planda görünür).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == activeIndex ? 9 : 7,
            height: i == activeIndex ? 9 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AstraText.title
                  .withValues(alpha: i == activeIndex ? 0.8 : 0.28),
            ),
          ),
      ],
    );
  }
}
