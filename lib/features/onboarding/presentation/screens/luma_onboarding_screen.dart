import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../profile/data/profile_repository.dart';

/// A short, character-led welcome shown right after sign-up: Luma (a warm
/// glowing star) introduces itself, then asks what to call the user. The
/// nickname is saved to the profile so greetings feel personal.
class LumaOnboardingScreen extends StatefulWidget {
  const LumaOnboardingScreen({super.key});

  @override
  State<LumaOnboardingScreen> createState() => _LumaOnboardingScreenState();
}

class _LumaOnboardingScreenState extends State<LumaOnboardingScreen> {
  final _controller = PageController();
  final _nickController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _nickController.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final nick = _nickController.text.trim();
    if (nick.isNotEmpty) {
      try {
        await ProfileRepository().updateFullName(nick);
      } catch (_) {
        // Saving the nickname is best-effort; never block onboarding on it.
      }
    }
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9A7E8), Color(0xFF8E72C6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _page > 0
                      ? IconButton(
                          onPressed: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                          icon: Icon(Icons.arrow_back_rounded,
                              color: Colors.white.withValues(alpha: 0.8)),
                        )
                      : const SizedBox(),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _IntroPage(isTr: isTr, onNext: _next),
                    _NicknamePage(
                      isTr: isTr,
                      controller: _nickController,
                      onContinue: _finish,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: i == _page ? 0.95 : 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.isTr, required this.onNext});

  final bool isTr;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const _LumaCharacter(size: 96),
          const SizedBox(height: 30),
          Text(
            isTr ? 'Merhaba, ben Luma ✨' : "Hi, I'm Luma ✨",
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isTr
                ? 'Yeni kişisel öz-bakım yoldaşın'
                : 'Your new personal self-care companion',
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const Spacer(),
          _PillButton(
            label: isTr ? 'Merhaba Luma!' : 'Hi, Luma!',
            filled: true,
            onTap: onNext,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NicknamePage extends StatelessWidget {
  const _NicknamePage({
    required this.isTr,
    required this.controller,
    required this.onContinue,
  });

  final bool isTr;
  final TextEditingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const _LumaCharacter(size: 76),
          const SizedBox(height: 24),
          Text(
            isTr
                ? 'Tanıştığımıza sevindim! Sana nasıl hitap edelim?'
                : 'So nice to meet you! What should I call you?',
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onContinue(),
            style: AppTheme.bodyFont(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: isTr ? 'Takma adın...' : 'Your nickname...',
              hintStyle: AppTheme.bodyFont(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.55),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          _PillButton(
            label: isTr ? 'Devam' : 'Continue',
            filled: true,
            onTap: onContinue,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: filled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTheme.bodyFont(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF8E72C6),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Luma as a soft, twinkling star — our own friendly character.
class _LumaCharacter extends StatefulWidget {
  const _LumaCharacter({required this.size});

  final double size;

  @override
  State<_LumaCharacter> createState() => _LumaCharacterState();
}

class _LumaCharacterState extends State<_LumaCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.5,
      height: s * 1.5,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LumoraPalette.lightPurple
                          .withValues(alpha: 0.4 + 0.35 * t),
                      blurRadius: 30 + t * 16,
                      spreadRadius: 3 + t * 4,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.96 + 0.06 * t,
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [
                      LumoraPalette.warmCream,
                      LumoraPalette.lightPurple,
                    ],
                  ).createShader(rect),
                  child: Icon(Icons.star_rounded, size: s, color: Colors.white),
                ),
              ),
              // A couple of twinkling sparkles.
              for (final sp in const [
                (Alignment(-0.7, -0.6), 16.0, 0.0),
                (Alignment(0.72, -0.35), 12.0, 0.5),
                (Alignment(0.4, 0.7), 14.0, 0.8),
              ])
                Align(
                  alignment: sp.$1,
                  child: Opacity(
                    opacity: 0.3 +
                        0.7 * ((math.sin((t + sp.$3) * 2 * math.pi) + 1) / 2),
                    child: Icon(Icons.auto_awesome,
                        size: sp.$2, color: LumoraPalette.warmCream),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
