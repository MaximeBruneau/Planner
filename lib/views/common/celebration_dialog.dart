import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_user.dart';
import '../../models/partner_info.dart';

class CelebrationDialog extends StatefulWidget {
  final AppUser? currentUser;
  final PartnerInfo partner;
  final VoidCallback? onExplore;

  const CelebrationDialog({
    super.key,
    required this.currentUser,
    required this.partner,
    this.onExplore,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUser? currentUser,
    required PartnerInfo partner,
    VoidCallback? onExplore,
  }) async {
    // 1. Initial warm haptic rumble
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    HapticFeedback.heavyImpact();

    if (!context.mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF1E1018).withValues(alpha: 0.78),
      builder: (ctx) => CelebrationDialog(
        currentUser: currentUser,
        partner: partner,
        onExplore: onExplore,
      ),
    );
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _avatarSlideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _badgeScaleAnimation;
  late Animation<double> _textFadeSlideAnimation;

  final List<_WarmParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 1. Main entrance controller (1.4s)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Continuous breathing / warm heartbeat loop
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 3. Particle explosion controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _initAnimations();
    _generateParticles();

    _mainController.forward();
    _particleController.forward();
  }

  void _initAnimations() {
    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    // Avatars start wide and draw together with magnetic attraction
    _avatarSlideAnimation = Tween<double>(begin: 38.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.65, curve: Curves.elasticOut),
      ),
    );

    // Glowing explosion halo
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Center badge popping in at magnetic collision
    _badgeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.75, curve: Curves.bounceOut),
      ),
    );

    // Staggered text entrance
    _textFadeSlideAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );
  }

  void _generateParticles() {
    final colors = [
      const Color(0xFFFF4D6D), // Vibrant Rose
      const Color(0xFFFF758F), // Soft Coral
      const Color(0xFFFFB703), // Golden Amber
      const Color(0xFFFB8500), // Warm Orange
      const Color(0xFFFFD166), // Star Gold
      const Color(0xFFFF85A1), // Warm Peach
    ];

    for (int i = 0; i < 36; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 70.0 + _random.nextDouble() * 120.0;
      final size = 4.0 + _random.nextDouble() * 7.0;
      final color = colors[_random.nextInt(colors.length)];
      final rotation = _random.nextDouble() * 2 * pi;

      _particles.add(
        _WarmParticle(
          angle: angle,
          speed: speed,
          size: size,
          color: color,
          rotation: rotation,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = widget.partner.displayName.isNotEmpty
        ? widget.partner.displayName.split(' ')[0]
        : 'Partner';

    final currentUserName = widget.currentUser?.displayName.isNotEmpty == true
        ? widget.currentUser!.displayName.split(' ')[0]
        : 'You';

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController, _particleController]),
      builder: (context, child) {
        final pulse = _pulseController.value;
        final glowScale = 0.95 + (_glowAnimation.value * 0.15) + (pulse * 0.08);

        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF9FA),
                      Color(0xFFFFF0F3),
                      Color(0xFFFFF5EB),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF597B).withValues(alpha: 0.25),
                      blurRadius: 35,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFFF85A1).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Floating Sparks & Hearts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSparkle("✨", 0.8 + (pulse * 0.3)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF597B), Color(0xFFFF9248)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF597B).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("🔥", style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                "DUO SYNCHRONIZED",
                                style: GoogleFonts.fredoka(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSparkle("✨", 1.1 - (pulse * 0.3)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Center Stage: Warm Radiant Glow + Orbiting Avatars + Particle Burst
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Warm Radiant Backdrop Halo
                          Transform.scale(
                            scale: glowScale,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFF758F).withValues(alpha: 0.35 * _glowAnimation.value),
                                    const Color(0xFFFFD166).withValues(alpha: 0.25 * _glowAnimation.value),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // 2. Custom Particle Burst Canvas
                          CustomPaint(
                            size: const Size(260, 120),
                            painter: _ParticleBurstPainter(
                              particles: _particles,
                              progress: _particleController.value,
                            ),
                          ),

                          // 3. User Avatar (Slides in from Left)
                          Transform.translate(
                            offset: Offset(-_avatarSlideAnimation.value, 0),
                            child: _buildAvatar(
                              name: currentUserName,
                              photoUrl: widget.currentUser?.photoUrl,
                              fallbackInitial: currentUserName.isNotEmpty
                                  ? currentUserName[0].toUpperCase()
                                  : 'U',
                              borderColor: const Color(0xFFE85D75),
                              accentColor: const Color(0xFFFDE8EC),
                              isLeft: true,
                            ),
                          ),

                          // 4. Partner Avatar (Slides in from Right)
                          Transform.translate(
                            offset: Offset(_avatarSlideAnimation.value, 0),
                            child: _buildAvatar(
                              name: partnerName,
                              photoUrl: widget.partner.photoUrl,
                              fallbackInitial: "🐰",
                              borderColor: const Color(0xFFF97316),
                              accentColor: const Color(0xFFFFEDD5),
                              isLeft: false,
                            ),
                          ),

                          // 5. Center Beating Heart / Flame Fusion Badge
                          ScaleTransition(
                            scale: _badgeScaleAnimation,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF3366), Color(0xFFFF9900)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF3366).withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: 0.9 + (pulse * 0.2),
                                  child: const Text(
                                    "💖",
                                    style: TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Avatar Names Underneath
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentUserName,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1521),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "&",
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE85D75),
                            ),
                          ),
                        ),
                        Text(
                          partnerName,
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A1521),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Warm Title with Staggered Entrance
                    Transform.translate(
                      offset: Offset(0, (1 - _textFadeSlideAnimation.value) * 12),
                      child: Opacity(
                        opacity: _textFadeSlideAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              "Connection Successful! 🌸🔥",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fredoka(
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2C181A),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Warm Descriptive Story
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                "Your days and vibes are now connected. Share your mood in real-time, build your daily duo flames, and stay in sync!",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: const Color(0xFF5C333B).withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main Action CTA Button with Warm Shimmer
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE85D75),
                              Color(0xFFF97316),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE85D75).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                            widget.onExplore?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Explore $partnerName's Vibe",
                                style: GoogleFonts.fredoka(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkle(String emoji, double scale) {
    return Transform.scale(
      scale: scale,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAvatar({
    required String name,
    required String? photoUrl,
    required String fallbackInitial,
    required Color borderColor,
    required Color accentColor,
    required bool isLeft,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: isLeft ? 0 : 54,
        right: isLeft ? 54 : 0,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isLeft
              ? [const Color(0xFFE85D75), const Color(0xFFFF9248)]
              : [const Color(0xFFFF9248), const Color(0xFFE85D75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: accentColor,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(
                fallbackInitial,
                style: TextStyle(
                  fontSize: fallbackInitial == "🐰" ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              )
            : null,
      ),
    );
  }
}

class _WarmParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotation;

  _WarmParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
  });
}

class _ParticleBurstPainter extends CustomPainter {
  final List<_WarmParticle> particles;
  final double progress;

  _ParticleBurstPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final distance = particle.speed * Curves.easeOutCubic.transform(progress);
      final dx = center.dx + cos(particle.angle) * distance;
      final dy = center.dy + sin(particle.angle) * distance;

      // Opacity fades out towards the end
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = particle.color.withValues(alpha: alpha);

      // Draw particle as a glowing soft dot / star spark
      canvas.drawCircle(Offset(dx, dy), particle.size * (1.0 - (progress * 0.4)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
