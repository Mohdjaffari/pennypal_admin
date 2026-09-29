import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/auth_service.dart';
import '../main_layout.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool autoNavigate;
  final Duration duration;

  const SplashScreen({
    super.key,
    this.autoNavigate = true,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatingCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _illustrationScale;
  late final Animation<double> _illustrationFade;
  late final Animation<Offset> _waveSlide;
  late final Animation<double> _footerFade;

  late final Animation<double> _floatAnim;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.20, 0.55, curve: Curves.easeIn),
    );

    _illustrationScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _illustrationFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
    );

    _waveSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.15, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _footerFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.50, 0.95, curve: Curves.easeIn),
    );

    _floatingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatingCtrl, curve: Curves.easeInOut),
    );

    _entranceCtrl.forward();

    if (widget.autoNavigate) {
      _checkAuthenticationAndProceed();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatingCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthenticationAndProceed() async {
    if (_isNavigating) return;

    try {
      final splashTimer = Future.delayed(widget.duration);
      final authInitFuture = AuthService.instance.init();

      final results = await Future.wait([splashTimer, authInitFuture]);
      final isVerifiedAdmin = results[1] as bool;

      if (!mounted) return;
      _isNavigating = true;

      final provider = Provider.of<AdminProvider>(context, listen: false);

      if (isVerifiedAdmin) {
        provider.setAuthenticated(true);
        final cached = AuthService.instance.cachedUser;
        if (cached != null) {
          provider.adminProfile.id = cached.id;
          provider.adminProfile.name = cached.name;
          provider.adminProfile.email = cached.email;
          provider.adminProfile.role = cached.role;
          if (cached.avatarUrl.isNotEmpty) {
            provider.adminProfile.avatarUrl = cached.avatarUrl;
          }
          if (cached.phone.isNotEmpty) {
            provider.adminProfile.phone = cached.phone;
          }
          provider.adminProfile.lastLogin = DateTime.now();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainLayout(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        provider.setAuthenticated(false);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      debugPrint("SplashScreen: Error checking authentication: $e");
      if (!mounted) return;
      _isNavigating = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFBFD);
    final isCompactScreen = size.height < 700;
    final isSmallWidth = size.width < 360;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () {
          if (!widget.autoNavigate) {
            Navigator.of(context).maybePop();
          } else {
            _checkAuthenticationAndProceed();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: size.width * 0.15,
              right: size.width * 0.15,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.15 : 0.12),
                      const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.08 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            if (!widget.autoNavigate)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          size: 18,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  SizedBox(height: isCompactScreen ? 14 : 28),

                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _PennyPalWalletSprout(size: isCompactScreen ? 56 : 70),
                    ),
                  ),

                  SizedBox(height: isCompactScreen ? 10 : 16),

                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Penny',
                                  style: TextStyle(
                                    fontSize: isSmallWidth ? 28 : (isCompactScreen ? 32 : 36),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1D4ED8),
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Pal',
                                  style: TextStyle(
                                    fontSize: isSmallWidth ? 28 : (isCompactScreen ? 32 : 36),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF43F5E),
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),

                          // "Fresh All Along" Tagline
                          Text(
                            'Fresh All Along',
                            style: TextStyle(
                              fontSize: isCompactScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN PORTAL & OPERATIONS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isCompactScreen ? 10 : 18),

                  Expanded(
                    child: ScaleTransition(
                      scale: _illustrationScale,
                      child: FadeTransition(
                        opacity: _illustrationFade,
                        child: AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Center(
                              child: _buildHeroIllustration(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: (size.height * 0.11).clamp(16.0, 75.0)),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _waveSlide,
                child: SizedBox(
                  height: size.height * 0.22,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SplashDualWavePainter(),
                        ),
                      ),

                      FadeTransition(
                        opacity: _footerFade,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 22.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Smart Money',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 9.0),
                                  child: Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Better Future',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Image natural aspect ratio is ~1.34 (1024 x 764)
        final availableHeight = (maxH.isFinite && maxH > 60) ? maxH : 260.0;
        final availableWidth = (maxW.isFinite && maxW > 60) ? maxW : 360.0;

        final targetH = (availableHeight * 0.95).clamp(120.0, 260.0);
        final targetW = (targetH * 1.34).clamp(160.0, availableWidth);

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: targetW * 0.85,
              height: targetH * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF38BDF8) : const Color(0xFF93C5FD))
                        .withValues(alpha: isDark ? 0.20 : 0.28),
                    const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.08 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/images/splash_illustration.png',
              width: targetW,
              height: targetH,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/splash_illustration.png',
                  width: targetW,
                  height: targetH,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    width: targetW,
                    height: targetH,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PennyPal Admin Suite',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PennyPalWalletSprout extends StatelessWidget {
  final double size;

  const _PennyPalWalletSprout({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WalletSproutPainter(),
      ),
    );
  }
}

class _WalletSproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final sproutCenter = Offset(w * 0.50, h * 0.28);

    final stemPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(sproutCenter.dx, sproutCenter.dy + 8)
      ..quadraticBezierTo(sproutCenter.dx - 2, sproutCenter.dy, sproutCenter.dx, sproutCenter.dy - 10);
    canvas.drawPath(stemPath, stemPaint);

    // Left Leaf (Organic cyan/sky-blue leaf)
    final leftLeafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(sproutCenter.dx - 18, sproutCenter.dy - 18, 18, 16))
      ..style = PaintingStyle.fill;

    final leftLeaf = Path()
      ..moveTo(sproutCenter.dx - 1, sproutCenter.dy - 3)
      ..cubicTo(
        sproutCenter.dx - 8, sproutCenter.dy,
        sproutCenter.dx - 18, sproutCenter.dy - 6,
        sproutCenter.dx - 13, sproutCenter.dy - 16,
      )
      ..cubicTo(
        sproutCenter.dx - 5, sproutCenter.dy - 17,
        sproutCenter.dx - 1, sproutCenter.dy - 8,
        sproutCenter.dx - 1, sproutCenter.dy - 3,
      );
    canvas.drawPath(leftLeaf, leftLeafPaint);

    // Right Leaf
    final rightLeafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(sproutCenter.dx, sproutCenter.dy - 20, 20, 18))
      ..style = PaintingStyle.fill;

    final rightLeaf = Path()
      ..moveTo(sproutCenter.dx, sproutCenter.dy - 5)
      ..cubicTo(
        sproutCenter.dx + 8, sproutCenter.dy - 1,
        sproutCenter.dx + 18, sproutCenter.dy - 8,
        sproutCenter.dx + 14, sproutCenter.dy - 18,
      )
      ..cubicTo(
        sproutCenter.dx + 4, sproutCenter.dy - 18,
        sproutCenter.dx, sproutCenter.dy - 10,
        sproutCenter.dx, sproutCenter.dy - 5,
      );
    canvas.drawPath(rightLeaf, rightLeafPaint);

    final walletRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.65),
        width: w * 0.74,
        height: h * 0.52,
      ),
      const Radius.circular(13),
    );

    canvas.drawRRect(
      walletRect.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0xFF1D4ED8).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final walletPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF2563EB),
          Color(0xFF1D4ED8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(walletRect.outerRect);
    canvas.drawRRect(walletRect, walletPaint);

    final glossRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        walletRect.left + 2,
        walletRect.top + 2,
        walletRect.width - 4,
        walletRect.height * 0.32,
      ),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      glossRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(glossRect.outerRect),
    );

    // ── 3. Coral/Red Clasp with Coin Dot ────────────────────────────────────
    final claspWidth = w * 0.26;
    final claspHeight = h * 0.19;
    final claspCenter = Offset(
      walletRect.right - claspWidth * 0.45,
      walletRect.top + walletRect.height * 0.54,
    );

    final claspRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: claspCenter,
        width: claspWidth,
        height: claspHeight,
      ),
      const Radius.circular(6.5),
    );

    // Clasp Shadow
    canvas.drawRRect(
      claspRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Clasp Base (Vibrant Red-Pink)
    canvas.drawRRect(
      claspRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFB7185), Color(0xFFF43F5E), Color(0xFFE11D48)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(claspRect.outerRect),
    );

    // Inner White Coin/Button Dot
    final dotCenter = Offset(claspCenter.dx - claspWidth * 0.10, claspCenter.dy);
    canvas.drawCircle(
      dotCenter,
      claspHeight * 0.28,
      Paint()..color = Colors.white,
    );

    // Dot center indent
    canvas.drawCircle(
      dotCenter,
      claspHeight * 0.12,
      Paint()..color = const Color(0xFFF43F5E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashDualWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pinkPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFF472B6),
          Color(0xFFEC4899),
          Color(0xFFFB7185),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final pinkPath = Path();
    pinkPath.moveTo(0, h * 0.26);
    pinkPath.cubicTo(
      w * 0.22, h * 0.48,
      w * 0.65, h * 0.04,
      w, h * 0.28,
    );
    pinkPath.lineTo(w, h);
    pinkPath.lineTo(0, h);
    pinkPath.close();
    canvas.drawPath(pinkPath, pinkPaint);

    final bluePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF2563EB),
          Color(0xFF3B82F6),
          Color(0xFF1D4ED8),
          Color(0xFF4F46E5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bluePath = Path();
    bluePath.moveTo(0, h * 0.44);
    bluePath.cubicTo(
      w * 0.32, h * 0.64,
      w * 0.68, h * 0.26,
      w, h * 0.42,
    );
    bluePath.lineTo(w, h);
    bluePath.lineTo(0, h);
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // Soft top ambient highlight on the blue wave
    final waveHighlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.35, w, 20))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final highlightPath = Path()
      ..moveTo(0, h * 0.44)
      ..cubicTo(
        w * 0.32, h * 0.64,
        w * 0.68, h * 0.26,
        w, h * 0.42,
      );
    canvas.drawPath(highlightPath, waveHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
