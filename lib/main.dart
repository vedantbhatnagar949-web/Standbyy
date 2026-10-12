import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'standby_home_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const StandbyApp());
}

class StandbyApp extends StatefulWidget {
  const StandbyApp({super.key});

  @override
  State<StandbyApp> createState() => _StandbyAppState();
}

class _StandbyAppState extends State<StandbyApp> {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;
  bool _isClockOpen = false;
  bool? _hasCompletedGetStarted;

  @override
  void initState() {
    super.initState();
    _checkGetStarted();
    _checkInitialCharging();
    _listenChargingEvents();
  }

  void _checkGetStarted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('has_completed_get_started') ?? false;
      if (mounted) {
        setState(() => _hasCompletedGetStarted = hasCompleted);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasCompletedGetStarted = false);
      }
    }
  }

  void _checkInitialCharging() async {
    try {
      final state = await _battery.batteryState;
      if (state == BatteryState.charging || state == BatteryState.connectedNotCharging) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openRandomClock();
        });
      }
    } catch (_) {}
  }

  void _listenChargingEvents() {
    try {
      _batterySub = _battery.onBatteryStateChanged.listen((state) {
        if (state == BatteryState.charging || state == BatteryState.connectedNotCharging) {
          _openRandomClock();
        }
      });
    } catch (_) {}
  }

  void _openRandomClock() {
    if (_isClockOpen) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    _isClockOpen = true;
    final faces = StandbyClockFace.values;
    final randomFace = faces[Random().nextInt(faces.length)];

    nav.push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => LandscapeStandbyClockView(
          initialFace: randomFace,
          isNightMode: false,
          is24Hour: false,
          showSeconds: true,
          brightness: 1.0,
          alarmTime: '06:30',
          onExit: () {
            _isClockOpen = false;
            Navigator.of(context).pop();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) {
      _isClockOpen = false;
    });
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (_hasCompletedGetStarted == null) {
      homeWidget = const Scaffold(backgroundColor: Colors.black);
    } else if (_hasCompletedGetStarted == true) {
      homeWidget = const StandbyHomeScreen();
    } else {
      homeWidget = const GetStartedPage();
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Standby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: homeWidget,
    );
  }
}

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _fluidController;
  late AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..forward();
  }

  @override
  void dispose() {
    _fluidController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // Pure pitch black OLED top 60%
      body: AnimatedBuilder(
        animation: Listenable.merge([_fluidController, _introController]),
        builder: (context, child) {
          final intro = _introController.value;

          // 1. Text fades in in center of screen: 0.0 -> 0.35 (Silky gentle bloom)
          final titleFadeIn = Curves.easeOutQuart.transform(
            (intro / 0.35).clamp(0.0, 1.0),
          );

          // 2. Match & Move from center (0.42 height) to top (0.19 height): 0.30 -> 0.76 (Luxurious gradual ease)
          final titleMove = Curves.easeInOutCubicEmphasized.transform(
            ((intro - 0.30) / (0.76 - 0.30)).clamp(0.0, 1.0),
          );

          final centerY = size.height * 0.42;
          final targetY = size.height * 0.19;
          final currentTitleY = lerpDouble(centerY, targetY, titleMove)!;

          // Subtle font size morph from heroic center to sleek landing header
          final finalFontSize = (size.width * 0.065).clamp(56.0, 88.0);
          final centerFontSize = finalFontSize * 1.15;
          final currentFontSize =
              lerpDouble(centerFontSize, finalFontSize, titleMove)!;

          // Glowing bloom shadow when in center, morphing to sleek ambient shadow
          final glowBloom = lerpDouble(50.0, 32.0, titleMove)!;
          final glowAlpha = lerpDouble(0.70, 0.38, titleMove)!;

          // Subtitle fades in with letter-expansion as title moves to top: 0.52 -> 0.88
          final subtitleFade = Curves.easeOutCubic.transform(
            ((intro - 0.52) / (0.88 - 0.52)).clamp(0.0, 1.0),
          );
          final subtitleSlideY = (1.0 - subtitleFade) * 16.0;

          // 3. Fluid blue wave rises from below the viewport: 0.38 -> 0.86 (Smooth oceanic swell)
          final waveRise = Curves.easeOutQuart.transform(
            ((intro - 0.38) / (0.86 - 0.38)).clamp(0.0, 1.0),
          );
          final waveOffsetY = (1.0 - waveRise) * (size.height * 0.42);

          // 4. Getting started button rises from below with fluid wave: 0.52 -> 0.95 (Soft buoyant rise)
          final buttonRise = Curves.easeOutCubic.transform(
            ((intro - 0.52) / (0.95 - 0.52)).clamp(0.0, 1.0),
          );
          final buttonOffsetY = (1.0 - buttonRise.clamp(0.0, 1.0)) * 90.0;
          final buttonOpacity = Curves.easeOut.transform(
            ((intro - 0.52) / (0.80 - 0.52)).clamp(0.0, 1.0),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. ARCHITECTURAL TECH GRID FILLING BACKGROUND BEHIND THE GRADIENT
              const Positioned.fill(
                child: CustomPaint(
                  painter: TechGridBackgroundPainter(),
                ),
              ),

              // 2. AMBIENT SAPPHIRE EDGE-LIT GLOW (Smooth fade in)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: Curves.easeOut.transform((intro / 0.5).clamp(0.0, 1.0)),
                    child: const AmbientEdgeGlow(),
                  ),
                ),
              ),

              // 3. FLOWING BLURRED FLUID GRADIENT RISING FROM BELOW (BOTTOM 40%)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.40, // Strictly bottom 40%
                child: Transform.translate(
                  offset: Offset(0, waveOffsetY),
                  child: Opacity(
                    opacity: waveRise.clamp(0.0, 1.0),
                    child: ImageFiltered(
                      // Dual-axis optical blur for silky fluid wave diffusion
                      imageFilter: ImageFilter.blur(
                        sigmaX: 26.0,
                        sigmaY: 26.0,
                        tileMode: TileMode.decal,
                      ),
                      child: CustomPaint(
                        painter: Bottom40FlowingWavePainter(
                          progress: _fluidController.value,
                        ),
                        size: Size(size.width, size.height * 0.40),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. TITLE TYPOGRAPHY (Fades in at screen center, match-and-moves to top)
              Positioned(
                left: 24,
                right: 24,
                top: currentTitleY,
                child: Opacity(
                  opacity: titleFadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero wraps the title so it glides to login header
                      Hero(
                        tag: 'standby-title',
                        flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
                          // Custom shuttle: silk cross-fade and size glide during flight
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (ctx, _) {
                              final t = const Cubic(0.20, 0.0, 0.0, 1.0).transform(animation.value);
                              final fontSize = lerpDouble(currentFontSize, 26.0, t)!;
                              return Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  'Standby',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'DxFiggle',
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white,
                                    letterSpacing: lerpDouble(2.5, 1.5, t)!,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF1D4ED8).withValues(
                                          alpha: lerpDouble(glowAlpha, 0.30, t)!,
                                        ),
                                        blurRadius: lerpDouble(glowBloom, 24.0, t)!,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            'Standby',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DxFiggle',
                              fontSize: currentFontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              height: 1.05,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF1D4ED8).withValues(alpha: glowAlpha),
                                  blurRadius: glowBloom,
                                  offset: const Offset(0, 6),
                                ),
                                const Shadow(
                                  color: Colors.black,
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Editorial refined subtitle
                      Opacity(
                        opacity: subtitleFade,
                        child: Transform.translate(
                          offset: Offset(0, subtitleSlideY),
                          child: Text(
                            'S T A N D B Y   C L O C K S',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: lerpDouble(2.2, 3.8, subtitleFade)!,
                              color: Colors.white.withValues(alpha: 0.50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. LIQUID GLASS TRAY BUTTON RISING FROM BELOW (Hero-morphs into auth card)
              Positioned(
                left: 0,
                right: 0,
                bottom: 46,
                child: Transform.translate(
                  offset: Offset(0, buttonOffsetY),
                  child: Opacity(
                    opacity: buttonOpacity,
                    child: Center(
                      child: _LiquidGlassTrayButton(
                        onPressed: () {
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('has_completed_get_started', true);
                          });
                          // Silky 1100ms shared-element transition to login page
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 1100),
                              reverseTransitionDuration: const Duration(milliseconds: 900),
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const LoginPage(),
                              transitionsBuilder:
                                  (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: const Interval(0.12, 1.0, curve: Curves.easeInOutCubic),
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// AMBIENT SAPPHIRE EDGE-LIT GLOW
/// Recreates the soft luminous perimeter edge-glow framing the top and sides of the viewport
class AmbientEdgeGlow extends StatelessWidget {
  const AmbientEdgeGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top edge aura
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 130,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E40AF).withValues(alpha: 0.32),
                  const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Left edge aura
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF1D4ED8).withValues(alpha: 0.22),
                  const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
        ),

        // Right edge aura
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  const Color(0xFF1D4ED8).withValues(alpha: 0.22),
                  const Color(0xFF1E40AF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// DUAL-LAYER LIQUID GLASS TRAY BUTTON WITH INSET OBSIDIAN CORE
/// Faithfully reproduces the user's reference:
/// - Outer translucent blue liquid glass capsule tray with optical refraction
/// - Inset matte dark obsidian core capsule
/// - "Getting started..." typography with right-aligned indicator badge
class _LiquidGlassTrayButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _LiquidGlassTrayButton({required this.onPressed});

  @override
  State<_LiquidGlassTrayButton> createState() => _LiquidGlassTrayButtonState();
}

class _LiquidGlassTrayButtonState extends State<_LiquidGlassTrayButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.965 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Hero(
            tag: 'auth-card',
            flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
              return AnimatedBuilder(
                animation: animation,
                builder: (ctx, _) {
                  final t = const Cubic(0.20, 0.0, 0.0, 1.0).transform(animation.value);
                  final radius = lerpDouble(28.0, 32.0, t)!;
                  final height = lerpDouble(56.0, 620.0, t)!;
                  return Material(
                    type: MaterialType.transparency,
                    child: Container(
                      height: height,
                      constraints: BoxConstraints(
                        minWidth: lerpDouble(260, 340, t)!,
                        maxWidth: lerpDouble(300, 440, t)!,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(
                              const Color(0xFF2563EB).withValues(alpha: 0.32),
                              const Color(0xFF0F1015).withValues(alpha: 0.84),
                              t,
                            )!,
                            Color.lerp(
                              const Color(0xFF1E3A8A).withValues(alpha: 0.42),
                              const Color(0xFF0F1015).withValues(alpha: 0.84),
                              t,
                            )!,
                          ],
                        ),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xFF3B82F6).withValues(alpha: 0.65),
                            Colors.white.withValues(alpha: 0.14),
                            t,
                          )!,
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: lerpDouble(28, 36, t)!,
                            offset: Offset(0, lerpDouble(12, 16, t)!),
                          ),
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: lerpDouble(0.38, 0.20, t)!),
                            blurRadius: lerpDouble(18, 30, t)!,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
            height: 56,
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              // Outer blue liquid glass translucent body
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.45 : 0.32),
                  const Color(0xFF1E3A8A).withValues(alpha: _isHovered ? 0.55 : 0.42),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: _isHovered ? 0.85 : 0.65),
                width: 1.4,
              ),
              boxShadow: [
                // Deep ground shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                // Luminous electric blue aura glow
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.55 : 0.38),
                  blurRadius: _isHovered ? 26 : 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              // Inset spacing between outer liquid glass tray and inner obsidian core
              padding: const EdgeInsets.all(4.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23.5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131418), // Inset deep dark obsidian core
                    borderRadius: BorderRadius.circular(23.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.07),
                      width: 0.9,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // "Tap to get started" label centered
                      Center(
                        child: Text(
                          'Tap to get started',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),

                      // Status indicator badge on right
                      Positioned(
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF212328),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626), // Vivid ruby indicator square
                                borderRadius: BorderRadius.circular(2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ), // closes Hero child: Container
        ), // closes Hero
        ),
      ),
    );
  }
}

/// Architectural high-tech coordinate grid pattern filling the background
class TechGridBackgroundPainter extends CustomPainter {
  const TechGridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 48.0;

    // 1. Fine subtle grid lines filling the background
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.065)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical grid lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Horizontal grid lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 2. Subtle micro-dots at line intersections
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TechGridBackgroundPainter oldDelegate) => false;
}

/// FLOWING BLURRED FLUID WAVE CONFINED TO BOTTOM 40%
/// Renders a CONSTANT CONTRASTING DARK BLUE fluid ocean wave:
/// Not too dark, but a rich, cohesive, elegant royal dark blue with undulating waves.
class Bottom40FlowingWavePainter extends CustomPainter {
  final double progress;

  Bottom40FlowingWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * 2 * pi;

    // --- LAYER 1: DEEP MIDNIGHT NAVY OCEAN BASE ---
    // Solid fill reservoir ensuring no black gaps at the bottom
    final baseWave = _createWavePath(
      w: w,
      h: h,
      baseY: h * 0.36,
      amp1: h * 0.13,
      freq1: 1.8,
      phase1: t * 0.6,
      amp2: h * 0.08,
      freq2: 3.2,
      phase2: -t * 0.4 + 1.0,
      centerDip: h * 0.08,
    );
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E3A8A), // Rich Royal Sapphire
          const Color(0xFF172554), // Deep Navy
          const Color(0xFF0F172A), // Dark Abyss Blue
          const Color(0xFF070E20), // Bottom edge deep navy
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(baseWave, basePaint);

    // --- LAYER 2: MID-GROUND VIBRANT DARK BLUE WAVE ---
    final midWave = _createWavePath(
      w: w,
      h: h,
      baseY: h * 0.28,
      amp1: h * 0.15,
      freq1: 2.1,
      phase1: -t * 0.7 + 0.8,
      amp2: h * 0.09,
      freq2: 3.6,
      phase2: t * 0.5 + 2.0,
      centerDip: h * 0.06,
    );
    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: 0.92), // Radiant Cobalt Blue
          const Color(0xFF1D4ED8).withValues(alpha: 0.88), // Royal Blue
          const Color(0xFF1E3A8A).withValues(alpha: 0.95), // Deep Navy
          const Color(0xFF0F1E4A),
        ],
        stops: const [0.0, 0.30, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(midWave, midPaint);

    // --- LAYER 3: FOREGROUND ROLLING SAPPHIRE WAVE SWELL ---
    final foreWave = _createWavePath(
      w: w,
      h: h,
      baseY: h * 0.24,
      amp1: h * 0.14,
      freq1: 2.3,
      phase1: t * 0.8 + 1.6,
      amp2: h * 0.07,
      freq2: 4.2,
      phase2: -t * 0.6 + 0.6,
      centerDip: h * 0.05,
    );
    final forePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.75), // Bright Sapphire Crest
          const Color(0xFF1D4ED8).withValues(alpha: 0.85), // Royal Blue
          const Color(0xFF172554).withValues(alpha: 0.90), // Deep Navy
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(foreWave, forePaint);

    // --- LAYER 4: LUMINOUS DARK BLUE SURFACE CREST SHEEN ---
    // Smooth undulating crest highlight connecting the wave surface
    final crestWave = _createWavePath(
      w: w,
      h: h,
      baseY: h * 0.20,
      amp1: h * 0.13,
      freq1: 2.0,
      phase1: t * 0.75 + 1.2,
      amp2: h * 0.06,
      freq2: 3.8,
      phase2: -t * 0.5 + 2.5,
      centerDip: h * 0.05,
    );
    final crestPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.50), // Constant contrasting dark blue
          const Color(0xFF60A5FA).withValues(alpha: 0.40), // Gentle light swell
          const Color(0xFF2563EB).withValues(alpha: 0.55), // Cobalt
          const Color(0xFF3B82F6).withValues(alpha: 0.45),
        ],
        stops: const [0.05, 0.45, 0.75, 0.95],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(crestWave, crestPaint);
  }

  /// Harmonic physical water wave generator filled down to the bottom
  Path _createWavePath({
    required double w,
    required double h,
    required double baseY,
    required double amp1,
    required double freq1,
    required double phase1,
    required double amp2,
    required double freq2,
    required double phase2,
    required double centerDip,
  }) {
    final path = Path();
    path.moveTo(0, h); // Start at bottom-left

    const int steps = 80;
    final dx = w / steps;

    for (int i = 0; i <= steps; i++) {
      final x = i * dx;
      final normX = x / w;

      // Natural harmonic wave equations
      final wave1 = sin(normX * freq1 * pi + phase1) * amp1;
      final wave2 = cos(normX * freq2 * pi + phase2) * amp2;

      // Parabolic subtle center valley as seen in the Stitch reference image
      final valley = pow((normX - 0.5) * 2.0, 2) * centerDip;

      // Calculate surface elevation, clamped within container
      final y = (baseY - valley + wave1 + wave2).clamp(h * 0.05, h);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.lineTo(w, h); // To bottom-right
    path.close();      // Close down solid fluid fill
    return path;
  }

  @override
  bool shouldRepaint(covariant Bottom40FlowingWavePainter oldDelegate) => true;
}
