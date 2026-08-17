import 'package:flutter/material.dart';

import 'layered_modal_route.dart';
import 'liquid_color_transition.dart';
import 'living_avatar.dart';
import 'morph_page_route.dart';
import 'spring_physics.dart';

/// A single, dependency-free screen exercising all five motion systems
/// together. Wire a temporary route to this during development to sanity
/// check the whole kit before integrating individual effects into
/// production screens — nothing here touches any existing app file.
class MotionShowcaseScreen extends StatefulWidget {
  const MotionShowcaseScreen({super.key});

  @override
  State<MotionShowcaseScreen> createState() => _MotionShowcaseScreenState();
}

class _MotionShowcaseScreenState extends State<MotionShowcaseScreen> {
  late final LiquidColorController _liquid =
      LiquidColorController(initialColor: const Color(0xFFFCE8EE));
  final MorphCardHandle _cardHandle = MorphCardHandle();
  final GlobalKey<LivingAvatarState> _avatarKey = GlobalKey<LivingAvatarState>();

  int _mood = 2;

  static const _moodStops = [
    MoodStop(label: 'Kötü', icon: Icons.thunderstorm_rounded, color: Color(0xFF7EA8D8)),
    MoodStop(label: 'Düşük', icon: Icons.cloud_rounded, color: Color(0xFFB6A8D8)),
    MoodStop(label: 'Normal', icon: Icons.wb_cloudy_rounded, color: Color(0xFFEAAAC8)),
    MoodStop(label: 'İyi', icon: Icons.wb_sunny_rounded, color: Color(0xFFFFC469)),
    MoodStop(label: 'Harika', icon: Icons.auto_awesome_rounded, color: Color(0xFFFF9F5A)),
  ];

  static const _swatches = [
    Color(0xFFFCE8EE),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFE8F5E9),
  ];

  AvatarMood _moodFor(int index) {
    switch (index) {
      case 0:
        return AvatarMood.sad;
      case 1:
        return AvatarMood.anxious;
      case 2:
        return AvatarMood.calm;
      case 3:
        return AvatarMood.happy;
      default:
        return AvatarMood.happy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidColorBackground(
      controller: _liquid,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Motion Kit Showcase'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: LivingAvatar(key: _avatarKey, mood: _moodFor(_mood)),
              ),
              const SizedBox(height: 28),
              const Text('Effect 3 — Spring mood slider',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SpringMoodSlider(
                stops: _moodStops,
                value: _mood,
                onChanged: (v) {
                  setState(() => _mood = v);
                  _avatarKey.currentState?.react();
                },
              ),
              const SizedBox(height: 28),
              const Text('Effect 2 — Liquid color change',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  for (final c in _swatches)
                    GestureDetector(
                      onTapUp: (details) => _liquid.begin(c, details.globalPosition),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Effect 1 — Card-to-page morph',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MorphPageRoute(
                    handle: _cardHandle,
                    cardRadius: 24,
                    closedBuilder: (_) => const _DemoCard(),
                    openBuilder: (_) => const _DemoFullPage(),
                  ),
                ),
                child: MorphSource(
                  handle: _cardHandle,
                  borderRadius: 24,
                  child: const _DemoCard(),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Effect 4 — Layered modal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SpringBouncyButton(
                onTap: () => showLayeredModal(context, builder: (_) => const _DemoModal()),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCE7CA6),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Text(
                    'Open modal',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFF8DCE6),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: const Text('Tap to morph →', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DemoFullPage extends StatelessWidget {
  const _DemoFullPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8DCE6),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: const Center(child: Text('Morphed into a full page')),
    );
  }
}

class _DemoModal extends StatelessWidget {
  const _DemoModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      alignment: Alignment.center,
      child: const Text('Layered modal content'),
    );
  }
}
