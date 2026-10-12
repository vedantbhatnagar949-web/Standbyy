import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

enum StandbyNavTab {
  clocks,
  subscription,
  settings,
}

enum StandbyClockFace {
  // 3 Fan-Favorites
  nixieTube,        // Soviet IN-18 Nixie Vacuum Cathode
  bauhausKinetic,   // Bauhaus 1919 Kinetic
  neonWireframe,    // Wireframe Vector Outline

  // 5 OLED StandBy References
  warmBubble,       // Warm Bubble StandBy
  gzestheticsMono,  // Monochrome Minimal
  segmentTelemetry, // 7-Segment Digital
  neonDuo,          // Apple StandBy Neon Duo
  dualWidget,       // StandBy Dual-Widget
}

class StandbyHomeScreen extends StatefulWidget {
  const StandbyHomeScreen({super.key});

  @override
  State<StandbyHomeScreen> createState() => _StandbyHomeScreenState();
}

class _StandbyHomeScreenState extends State<StandbyHomeScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _ambientController;
  DateTime _now = DateTime.now();

  // Battery Charging Listener
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;
  bool _hasAutoLaunchedCharging = false;

  // Navigation State
  StandbyNavTab _currentTab = StandbyNavTab.clocks;

  // Active Preferences
  bool _isNightMode = false;
  bool _is24Hour = false;
  bool _showSeconds = true;
  double _brightness = 1.0;
  bool _ambientWaves = true;
  bool _hapticTicks = true;
  bool _hourlyChime = false;
  bool _aodPreventSleep = true;
  bool _pixelShift = true;
  bool _autoDock = true;
  String _alarmTime = '06:30';

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _initBatteryListener();
  }

  void _initBatteryListener() {
    try {
      _battery.batteryState.then((state) {
        if (mounted && (state == BatteryState.charging || state == BatteryState.connectedNotCharging)) {
          if (_autoDock && !_hasAutoLaunchedCharging) {
            _hasAutoLaunchedCharging = true;
            _launchRandomClockOnCharge();
          }
        }
      });
    } catch (_) {}

    try {
      _batterySub = _battery.onBatteryStateChanged.listen((state) {
        if (mounted && (state == BatteryState.charging || state == BatteryState.connectedNotCharging)) {
          if (_autoDock) {
            _launchRandomClockOnCharge();
          }
        } else {
          _hasAutoLaunchedCharging = false;
        }
      });
    } catch (_) {}
  }

  void _launchRandomClockOnCharge() {
    final faces = StandbyClockFace.values;
    final randomFace = faces[Random().nextInt(faces.length)];
    _openClockInStandby(randomFace);
  }

  @override
  void dispose() {
    _timer.cancel();
    _batterySub?.cancel();
    _ambientController.dispose();
    super.dispose();
  }

  void _openClockInStandby(StandbyClockFace face) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => LandscapeStandbyClockView(
          initialFace: face,
          isNightMode: _isNightMode,
          is24Hour: _is24Hour,
          showSeconds: _showSeconds,
          brightness: _brightness,
          alarmTime: _alarmTime,
          onToggleNightMode: () {
            setState(() => _isNightMode = !_isNightMode);
          },
          onToggle24Hour: () {
            setState(() => _is24Hour = !_is24Hour);
          },
          onToggleSeconds: () {
            setState(() => _showSeconds = !_showSeconds);
          },
          onUpdateAlarm: (newTime) {
            setState(() => _alarmTime = newTime);
          },
          onExit: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final accentColor = _isNightMode ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Opacity(
        opacity: _brightness,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. ARCHITECTURAL TECH GRID
            const Positioned.fill(
              child: CustomPaint(
                painter: TechGridBackgroundPainter(),
              ),
            ),

            // 2. AMBIENT EDGE GLOW
            Positioned.fill(
              child: IgnorePointer(
                child: _CustomAmbientEdgeGlow(color: accentColor),
              ),
            ),

            // 3. AMBIENT BOTTOM FLUID WAVE
            if (_ambientWaves && !_isNightMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.35,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 28.0,
                    sigmaY: 28.0,
                    tileMode: TileMode.decal,
                  ),
                  child: AnimatedBuilder(
                    animation: _ambientController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: Bottom40FlowingWavePainter(
                          progress: _ambientController.value,
                        ),
                        size: Size(size.width, size.height * 0.35),
                      );
                    },
                  ),
                ),
              ),

            // 4. MAIN PAGE BODY BY ACTIVE TAB
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 96), // Space for floating nav
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildCurrentTabContent(accentColor),
                ),
              ),
            ),

            // 5. FLOATING LIQUID GLASS 3-TAB NAV BAR
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Center(
                child: _MainFloatingNavBar(
                  currentTab: _currentTab,
                  isNightMode: _isNightMode,
                  onSelectTab: (tab) => setState(() => _currentTab = tab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(Color accentColor) {
    switch (_currentTab) {
      case StandbyNavTab.clocks:
        return _ClocksGalleryTab(
          key: const ValueKey('clocks_tab'),
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _isNightMode,
          accentColor: accentColor,
          alarmTime: _alarmTime,
          onTapClock: _openClockInStandby,
          onLaunchAll: () => _openClockInStandby(StandbyClockFace.nixieTube),
          onTestChargeLaunch: _launchRandomClockOnCharge,
        );
      case StandbyNavTab.subscription:
        return _SubscriptionTab(
          key: const ValueKey('sub_tab'),
          isNightMode: _isNightMode,
          accentColor: accentColor,
        );
      case StandbyNavTab.settings:
        return _SettingsFullPageTab(
          key: const ValueKey('settings_tab'),
          isNightMode: _isNightMode,
          is24Hour: _is24Hour,
          showSeconds: _showSeconds,
          brightness: _brightness,
          ambientWaves: _ambientWaves,
          hapticTicks: _hapticTicks,
          hourlyChime: _hourlyChime,
          aodPreventSleep: _aodPreventSleep,
          pixelShift: _pixelShift,
          autoDock: _autoDock,
          accentColor: accentColor,
          onToggleNightMode: (v) => setState(() => _isNightMode = v),
          onToggle24Hour: (v) => setState(() => _is24Hour = v),
          onToggleSeconds: (v) => setState(() => _showSeconds = v),
          onChangeBrightness: (v) => setState(() => _brightness = v),
          onToggleAmbientWaves: (v) => setState(() => _ambientWaves = v),
          onToggleHaptics: (v) => setState(() => _hapticTicks = v),
          onToggleChime: (v) => setState(() => _hourlyChime = v),
          onToggleAod: (v) => setState(() => _aodPreventSleep = v),
          onTogglePixelShift: (v) => setState(() => _pixelShift = v),
          onToggleAutoDock: (v) => setState(() => _autoDock = v),
          onTestChargeLaunch: _launchRandomClockOnCharge,
          onSignOut: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('has_completed_get_started');
            } catch (_) {}
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GetStartedPage()),
            );
          },
        );
    }
  }
}

