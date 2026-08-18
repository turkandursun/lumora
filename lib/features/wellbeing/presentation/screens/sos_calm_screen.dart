import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';

/// "Calm now" — a quick-access SOS flow for a moment of anxiety or panic:
/// a slow box-breathing pacer, then the 5-4-3-2-1 grounding exercise, then a
/// short reassurance. No inputs, no pressure — just something steady to hold on
/// to. A self-soothing aid, not a substitute for professional help; the app's
/// crisis support stays one tap away elsewhere.
class SosCalmScreen extends ConsumerStatefulWidget {
  const SosCalmScreen({super.key});

  @override
  ConsumerState<SosCalmScreen> createState() => _SosCalmScreenState();
}

enum _Stage { breathe, ground, done }

class _SosCalmScreenState extends ConsumerState<SosCalmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _box;
  _Stage _stage = _Stage.breathe;
  int _groundIndex = 0;

  @override
  void initState() {
    super.initState();
    // 16s box-breathing cycle: inhale · hold · exhale · hold, 4s each.
    _box =
        AnimationController(vsync: this, duration: const Duration(seconds: 16))
          ..repeat();
  }

  @override
  void dispose() {
    _box.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.close_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(isTr ? 'Sakinleş' : 'Calm now',
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (_stage) {
                    _Stage.breathe => _buildBreathe(isTr, isDark, primary),
                    _Stage.ground => _buildGround(isTr, isDark, primary),
                    _Stage.done => _buildDone(isTr, isDark, primary),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathe(bool isTr, bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isTr ? 'Benimle yavaşça nefes al.' : 'Breathe slowly with me.',
          style: AstraKit.body(context, isDark,
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 34),
        AnimatedBuilder(
          animation: _box,
          builder: (context, _) {
            final v = _box.value;
            double scale;
            String label;
            if (v < 0.25) {
              scale = 0.6 + (v / 0.25) * 0.4;
              label = isTr ? 'Nefes al' : 'Breathe in';
            } else if (v < 0.5) {
              scale = 1.0;
              label = isTr ? 'Tut' : 'Hold';
            } else if (v < 0.75) {
              scale = 1.0 - ((v - 0.5) / 0.25) * 0.4;
              label = isTr ? 'Ver' : 'Breathe out';
            } else {
              scale = 0.6;
              label = isTr ? 'Tut' : 'Hold';
            }
            final size = 150 * scale + 40;
            return SizedBox(
              width: 230,
              height: 230,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? Colors.white : primary)
                            .withValues(alpha: 0.9),
                        primary.withValues(alpha: 0.4),
                        primary.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Text(
                    label,
                    style: AstraKit.body(context, isDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0F00)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 34),
        Text(
          isTr ? 'Hazır olduğunda devam et.' : 'Continue when you feel ready.',
          textAlign: TextAlign.center,
          style: AstraKit.body(context, isDark,
              fontSize: 14.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        AstraGoldButton(
          isDark: isDark,
          label: isTr ? 'Devam et' : 'Continue',
          expand: false,
          onTap: () => setState(() => _stage = _Stage.ground),
        ),
      ],
    );
  }

  static const _groundTr = [
    ('5', 'Etrafında görebildiğin 5 şeyi fark et.'),
    ('4', 'Duyabildiğin 4 sesi dinle.'),
    ('3', 'Dokunabildiğin 3 şeyi hisset.'),
    ('2', 'Alabildiğin 2 kokuyu fark et.'),
    ('1', 'Tadabildiğin 1 şeyi düşün.'),
  ];
  static const _groundEn = [
    ('5', 'Notice 5 things you can see.'),
    ('4', 'Listen for 4 things you can hear.'),
    ('3', 'Feel 3 things you can touch.'),
    ('2', 'Notice 2 things you can smell.'),
    ('1', 'Think of 1 thing you can taste.'),
  ];

  Widget _buildGround(bool isTr, bool isDark, Color primary) {
    final steps = isTr ? _groundTr : _groundEn;
    final step = steps[_groundIndex];
    final isLast = _groundIndex == steps.length - 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isTr ? 'Şimdiye geri dön' : 'Come back to now',
          style: AstraKit.body(context, isDark,
              fontSize: 15, fontWeight: FontWeight.w700, color: primary),
        ),
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.22),
            border: Border.all(color: primary.withValues(alpha: 0.6), width: 2),
          ),
          child: Text(step.$1,
              style: AstraKit.heading1(context, isDark, fontSize: 52)),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            step.$2,
            textAlign: TextAlign.center,
            style: AstraKit.body(context, isDark,
                fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 34),
        AstraGoldButton(
          isDark: isDark,
          label: isLast
              ? (isTr ? 'Bitir' : 'Finish')
              : (isTr ? 'Sonraki' : 'Next'),
          expand: false,
          onTap: () {
            if (isLast) {
              setState(() => _stage = _Stage.done);
            } else {
              setState(() => _groundIndex++);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDone(bool isTr, bool isDark, Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_rounded, color: primary, size: 56),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            isTr
                ? 'Buradasın ve güvendesin. Bu dalga da geçecek. Kendinle gurur duy.'
                : 'You are here and you are safe. This wave will pass too. Be proud of yourself.',
            textAlign: TextAlign.center,
            style: AstraKit.body(context, isDark,
                fontSize: 16, fontWeight: FontWeight.w600, height: 1.45),
          ),
        ),
        const SizedBox(height: 30),
        AstraGoldButton(
          isDark: isDark,
          label: isTr ? 'Tamam' : 'Done',
          icon: Icons.check_rounded,
          expand: false,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => setState(() {
            _groundIndex = 0;
            _stage = _Stage.breathe;
          }),
          child: Text(isTr ? 'Tekrar başla' : 'Start again',
              style: AstraKit.mutedText(context, isDark,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
