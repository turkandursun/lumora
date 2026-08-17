import 'package:flutter/material.dart';

import '../../../../theme/luma_avatar.dart';

/// EKRAN 6 — Nihai hoş geldin / başlangıç ekranı.
///
/// Hafif koyulaştırılmış arka plan üzerinde ortalanmış beyaz bir kart (modal);
/// kartın tam üstüne yarı gömülü robot avatar; başlık, metin ve mavi-yeşil
/// degrade "YAZMAYA BAŞLA" butonu. Tek dosyada, kendi kendine çalışır.
///
/// Kullanım:
/// ```dart
/// OnboardingCompleteScreen(
///   userName: 'Türkan',
///   onStart: () { /* ana sayfaya / günlük yazmaya geç */ },
/// )
/// ```
class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({
    super.key,
    required this.onStart,
    this.userName,
  });

  /// "YAZMAYA BAŞLA"ya basınca çağrılır.
  final VoidCallback onStart;

  /// İsteğe bağlı: başlıkta kullanmak için kullanıcı adı.
  final String? userName;

  static const _navy = Color(0xFF243044);
  static const _bodyGrey = Color(0xFF8A94A6);
  static const _buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF35B0C4), Color(0xFF5B8DEF)],
  );

  @override
  Widget build(BuildContext context) {
    const avatar = 96.0;
    final title = userName == null || userName!.trim().isEmpty
        ? 'Harika, Her Şey Hazır!'
        : 'Harika, Her Şey Hazır ${userName!.trim()}!';

    return Scaffold(
      // Hafif koyulaştırılmış arka plan.
      backgroundColor: const Color(0xFFB9BEC6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Beyaz kart
              Container(
                margin: const EdgeInsets.only(top: avatar / 2),
                padding: EdgeInsets.fromLTRB(24, avatar / 2 + 20, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Günlük yolculuğuna başlamak için ilk adımı atmaya '
                      'tamamen hazırsın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _bodyGrey,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    // Mavi-yeşil degrade pill buton
                    _GradientPill(
                      label: 'YAZMAYA BAŞLA',
                      gradient: _buttonGradient,
                      onTap: onStart,
                    ),
                  ],
                ),
              ),
              // Karta yarı gömülü Luma yıldızı
              const Positioned(top: 0, child: LumaAvatar(size: avatar)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tam genişlik, degradeli oval (pill) buton.
class _GradientPill extends StatelessWidget {
  const _GradientPill({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4E9AD8).withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: onTap,
            child: Container(
              height: 58,
              alignment: Alignment.center,
              child: const Text(
                'YAZMAYA BAŞLA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