// ============================================================================
// TAB 1: CLOCKS GALLERY PAGE WITH BESPOKE CARDS
// ============================================================================
class _ClocksGalleryTab extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final Color accentColor;
  final String alarmTime;
  final ValueChanged<StandbyClockFace> onTapClock;
  final VoidCallback onLaunchAll;
  final VoidCallback onTestChargeLaunch;

  const _ClocksGalleryTab({
    super.key,
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.accentColor,
    required this.alarmTime,
    required this.onTapClock,
    required this.onLaunchAll,
    required this.onTestChargeLaunch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gallery Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STANDBY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: isNightMode ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clocks',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              // Live Clock Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any clock to open fullscreen StandBy mode. Swipe up or down to switch clocks.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Hero Fullscreen Launch Pill
          GestureDetector(
            onTap: onLaunchAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isNightMode ? const Color(0xFFDC2626) : const Color(0xFF2563EB)).withValues(alpha: 0.35),
                    (isNightMode ? const Color(0xFF991B1B) : const Color(0xFF1D4ED8)).withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isNightMode ? const Color(0xFFEF4444) : const Color(0xFF60A5FA)).withValues(alpha: 0.40),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dock_rounded,
                    color: isNightMode ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Open Fullscreen Clock (Vertical Scroll ↑↓)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Charging Auto-Launch Simulator Card
          GestureDetector(
            onTap: onTestChargeLaunch,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Open on Charger Active ⚡',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Tap here to test plugging in (opens a random clock directly)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 8 Clock Cards Showcase
          // 1. Soviet Nixie Tube
          _ClockFaceCard(
            title: 'Soviet Nixie Tube',
            badge: 'VINTAGE',
            subtitle: 'Glowing vacuum tubes with a warm vintage orange filament.',
            accentColor: const Color(0xFFFF7700),
            preview: _NixieFilamentFace(now: now, is24Hour: is24Hour, isNightMode: isNightMode, isMobile: true),
            onTap: () => onTapClock(StandbyClockFace.nixieTube),
          ),
          const SizedBox(height: 18),

          // 2. Bauhaus 1919
          _ClockFaceCard(
            title: 'Bauhaus 1919',
            badge: 'KINETIC',
            subtitle: 'Geometric shapes and primary colors inspired by classic Bauhaus design.',
            accentColor: const Color(0xFFE11D48),
            preview: _BauhausKineticFace(now: now, is24Hour: is24Hour, isNightMode: isNightMode, isMobile: true),
            onTap: () => onTapClock(StandbyClockFace.bauhausKinetic),
          ),
          const SizedBox(height: 18),

          // 3. Wireframe Vector
          _ClockFaceCard(
            title: 'Wireframe Vector',
            badge: 'NEON',
            subtitle: 'Electric cyan outline digits with a glowing modern vector aesthetic.',
            accentColor: const Color(0xFF00E5FF),
            preview: _NeonWireframeFace(now: now, is24Hour: is24Hour, isNightMode: isNightMode, isMobile: true),
            onTap: () => onTapClock(StandbyClockFace.neonWireframe),
          ),
          const SizedBox(height: 18),

          // 4. Warm Bubble
          _ClockFaceCard(
            title: 'Warm Bubble',
            badge: 'STANDBY',
            subtitle: 'Chunky rounded digits in warm peach and sunset orange tones.',
            accentColor: const Color(0xFFFF5722),
            preview: _WarmBubbleClockView(
              now: now,
              is24Hour: is24Hour,
              isNightMode: isNightMode,
              palette: const _DuoPalette(
                name: 'Sunset',
                hourColor: Color(0xFFFF5722),
                minuteColor: Color(0xFFFFA26B),
                colonColor: Color(0xFFFFE0B2),
              ),
              alarmTime: alarmTime,
              onTapAlarm: () {},
              isLandscape: false,
            ),
            onTap: () => onTapClock(StandbyClockFace.warmBubble),
          ),
          const SizedBox(height: 18),

          // 5. Monochrome Minimal
          _ClockFaceCard(
            title: 'Monochrome Minimal',
            badge: 'MINIMAL',
            subtitle: 'Tall condensed white numerals with a clean, distraction-free layout.',
            accentColor: Colors.white,
            preview: _GzestheticsMonoClockView(now: now, is24Hour: is24Hour, isNightMode: isNightMode, isLandscape: false),
            onTap: () => onTapClock(StandbyClockFace.gzestheticsMono),
          ),
          const SizedBox(height: 18),

          // 6. 7-Segment Digital
          _ClockFaceCard(
            title: '7-Segment Digital',
            badge: 'RETRO',
            subtitle: 'Classic illuminated LED segments showing time, weather, and date.',
            accentColor: const Color(0xFF10B981),
            preview: _SegmentTelemetryClockView(now: now, is24Hour: is24Hour, isNightMode: isNightMode, isLandscape: false),
            onTap: () => onTapClock(StandbyClockFace.segmentTelemetry),
          ),
          const SizedBox(height: 18),

          // 7. Neon Duo
          _ClockFaceCard(
            title: 'Neon Duo',
            badge: 'DUAL TONE',
            subtitle: 'Bold dual-tone rounded numerals in hot magenta and deep purple.',
            accentColor: const Color(0xFFFF2D75),
            preview: _NeonDuoClockView(
              now: now,
              is24Hour: is24Hour,
              isNightMode: isNightMode,
              palette: const _DuoPalette(
                name: 'Apple',
                hourColor: Color(0xFFFF2D75),
                minuteColor: Color(0xFF7C4DFF),
                colonColor: Color(0xFFE1BEE7),
              ),
              isLandscape: false,
            ),
            onTap: () => onTapClock(StandbyClockFace.neonDuo),
          ),
          const SizedBox(height: 18),

          // 8. Dual Widget
          _ClockFaceCard(
            title: 'Dual Widget',
            badge: 'WIDGETS',
            subtitle: 'Classic analog clock paired with a live monthly calendar.',
            accentColor: const Color(0xFFFF453A),
            preview: _DualWidgetClockView(now: now, isNightMode: isNightMode, showSeconds: true, isLandscape: false),
            onTap: () => onTapClock(StandbyClockFace.dualWidget),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ClockFaceCard extends StatefulWidget {
  final String title;
  final String badge;
  final String subtitle;
  final Color accentColor;
  final Widget preview;
  final VoidCallback onTap;

  const _ClockFaceCard({
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.accentColor,
    required this.preview,
    required this.onTap,
  });

  @override
  State<_ClockFaceCard> createState() => _ClockFaceCardState();
}

class _ClockFaceCardState extends State<_ClockFaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.10),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.45),
                blurRadius: _isHovered ? 24 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Preview Box
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: widget.preview,
                      ),
                    ),
                  ),
                ),
              ),

              // Metadata & Launch Trigger
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.badge,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: _isHovered ? widget.accentColor : Colors.white38,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                        height: 1.35,
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

// ============================================================================
// FULLSCREEN STANDBY DOCK VIEW (VERTICAL SWIPING OLED CAROUSEL)
// ============================================================================
class LandscapeStandbyClockView extends StatefulWidget {
  final StandbyClockFace initialFace;
  final bool isNightMode;
  final bool is24Hour;
  final bool showSeconds;
  final double brightness;
  final String alarmTime;
  final VoidCallback? onToggleNightMode;
  final VoidCallback? onToggle24Hour;
  final VoidCallback? onToggleSeconds;
  final ValueChanged<String>? onUpdateAlarm;
  final VoidCallback onExit;

  const LandscapeStandbyClockView({
    super.key,
    required this.initialFace,
    this.isNightMode = false,
    this.is24Hour = false,
    this.showSeconds = true,
    this.brightness = 1.0,
    this.alarmTime = '06:30',
    this.onToggleNightMode,
    this.onToggle24Hour,
    this.onToggleSeconds,
    this.onUpdateAlarm,
    required this.onExit,
  });

  @override
  State<LandscapeStandbyClockView> createState() => _LandscapeStandbyClockViewState();
}

class _LandscapeStandbyClockViewState extends State<LandscapeStandbyClockView> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  late PageController _pageController;
  late int _currentIndex;
  final List<StandbyClockFace> _faces = StandbyClockFace.values;

  // Internal toggles
  late bool _nightMode;
  late bool _is24Hour;
  late bool _showSeconds;
  late String _alarmTime;

  // Auto-hiding HUD
  bool _showHud = true;
  Timer? _hideHudTimer;

  // Duo palettes
  int _paletteIndex = 0;
  final List<_DuoPalette> _palettes = const [
    _DuoPalette(
      name: 'Sunset Orange',
      hourColor: Color(0xFFFF5722),
      minuteColor: Color(0xFFFFA26B),
      colonColor: Color(0xFFFFE0B2),
    ),
    _DuoPalette(
      name: 'Apple StandBy (Pink/Violet)',
      hourColor: Color(0xFFFF2D75),
      minuteColor: Color(0xFF7C4DFF),
      colonColor: Color(0xFFE1BEE7),
    ),
    _DuoPalette(
      name: 'Cyber Cyan/Lime',
      hourColor: Color(0xFF00E5FF),
      minuteColor: Color(0xFF00E676),
      colonColor: Color(0xFFB9F6CA),
    ),
    _DuoPalette(
      name: 'Solar Amber',
      hourColor: Color(0xFFFF9100),
      minuteColor: Color(0xFFFFD54F),
      colonColor: Color(0xFFFFF8E1),
    ),
    _DuoPalette(
      name: 'Pure Monochrome',
      hourColor: Color(0xFFFFFFFF),
      minuteColor: Color(0xFFE0E0E0),
      colonColor: Color(0xFFBDBDBD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nightMode = widget.isNightMode;
    _is24Hour = widget.is24Hour;
    _showSeconds = widget.showSeconds;
    _alarmTime = widget.alarmTime;

    _currentIndex = _faces.indexOf(widget.initialFace);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _resetHudTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _hideHudTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _resetHudTimer() {
    _hideHudTimer?.cancel();
    if (!_showHud) {
      setState(() => _showHud = true);
    }
    _hideHudTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHud = false);
    });
  }

  void _onUserTouch() {
    _resetHudTimer();
  }

  void _toggleNightMode() {
    _onUserTouch();
    setState(() => _nightMode = !_nightMode);
    widget.onToggleNightMode?.call();
  }

  void _toggle24Hour() {
    _onUserTouch();
    setState(() => _is24Hour = !_is24Hour);
    widget.onToggle24Hour?.call();
  }

  void _toggleSeconds() {
    _onUserTouch();
    setState(() => _showSeconds = !_showSeconds);
    widget.onToggleSeconds?.call();
  }

  void _cyclePalette() {
    _onUserTouch();
    HapticFeedback.lightImpact();
    setState(() => _paletteIndex = (_paletteIndex + 1) % _palettes.length);
  }

  void _pickAlarmTime() async {
    _onUserTouch();
    final parts = _alarmTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 6,
      minute: int.tryParse(parts[1]) ?? 30,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF5722),
            surface: Color(0xFF1E1E1E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _alarmTime = '$h:$m');
      widget.onUpdateAlarm?.call('$h:$m');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isMobile = size.width < 700;
    final nightRed = const Color(0xFFFF2A2A);
    final activePalette = _palettes[_paletteIndex];

    return Scaffold(
      backgroundColor: Colors.black, // Pure OLED black
      body: MouseRegion(
        onHover: (_) => _onUserTouch(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _showHud = !_showHud);
            if (_showHud) _resetHudTimer();
          },
          child: Opacity(
            opacity: widget.brightness,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. VERTICALLY SCROLLING CAROUSEL OVER ALL 8 FACES
                ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      ui.PointerDeviceKind.touch,
                      ui.PointerDeviceKind.mouse,
                      ui.PointerDeviceKind.trackpad,
                      ui.PointerDeviceKind.stylus,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical, // Up/down scrolling!
                    physics: const BouncingScrollPhysics(),
                    itemCount: _faces.length,
                    onPageChanged: (idx) {
                      setState(() => _currentIndex = idx);
                      _onUserTouch();
                      HapticFeedback.lightImpact();
                    },
                    itemBuilder: (context, index) {
                      final face = _faces[index];
                      return Center(
                        child: _buildClockView(face, isLandscape, isMobile, activePalette),
                      );
                    },
                  ),
                ),

                // 2. TOP HUD (STYLE BADGE WITH UP-SCROLLING TEXT, CONTROLS, EXIT BUTTON)
                Positioned(
                  top: 16,
                  left: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showHud ? 1.0 : 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Current Style Pill Badge with UP-SCROLLING Text Animation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _nightMode ? nightRed : const Color(0xFF10B981),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_nightMode ? nightRed : const Color(0xFF10B981))
                                          .withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Animated Up-Scrolling Text Transition
                              ClipRect(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.75), // Slides up from bottom!
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _getFaceTitle(_faces[_currentIndex]),
                                    key: ValueKey<int>(_currentIndex),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.unfold_more_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ],
                          ),
                        ),

                        // Right: Quick Controls & Exit
                        Row(
                          children: [
                            // 12H / 24H Toggle
                            _IconButtonPill(
                              label: _is24Hour ? '24H' : '12H',
                              onTap: _toggle24Hour,
                            ),
                            const SizedBox(width: 8),

                            // Seconds Toggle (for Dual Widget)
                            if (_faces[_currentIndex] == StandbyClockFace.dualWidget) ...[
                              _IconButtonPill(
                                label: _showSeconds ? 'SEC ON' : 'SEC OFF',
                                onTap: _toggleSeconds,
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Palette Cycle (for Bubble & Neon Duo)
                            if (_faces[_currentIndex] == StandbyClockFace.warmBubble ||
                                _faces[_currentIndex] == StandbyClockFace.neonDuo) ...[
                              _IconButtonPill(
                                icon: Icons.palette_outlined,
                                onTap: _cyclePalette,
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Night Mode (🌙)
                            _IconButtonPill(
                              icon: _nightMode ? Icons.bedtime : Icons.bedtime_outlined,
                              activeColor: _nightMode ? nightRed : null,
                              onTap: _toggleNightMode,
                            ),
                            const SizedBox(width: 8),

                            // Exit Button (✕) to return back to Home Screen
                            _IconButtonPill(
                              icon: Icons.close_rounded,
                              onTap: widget.onExit,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. RIGHT-EDGE SLEEK VERTICAL INDICATOR (DOTS FOR UP/DOWN PAGING)
                Positioned(
                  right: 18,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showHud ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414).withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_faces.length, (i) {
                            final isSelected = _currentIndex == i;
                            return GestureDetector(
                              onTap: () {
                                _onUserTouch();
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(vertical: 3.5),
                                width: 5,
                                height: isSelected ? 22 : 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isSelected ? Colors.white : Colors.white24,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. BOTTOM FLOATING LIQUID GLASS DOCK (STANDBY STYLE PICKER)
                Positioned(
                  bottom: 18,
                  left: 12,
                  right: 12,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showHud ? 1.0 : 0.0,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 840),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white12, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_faces.length, (i) {
                              final face = _faces[i];
                              return _DockItem(
                                icon: _getFaceIcon(face),
                                label: _getFaceShortLabel(face),
                                isSelected: _currentIndex == i,
                                onTap: () {
                                  _onUserTouch();
                                  HapticFeedback.selectionClick();
                                  setState(() => _currentIndex = i);
                                  _pageController.animateToPage(
                                    i,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                              );
                            }),
                          ),
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
    );
  }

  Widget _buildClockView(StandbyClockFace face, bool isLandscape, bool isMobile, _DuoPalette palette) {
    switch (face) {
      case StandbyClockFace.nixieTube:
        return _NixieFilamentFace(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          isMobile: isMobile,
        );
      case StandbyClockFace.bauhausKinetic:
        return _BauhausKineticFace(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          isMobile: isMobile,
        );
      case StandbyClockFace.neonWireframe:
        return _NeonWireframeFace(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          isMobile: isMobile,
        );
      case StandbyClockFace.warmBubble:
        return _WarmBubbleClockView(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          palette: palette,
          alarmTime: _alarmTime,
          onTapAlarm: _pickAlarmTime,
          isLandscape: isLandscape,
        );
      case StandbyClockFace.gzestheticsMono:
        return _GzestheticsMonoClockView(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          isLandscape: isLandscape,
        );
      case StandbyClockFace.segmentTelemetry:
        return _SegmentTelemetryClockView(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          isLandscape: isLandscape,
        );
      case StandbyClockFace.neonDuo:
        return _NeonDuoClockView(
          now: _now,
          is24Hour: _is24Hour,
          isNightMode: _nightMode,
          palette: palette,
          isLandscape: isLandscape,
        );
      case StandbyClockFace.dualWidget:
        return _DualWidgetClockView(
          now: _now,
          isNightMode: _nightMode,
          showSeconds: _showSeconds,
          isLandscape: isLandscape,
        );
    }
  }

  String _getFaceTitle(StandbyClockFace face) {
    switch (face) {
      case StandbyClockFace.nixieTube:
        return 'Soviet Nixie Tube';
      case StandbyClockFace.bauhausKinetic:
        return 'Bauhaus 1919';
      case StandbyClockFace.neonWireframe:
        return 'Wireframe Vector';
      case StandbyClockFace.warmBubble:
        return 'Warm Bubble';
      case StandbyClockFace.gzestheticsMono:
        return 'Monochrome Minimal';
      case StandbyClockFace.segmentTelemetry:
        return '7-Segment Digital';
      case StandbyClockFace.neonDuo:
        return 'Neon Duo';
      case StandbyClockFace.dualWidget:
        return 'Dual Widget';
    }
  }

  String _getFaceShortLabel(StandbyClockFace face) {
    switch (face) {
      case StandbyClockFace.nixieTube:
        return 'Nixie';
      case StandbyClockFace.bauhausKinetic:
        return 'Bauhaus';
      case StandbyClockFace.neonWireframe:
        return 'Wireframe';
      case StandbyClockFace.warmBubble:
        return 'Bubble';
      case StandbyClockFace.gzestheticsMono:
        return 'Minimal';
      case StandbyClockFace.segmentTelemetry:
        return '7-Segment';
      case StandbyClockFace.neonDuo:
        return 'Neon Duo';
      case StandbyClockFace.dualWidget:
        return 'Dual Widget';
    }
  }

  IconData _getFaceIcon(StandbyClockFace face) {
    switch (face) {
      case StandbyClockFace.nixieTube:
        return Icons.lightbulb_outline_rounded;
      case StandbyClockFace.bauhausKinetic:
        return Icons.category_rounded;
      case StandbyClockFace.neonWireframe:
        return Icons.filter_frames_rounded;
      case StandbyClockFace.warmBubble:
        return Icons.bubble_chart_rounded;
      case StandbyClockFace.gzestheticsMono:
        return Icons.text_fields_rounded;
      case StandbyClockFace.segmentTelemetry:
        return Icons.developer_board_rounded;
      case StandbyClockFace.neonDuo:
        return Icons.auto_awesome_rounded;
      case StandbyClockFace.dualWidget:
        return Icons.calendar_today_rounded;
    }
  }
}

// ============================================================================
// TAB 2: SUBSCRIPTION MEMBERSHIP PAGE
// ============================================================================
class _SubscriptionTab extends StatefulWidget {
  final bool isNightMode;
  final Color accentColor;

  const _SubscriptionTab({
    super.key,
    required this.isNightMode,
    required this.accentColor,
  });

  @override
  State<_SubscriptionTab> createState() => _SubscriptionTabState();
}

class _SubscriptionTabState extends State<_SubscriptionTab> {
  int _selectedPlan = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Crown Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), width: 1),
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 16),
          Text(
            'STANDBY PRO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upgrade to Pro',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all 8 clock styles, custom color themes, and bedside night mode.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Plan Cards
          _PlanCard(
            title: 'Annual Pass',
            price: '\$29.99 / year',
            period: 'Includes 7-day free trial (\$2.49/mo)',
            badge: 'MOST POPULAR',
            isSelected: _selectedPlan == 0,
            onTap: () => setState(() => _selectedPlan = 0),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Lifetime Pass',
            price: '\$59.99 one-time',
            period: 'Pay once, keep forever with all future updates',
            badge: 'LIFETIME',
            isSelected: _selectedPlan == 1,
            onTap: () => setState(() => _selectedPlan = 1),
          ),
          const SizedBox(height: 24),

          // Features List
          _buildFeatureRow(Icons.check_circle_rounded, 'All 8 clock styles fully unlocked'),
          _buildFeatureRow(Icons.check_circle_rounded, 'Full access to all widgets and live calendar'),
          _buildFeatureRow(Icons.check_circle_rounded, 'Red nightstand mode for OLED screens'),
          _buildFeatureRow(Icons.check_circle_rounded, 'Live weather, battery, and date widgets'),
          const SizedBox(height: 26),

          // Action Button
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _selectedPlan == 0 ? 'Start 7-Day Free Trial' : 'Unlock Standby Pro',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Restore Purchases  •  Terms of Service  •  Privacy Policy',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.80)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF101217).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 16,
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF60A5FA) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF60A5FA),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(
                    period,
                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: SETTINGS PAGE
// ============================================================================
class _SettingsFullPageTab extends StatelessWidget {
  final bool isNightMode;
  final bool is24Hour;
  final bool showSeconds;
  final double brightness;
  final bool ambientWaves;
  final bool hapticTicks;
  final bool hourlyChime;
  final bool aodPreventSleep;
  final bool pixelShift;
  final bool autoDock;
  final Color accentColor;
  final ValueChanged<bool> onToggleNightMode;
  final ValueChanged<bool> onToggle24Hour;
  final ValueChanged<bool> onToggleSeconds;
  final ValueChanged<double> onChangeBrightness;
  final ValueChanged<bool> onToggleAmbientWaves;
  final ValueChanged<bool> onToggleHaptics;
  final ValueChanged<bool> onToggleChime;
  final ValueChanged<bool> onToggleAod;
  final ValueChanged<bool> onTogglePixelShift;
  final ValueChanged<bool> onToggleAutoDock;
  final VoidCallback onTestChargeLaunch;
  final VoidCallback onSignOut;

  const _SettingsFullPageTab({
    super.key,
    required this.isNightMode,
    required this.is24Hour,
    required this.showSeconds,
    required this.brightness,
    required this.ambientWaves,
    required this.hapticTicks,
    required this.hourlyChime,
    required this.aodPreventSleep,
    required this.pixelShift,
    required this.autoDock,
    required this.accentColor,
    required this.onToggleNightMode,
    required this.onToggle24Hour,
    required this.onToggleSeconds,
    required this.onChangeBrightness,
    required this.onToggleAmbientWaves,
    required this.onToggleHaptics,
    required this.onToggleChime,
    required this.onToggleAod,
    required this.onTogglePixelShift,
    required this.onToggleAutoDock,
    required this.onTestChargeLaunch,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERENCES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: isNightMode ? const Color(0xFFEF4444) : const Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('DISPLAY & TIME'),
          _buildGlassCard([
            _buildSwitchTile('24-Hour Time', 'Use 24-hour format instead of 12-hour AM/PM', is24Hour, onToggle24Hour),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Show Seconds', 'Display real-time seconds', showSeconds, onToggleSeconds),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Night Mode', 'Red tint to reduce eye strain in dark rooms', isNightMode, onToggleNightMode),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Wave Animation Effect', 'Animated ambient fluid waves on background', ambientWaves, onToggleAmbientWaves),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Brightness (${(brightness * 100).round()}%)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 4),
                  Slider(
                    value: brightness,
                    min: 0.2,
                    max: 1.0,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: onChangeBrightness,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 22),

          _buildSectionHeader('SOUND & HAPTICS'),
          _buildGlassCard([
            _buildSwitchTile('Haptic Feedback', 'Soft vibration on every tick', hapticTicks, onToggleHaptics),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Hourly Chime', 'Soft chime sound at the top of each hour', hourlyChime, onToggleChime),
          ]),
          const SizedBox(height: 22),

          _buildSectionHeader('CHARGING & DISPLAY PROTECTION'),
          _buildGlassCard([
            _buildSwitchTile('Keep Awake While Charging', 'Keep screen awake while phone is plugged in', aodPreventSleep, onToggleAod),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Burn-in Protection', 'Slightly shifts pixels over time', pixelShift, onTogglePixelShift),
            const Divider(color: Colors.white10, height: 1),
            _buildSwitchTile('Auto-Open Clock When Charging', 'Opens a random clock when plugged into power', autoDock, onToggleAutoDock),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: GestureDetector(
                onTap: onTestChargeLaunch,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Simulate Plugged in Charger ⚡',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 26),

          // Sign Out Button
          Center(
            child: TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              label: Text(
                'Log Out to Welcome Screen',
                style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.white54),
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101217).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white54)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: accentColor,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FLOATING LIQUID GLASS BOTTOM NAVIGATION BAR
// ============================================================================
class _MainFloatingNavBar extends StatelessWidget {
  final StandbyNavTab currentTab;
  final bool isNightMode;
  final ValueChanged<StandbyNavTab> onSelectTab;

  const _MainFloatingNavBar({
    required this.currentTab,
    required this.isNightMode,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isNightMode ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavTabPill(
                icon: Icons.access_time_filled_rounded,
                label: 'Clocks',
                isSelected: currentTab == StandbyNavTab.clocks,
                activeColor: activeColor,
                onTap: () => onSelectTab(StandbyNavTab.clocks),
              ),
              const SizedBox(width: 6),
              _NavTabPill(
                icon: Icons.diamond_rounded,
                label: 'Subscription',
                isSelected: currentTab == StandbyNavTab.subscription,
                activeColor: activeColor,
                onTap: () => onSelectTab(StandbyNavTab.subscription),
              ),
              const SizedBox(width: 6),
              _NavTabPill(
                icon: Icons.tune_rounded,
                label: 'Settings',
                isSelected: currentTab == StandbyNavTab.settings,
                activeColor: activeColor,
                onTap: () => onSelectTab(StandbyNavTab.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavTabPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.70), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : Colors.white60,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ambient Edge Glow
class _CustomAmbientEdgeGlow extends StatelessWidget {
  final Color color;
  const _CustomAmbientEdgeGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 140,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// RE-ADDED FAN FAVORITE 1: SOVIET IN-18 NIXIE VACUUM CATHODE CLOCK
// Glowing amber glass tubes, pixel filaments, and anode mesh technical labels
// =============================================================================
class _NixieFilamentFace extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final bool isMobile;

  const _NixieFilamentFace({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    int hour = now.hour;
    if (!is24Hour) {
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = now.minute.toString().padLeft(2, '0');
    final sStr = now.second.toString().padLeft(2, '0');
    final glowColor = isNightMode ? const Color(0xFFEF4444) : const Color(0xFFFF7700);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SOVIET IN-18 NIXIE VACUUM CATHODE',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.8,
              color: glowColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NixieGlassTube(digit: hStr[0], isNightMode: isNightMode, isMobile: isMobile),
                const SizedBox(width: 8),
                _NixieGlassTube(digit: hStr[1], isNightMode: isNightMode, isMobile: isMobile),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: glowColor,
                      fontSize: isMobile ? 36 : 56,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: glowColor, blurRadius: 16),
                      ],
                    ),
                  ),
                ),
                _NixieGlassTube(digit: mStr[0], isNightMode: isNightMode, isMobile: isMobile),
                const SizedBox(width: 8),
                _NixieGlassTube(digit: mStr[1], isNightMode: isNightMode, isMobile: isMobile),
                const SizedBox(width: 14),
                _NixieGlassTube(digit: sStr, isNightMode: isNightMode, isMobile: isMobile, isSmall: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ANODE WIRE MESH • 170V DC IONIZED NEON',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              color: Colors.white30,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NixieGlassTube extends StatelessWidget {
  final String digit;
  final bool isNightMode;
  final bool isMobile;
  final bool isSmall;

  const _NixieGlassTube({
    required this.digit,
    required this.isNightMode,
    required this.isMobile,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = isNightMode ? const Color(0xFFEF4444) : const Color(0xFFFF7700);
    final width = isSmall ? (isMobile ? 42.0 : 60.0) : (isMobile ? 62.0 : 96.0);
    final height = isSmall ? (isMobile ? 74.0 : 108.0) : (isMobile ? 106.0 : 166.0);
    final fontSize = isSmall ? (isMobile ? 32.0 : 48.0) : (isMobile ? 60.0 : 102.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF130B04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glowColor.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 22),
        ],
      ),
      child: Center(
        child: Text(
          digit,
          style: GoogleFonts.vt323(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: glowColor,
            shadows: [
              Shadow(color: glowColor, blurRadius: 18),
              Shadow(color: glowColor.withValues(alpha: 0.65), blurRadius: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// RE-ADDED FAN FAVORITE 2: STAATLICHES BAUHAUS WEIMAR // 1919
// Red circle hour, blue rounded rectangle minute, yellow circle second
// =============================================================================
class _BauhausKineticFace extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final bool isMobile;

  const _BauhausKineticFace({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    int hour = now.hour;
    if (!is24Hour) {
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    final size = isMobile ? 86.0 : 140.0;
    final fontSz = isMobile ? 40.0 : 72.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STAATLICHES BAUHAUS WEIMAR // 1919',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Circle for Hour
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNightMode ? const Color(0xFFEF4444) : const Color(0xFFE11D48),
                    boxShadow: [
                      BoxShadow(
                        color: (isNightMode ? const Color(0xFFEF4444) : const Color(0xFFE11D48))
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(
                        fontSize: fontSz,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Blue Rounded Rectangle for Minute
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isNightMode ? const Color(0xFF991B1B) : const Color(0xFF2563EB),
                    boxShadow: [
                      BoxShadow(
                        color: (isNightMode ? const Color(0xFF991B1B) : const Color(0xFF2563EB))
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      now.minute.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(
                        fontSize: fontSz,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Yellow Circle for Second
                Container(
                  width: size * 0.78,
                  height: size * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNightMode ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                    boxShadow: [
                      BoxShadow(
                        color: (isNightMode ? const Color(0xFFDC2626) : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      now.second.toString().padLeft(2, '0'),
                      style: GoogleFonts.inter(
                        fontSize: fontSz * 0.68,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RE-ADDED FAN FAVORITE 3: LUMINOUS WIREFRAME // VECTOR TUBE
// Electric cyan outline typography, diagonal 0-cut, and active ion discharge
// =============================================================================
class _NeonWireframeFace extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final bool isMobile;

  const _NeonWireframeFace({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    int hour = now.hour;
    if (!is24Hour) {
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    final timeStr = '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final neon = isNightMode ? const Color(0xFFEF4444) : const Color(0xFF00E5FF);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LUMINOUS WIREFRAME // VECTOR TUBE',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.2,
              color: neon.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.orbitron(
                    fontSize: isMobile ? 86 : 146,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3.5
                      ..color = neon,
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.orbitron(
                    fontSize: isMobile ? 86 : 146,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: neon.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${now.second.toString().padLeft(2, '0')} SECONDS // ACTIVE ION DISCHARGE',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: Colors.white30,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INSPIRATION 1: WARM BUBBLE STANDBY CLOCK (Image 1)
// =============================================================================
class _WarmBubbleClockView extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final _DuoPalette palette;
  final String alarmTime;
  final VoidCallback onTapAlarm;
  final bool isLandscape;

  const _WarmBubbleClockView({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.palette,
    required this.alarmTime,
    required this.onTapAlarm,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final hourVal = is24Hour ? now.hour : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    final hourStr = hourVal.toString();
    final minuteStr = now.minute.toString().padLeft(2, '0');

    final nightRed = const Color(0xFFFF2A2A);
    final hourColor = isNightMode ? nightRed : palette.hourColor;
    final minColor = isNightMode ? nightRed.withValues(alpha: 0.8) : palette.minuteColor;
    final colonColor = isNightMode ? nightRed : palette.colonColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final fontSize = isLandscape
            ? (availableHeight * 0.58).clamp(90.0, 320.0)
            : (availableWidth * 0.40).clamp(70.0, 180.0);

        final dotSize = fontSize * 0.14;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    hourStr,
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      color: hourColor,
                      letterSpacing: -2.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: fontSize * 0.05),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colonColor,
                          ),
                        ),
                        SizedBox(height: fontSize * 0.16),
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colonColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    minuteStr,
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      color: minColor,
                      letterSpacing: -2.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: fontSize * 0.06),
              GestureDetector(
                onTap: onTapAlarm,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNightMode ? nightRed.withValues(alpha: 0.3) : Colors.white12,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alarm_rounded,
                          size: 16,
                          color: isNightMode ? nightRed : const Color(0xFFFF9800),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alarmTime,
                          style: GoogleFonts.fredoka(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isNightMode ? nightRed : Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// INSPIRATION 2: GZESTHETICS ARCHITECTURAL MONOCHROME (Image 2)
// =============================================================================
class _GzestheticsMonoClockView extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final bool isLandscape;

  const _GzestheticsMonoClockView({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final hourVal = is24Hour ? now.hour : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    final hourStr = hourVal.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    final nightRed = const Color(0xFFFF2A2A);
    final textColor = isNightMode ? nightRed : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final fontSize = isLandscape
            ? (availableHeight * 0.65).clamp(100.0, 360.0)
            : (availableWidth * 0.44).clamp(80.0, 220.0);

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: fontSize * 0.08, right: fontSize * 0.04),
                child: Text(
                  period,
                  style: GoogleFonts.inter(
                    fontSize: fontSize * 0.09,
                    fontWeight: FontWeight.w900,
                    color: textColor.withValues(alpha: 0.75),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                hourStr,
                style: GoogleFonts.bebasNeue(
                  fontSize: fontSize,
                  height: 0.90,
                  color: textColor,
                  letterSpacing: 4.0,
                ),
              ),
              SizedBox(width: fontSize * 0.09),
              Text(
                minuteStr,
                style: GoogleFonts.bebasNeue(
                  fontSize: fontSize,
                  height: 0.90,
                  color: textColor,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// INSPIRATION 3: 7-SEGMENT DIGITAL CLOCK WITH TELEMETRY (Image 3)
// =============================================================================
class _SegmentTelemetryClockView extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final bool isLandscape;

  const _SegmentTelemetryClockView({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final hourVal = is24Hour ? now.hour : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    final hourStr = hourVal.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    const temp = '24';
    const hum = '55';
    final dateStr = '${now.month}/${now.day}';

    final nightRed = const Color(0xFFFF2A2A);
    final litColor = isNightMode ? nightRed : Colors.white;
    final unlitColor = isNightMode ? const Color(0xFF3B0000) : const Color(0xFF141414);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final digitHeight = isLandscape
            ? (availableHeight * 0.50).clamp(80.0, 240.0)
            : (availableWidth * 0.28).clamp(50.0, 140.0);
        final digitWidth = digitHeight * 0.52;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: digitWidth * 0.25, bottom: digitHeight * 0.4),
                  child: Text(
                    period,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: digitHeight * 0.16,
                      fontWeight: FontWeight.w700,
                      color: litColor.withValues(alpha: 0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _SevenSegmentDigit(value: int.parse(hourStr[0]), width: digitWidth, height: digitHeight, litColor: litColor, unlitColor: unlitColor),
                SizedBox(width: digitWidth * 0.15),
                _SevenSegmentDigit(value: int.parse(hourStr[1]), width: digitWidth, height: digitHeight, litColor: litColor, unlitColor: unlitColor),
                SizedBox(width: digitWidth * 0.18),
                _SegmentColon(height: digitHeight, litColor: litColor),
                SizedBox(width: digitWidth * 0.18),
                _SevenSegmentDigit(value: int.parse(minuteStr[0]), width: digitWidth, height: digitHeight, litColor: litColor, unlitColor: unlitColor),
                SizedBox(width: digitWidth * 0.15),
                _SevenSegmentDigit(value: int.parse(minuteStr[1]), width: digitWidth, height: digitHeight, litColor: litColor, unlitColor: unlitColor),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: digitWidth * 0.45),
                  child: Container(
                    width: 2.0,
                    height: digitHeight * 0.88,
                    color: isNightMode ? nightRed.withValues(alpha: 0.4) : Colors.white24,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TelemetryMetricRow(value: '$temp°C', label: 'TEMP', fontSize: digitHeight * 0.24, litColor: litColor),
                    SizedBox(height: digitHeight * 0.08),
                    _TelemetryMetricRow(value: '$hum%', label: 'HUM', fontSize: digitHeight * 0.24, litColor: litColor),
                    SizedBox(height: digitHeight * 0.08),
                    _TelemetryMetricRow(value: dateStr, label: 'DATE', fontSize: digitHeight * 0.24, litColor: litColor),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TelemetryMetricRow extends StatelessWidget {
  final String value;
  final String label;
  final double fontSize;
  final Color litColor;

  const _TelemetryMetricRow({
    required this.value,
    required this.label,
    required this.fontSize,
    required this.litColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: litColor,
            height: 1.0,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize * 0.40,
            fontWeight: FontWeight.w600,
            color: litColor.withValues(alpha: 0.55),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SevenSegmentDigit extends StatelessWidget {
  final int value;
  final double width;
  final double height;
  final Color litColor;
  final Color unlitColor;

  const _SevenSegmentDigit({
    required this.value,
    required this.width,
    required this.height,
    required this.litColor,
    required this.unlitColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SevenSegmentPainter(
        value: value,
        litColor: litColor,
        unlitColor: unlitColor,
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  final int value;
  final Color litColor;
  final Color unlitColor;

  _SevenSegmentPainter({
    required this.value,
    required this.litColor,
    required this.unlitColor,
  });

  static const Map<int, List<bool>> _segments = {
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final active = _segments[value] ?? _segments[8]!;
    final w = size.width;
    final h = size.height;
    final t = w * 0.18;

    _drawHorizontalSegment(canvas, 0, 0, w, t, active[0]);
    _drawVerticalSegment(canvas, w - t, t, t, (h / 2) - t, active[1]);
    _drawVerticalSegment(canvas, w - t, h / 2, t, (h / 2) - t, active[2]);
    _drawHorizontalSegment(canvas, 0, h - t, w, t, active[3]);
    _drawVerticalSegment(canvas, 0, h / 2, t, (h / 2) - t, active[4]);
    _drawVerticalSegment(canvas, 0, t, t, (h / 2) - t, active[5]);
    _drawHorizontalSegment(canvas, 0, (h / 2) - (t / 2), w, t, active[6]);
  }

  void _drawHorizontalSegment(Canvas canvas, double x, double y, double w, double t, bool isLit) {
    final paint = Paint()
      ..color = isLit ? litColor : unlitColor
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 2, y, w - 4, t),
      Radius.circular(t * 0.28),
    );
    canvas.drawRRect(rect, paint);
  }

  void _drawVerticalSegment(Canvas canvas, double x, double y, double t, double len, bool isLit) {
    final paint = Paint()
      ..color = isLit ? litColor : unlitColor
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y + 2, t, len - 4),
      Radius.circular(t * 0.28),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.litColor != litColor ||
      oldDelegate.unlitColor != unlitColor;
}

class _SegmentColon extends StatelessWidget {
  final double height;
  final Color litColor;

  const _SegmentColon({required this.height, required this.litColor});

  @override
  Widget build(BuildContext context) {
    final size = height * 0.08;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: litColor,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
        ),
        SizedBox(height: height * 0.24),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: litColor,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// INSPIRATION 4: APPLE STANDBY NEON DUO (Image 4)
// =============================================================================
class _NeonDuoClockView extends StatelessWidget {
  final DateTime now;
  final bool is24Hour;
  final bool isNightMode;
  final _DuoPalette palette;
  final bool isLandscape;

  const _NeonDuoClockView({
    required this.now,
    required this.is24Hour,
    required this.isNightMode,
    required this.palette,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final hourVal = is24Hour ? now.hour : (now.hour % 12 == 0 ? 12 : now.hour % 12);
    final hourStr = hourVal.toString();
    final minuteStr = now.minute.toString().padLeft(2, '0');

    final nightRed = const Color(0xFFFF2A2A);
    final hourColor = isNightMode ? nightRed : const Color(0xFFFF2D75);
    final minColor = isNightMode ? nightRed.withValues(alpha: 0.8) : const Color(0xFF7C4DFF);
    final colonColor = isNightMode ? nightRed : const Color(0xFFE1BEE7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final fontSize = isLandscape
            ? (availableHeight * 0.68).clamp(110.0, 380.0)
            : (availableWidth * 0.46).clamp(85.0, 240.0);

        final dotSize = fontSize * 0.13;

        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                hourStr,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  color: hourColor,
                  letterSpacing: -2.0,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: fontSize * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colonColor),
                    ),
                    SizedBox(height: fontSize * 0.18),
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colonColor),
                    ),
                  ],
                ),
              ),
              Text(
                minuteStr,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  color: minColor,
                  letterSpacing: -2.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// INSPIRATION 5: APPLE STANDBY DUAL-WIDGET (Image 5)
// =============================================================================
class _DualWidgetClockView extends StatelessWidget {
  final DateTime now;
  final bool isNightMode;
  final bool showSeconds;
  final bool isLandscape;

  const _DualWidgetClockView({
    required this.now,
    required this.isNightMode,
    required this.showSeconds,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (isLandscape) {
          final widgetSize = (min(w / 2.2, h * 0.85)).clamp(180.0, 360.0);

          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: widgetSize,
                  height: widgetSize,
                  child: _AppleAnalogClockWidget(
                    now: now,
                    isNightMode: isNightMode,
                    showSeconds: showSeconds,
                    size: widgetSize,
                  ),
                ),
                SizedBox(
                  width: widgetSize,
                  height: widgetSize,
                  child: _AppleCalendarWidget(
                    now: now,
                    isNightMode: isNightMode,
                    size: widgetSize,
                  ),
                ),
              ],
            ),
          );
        } else {
          final widgetSize = (min(w * 0.85, h / 2.3)).clamp(160.0, 300.0);

          return Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: widgetSize,
                    height: widgetSize,
                    child: _AppleAnalogClockWidget(
                      now: now,
                      isNightMode: isNightMode,
                      showSeconds: showSeconds,
                      size: widgetSize,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: widgetSize,
                    height: widgetSize,
                    child: _AppleCalendarWidget(
                      now: now,
                      isNightMode: isNightMode,
                      size: widgetSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class _AppleAnalogClockWidget extends StatelessWidget {
  final DateTime now;
  final bool isNightMode;
  final bool showSeconds;
  final double size;

  const _AppleAnalogClockWidget({
    required this.now,
    required this.isNightMode,
    required this.showSeconds,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppleAnalogDialPainter(
        now: now,
        isNightMode: isNightMode,
        showSeconds: showSeconds,
      ),
    );
  }
}

class _AppleAnalogDialPainter extends CustomPainter {
  final DateTime now;
  final bool isNightMode;
  final bool showSeconds;

  _AppleAnalogDialPainter({
    required this.now,
    required this.isNightMode,
    required this.showSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final nightRed = const Color(0xFFFF2A2A);
    final accentOrange = isNightMode ? nightRed : const Color(0xFFFF6A00);
    final dialColor = isNightMode ? nightRed : Colors.white;

    final tickPaint = Paint()
      ..color = dialColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final majorTickPaint = Paint()
      ..color = dialColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * pi / 180;
      final isMajor = i % 5 == 0;
      final tickLen = isMajor ? radius * 0.08 : radius * 0.04;
      final p1 = Offset(
        center.dx + (radius * 0.94 - tickLen) * cos(angle),
        center.dy + (radius * 0.94 - tickLen) * sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius * 0.94) * cos(angle),
        center.dy + (radius * 0.94) * sin(angle),
      );
      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final numberRadius = radius * 0.72;

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final pos = Offset(
        center.dx + numberRadius * cos(angle),
        center.dy + numberRadius * sin(angle),
      );

      textPainter.text = TextSpan(
        text: i.toString(),
        style: GoogleFonts.inter(
          fontSize: radius * 0.165,
          fontWeight: FontWeight.w700,
          color: dialColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)),
      );
    }

    final secondFraction = now.millisecond / 1000.0;
    final secondAngle = ((now.second + secondFraction) * 6 - 90) * pi / 180;
    final minuteAngle = ((now.minute + (now.second / 60)) * 6 - 90) * pi / 180;
    final hourAngle = (((now.hour % 12) + (now.minute / 60)) * 30 - 90) * pi / 180;

    final hourPaint = Paint()
      ..color = dialColor
      ..strokeWidth = radius * 0.055
      ..strokeCap = StrokeCap.round;
    final hourEnd = Offset(
      center.dx + (radius * 0.50) * cos(hourAngle),
      center.dy + (radius * 0.50) * sin(hourAngle),
    );
    canvas.drawLine(center, hourEnd, hourPaint);

    final minPaint = Paint()
      ..color = dialColor
      ..strokeWidth = radius * 0.042
      ..strokeCap = StrokeCap.round;
    final minEnd = Offset(
      center.dx + (radius * 0.76) * cos(minuteAngle),
      center.dy + (radius * 0.76) * sin(minuteAngle),
    );
    canvas.drawLine(center, minEnd, minPaint);

    if (showSeconds) {
      final secPaint = Paint()
        ..color = accentOrange
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final secEnd = Offset(
        center.dx + (radius * 0.88) * cos(secondAngle),
        center.dy + (radius * 0.88) * sin(secondAngle),
      );
      final secTail = Offset(
        center.dx - (radius * 0.18) * cos(secondAngle),
        center.dy - (radius * 0.18) * sin(secondAngle),
      );
      canvas.drawLine(secTail, secEnd, secPaint);

      final centerPaint = Paint()..color = accentOrange;
      canvas.drawCircle(center, radius * 0.045, centerPaint);
      canvas.drawCircle(center, radius * 0.02, Paint()..color = Colors.black);
    } else {
      canvas.drawCircle(center, radius * 0.035, Paint()..color = dialColor);
    }
  }

  @override
  bool shouldRepaint(covariant _AppleAnalogDialPainter oldDelegate) => true;
}

class _AppleCalendarWidget extends StatelessWidget {
  final DateTime now;
  final bool isNightMode;
  final double size;

  const _AppleCalendarWidget({
    required this.now,
    required this.isNightMode,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(now).toUpperCase();
    final nightRed = const Color(0xFFFF2A2A);
    final headerRed = isNightMode ? nightRed : const Color(0xFFFF453A);
    final textColor = isNightMode ? nightRed : Colors.white;

    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Padding(
      padding: EdgeInsets.all(size * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            monthName,
            style: GoogleFonts.inter(
              fontSize: size * 0.09,
              fontWeight: FontWeight.w900,
              color: headerRed,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: size * 0.11,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: size * 0.055,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.15,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final dayNum = index - startingWeekday + 1;
                final isValidDay = dayNum >= 1 && dayNum <= daysInMonth;
                final isToday = isValidDay && dayNum == now.day;

                if (!isValidDay) {
                  return const SizedBox.shrink();
                }

                if (isToday) {
                  return Center(
                    child: Container(
                      width: size * 0.095,
                      height: size * 0.095,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: headerRed,
                        boxShadow: [
                          BoxShadow(
                            color: headerRed.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          dayNum.toString(),
                          style: GoogleFonts.inter(
                            fontSize: size * 0.055,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: Text(
                    dayNum.toString(),
                    style: GoogleFonts.inter(
                      fontSize: size * 0.055,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Duo Palette
class _DuoPalette {
  final String name;
  final Color hourColor;
  final Color minuteColor;
  final Color colonColor;

  const _DuoPalette({
    required this.name,
    required this.hourColor,
    required this.minuteColor,
    required this.colonColor,
  });
}

class _IconButtonPill extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final Color? activeColor;
  final VoidCallback onTap;

  const _IconButtonPill({
    this.icon,
    this.label,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: activeColor != null
                ? activeColor!.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activeColor != null
                  ? activeColor!.withValues(alpha: 0.50)
                  : Colors.white12,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: activeColor ?? Colors.white,
                ),
              if (icon != null && label != null) const SizedBox(width: 5),
              if (label != null)
                Text(
                  label!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activeColor ?? Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? Border.all(color: Colors.white24, width: 0.8)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
                if (isSelected) const SizedBox(width: 5),
                if (isSelected)
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
