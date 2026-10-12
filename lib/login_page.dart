import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'standby_home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Mode & Flags
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToStandbyApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_get_started', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 950),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StandbyHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToStandbyApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. ARCHITECTURAL TECH GRID
          const Positioned.fill(
            child: CustomPaint(
              painter: TechGridBackgroundPainter(),
            ),
          ),

          // 2. AMBIENT SAPPHIRE EDGE-LIT GLOW
          const Positioned.fill(
            child: IgnorePointer(
              child: AmbientEdgeGlow(),
            ),
          ),

          // 3. FLOWING DARK BLUE WAVE (Bottom 40%)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 26.0,
                sigmaY: 26.0,
                tileMode: TileMode.decal,
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: Bottom40FlowingWavePainter(
                      progress: _waveController.value,
                    ),
                    size: Size(size.width, size.height * 0.40),
                  );
                },
              ),
            ),
          ),

          // 4. TOP BAR WITH FROSTED BACK BUTTON & STANDBY BRAND
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Frosted glass back button
                  _FrostedIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  // Standby brand mark in DxFiggle — Hero receives title from landing page
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'standby-title',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            'Standby',
                            style: const TextStyle(
                              fontFamily: 'DxFiggle',
                              fontSize: 26,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // 5. CENTERED GLASSMORPHIC AUTHENTICATION CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 76),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? size.width * 0.92 : 440,
                ),
                child: _AuthCard(
                  isSignUp: _isSignUp,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  rememberMe: _rememberMe,
                  agreeTerms: _agreeTerms,
                  isLoading: _isLoading,
                  onToggleMode: (signUp) {
                    setState(() => _isSignUp = signUp);
                  },
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onToggleConfirmObscure: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  onToggleRemember: (val) {
                    setState(() => _rememberMe = val ?? false);
                  },
                  onToggleAgreeTerms: (val) {
                    setState(() => _agreeTerms = val ?? false);
                  },
                  onSubmit: _handleSubmit,
                  onContinueAsGuest: _navigateToStandbyApp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted circular icon button
class _FrostedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_FrostedIconButton> createState() => _FrostedIconButtonState();
}

class _FrostedIconButtonState extends State<_FrostedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: _isHovered ? 0.14 : 0.07),
              border: Border.all(
                color: Colors.white.withValues(alpha: _isHovered ? 0.35 : 0.16),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.90),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Main Glassmorphic Auth Card (Supports both Sign In and Sign Up)
class _AuthCard extends StatelessWidget {
  final bool isSignUp;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool rememberMe;
  final bool agreeTerms;
  final bool isLoading;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleConfirmObscure;
  final ValueChanged<bool?> onToggleRemember;
  final ValueChanged<bool?> onToggleAgreeTerms;
  final VoidCallback onSubmit;
  final VoidCallback onContinueAsGuest;

  const _AuthCard({
    required this.isSignUp,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.rememberMe,
    required this.agreeTerms,
    required this.isLoading,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onToggleConfirmObscure,
    required this.onToggleRemember,
    required this.onToggleAgreeTerms,
    required this.onSubmit,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'auth-card',
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        // Specular ambient rim border
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          // Deep ground shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          // Sapphire ambient bounce
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // Frosted dark glass body
              color: const Color(0xFF0F1015).withValues(alpha: 0.84),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top crescent grip highlight
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Frosted Segmented Tab Switcher: [ Sign In ]  [ Create Account ]
                _SegmentedAuthTab(
                  isSignUp: isSignUp,
                  onSelect: onToggleMode,
                ),
                const SizedBox(height: 24),

                // Animated Header (Title & Subtitle with silky slide + fade)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 480),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey<bool>(isSignUp),
                    children: [
                      Text(
                        isSignUp ? 'Create Account' : 'Welcome Back',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isSignUp
                            ? 'Create an account to save your favorite clocks'
                            : 'Sign in to access your saved clocks',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.50),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields (Animated with smooth luxurious liquid expansion)
                AnimatedSize(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeInOutCubicEmphasized,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name (Only in Sign Up mode)
                      if (isSignUp) ...[
                        _buildFieldLabel('FULL NAME'),
                        const SizedBox(height: 8),
                        _ObsidianInputField(
                          controller: nameController,
                          hintText: 'Alex Morgan',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Address (Always visible)
                      _buildFieldLabel('EMAIL ADDRESS'),
                      const SizedBox(height: 8),
                      _ObsidianInputField(
                        controller: emailController,
                        hintText: 'name@example.com',
                        prefixIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel(isSignUp ? 'CREATE PASSWORD' : 'PASSWORD'),
                          if (!isSignUp)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Forgot?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ObsidianInputField(
                        controller: passwordController,
                        hintText: isSignUp ? 'At least 8 characters' : '••••••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          onPressed: onToggleObscure,
                        ),
                      ),

                      // Confirm Password (Only in Sign Up mode)
                      if (isSignUp) ...[
                        const SizedBox(height: 16),
                        _buildFieldLabel('CONFIRM PASSWORD'),
                        const SizedBox(height: 8),
                        _ObsidianInputField(
                          controller: confirmPasswordController,
                          hintText: 'Re-enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            onPressed: onToggleConfirmObscure,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Checkbox: Remember Me (Sign In) vs Terms (Sign Up)
                      if (!isSignUp)
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: rememberMe,
                                onChanged: onToggleRemember,
                                activeColor: const Color(0xFF2563EB),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Remember this device',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: agreeTerms,
                                onChanged: onToggleAgreeTerms,
                                activeColor: const Color(0xFF2563EB),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'I agree to the Standby Terms & Privacy Policy',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button: Dual-Layer Liquid Glass Tray Button
                _LiquidGlassSubmitButton(
                  label: isSignUp ? 'Create Standby Account' : 'Sign In to Standby',
                  isLoading: isLoading,
                  onPressed: onSubmit,
                ),
                const SizedBox(height: 22),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Social Options
                Row(
                  children: [
                    Expanded(
                      child: _SocialPillButton(
                        label: 'Apple',
                        icon: Icons.apple,
                        onTap: onContinueAsGuest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialPillButton(
                        label: 'Google',
                        icon: Icons.g_mobiledata_rounded,
                        onTap: onContinueAsGuest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Interactive Switcher Footer: "New here? Create an account" / "Already have an account? Sign in"
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onToggleMode(!isSignUp),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: isSignUp
                              ? 'Already have an account? '
                              : 'New here? ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          children: [
                            TextSpan(
                              text: isSignUp ? 'Sign in' : 'Create an account',
                              style: const TextStyle(
                                color: Color(0xFF60A5FA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Guest Access Option
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onContinueAsGuest,
                      child: Text(
                        'Continue as Guest',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                          decoration: TextDecoration.underline,
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
    ); // closes Hero
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}

/// Segmented Switcher for Sign In vs Create Account
class _SegmentedAuthTab extends StatelessWidget {
  final bool isSignUp;
  final ValueChanged<bool> onSelect;

  const _SegmentedAuthTab({
    required this.isSignUp,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF141519), // Inset obsidian track
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Stack(
        children: [
          // Animated sliding glass highlight
          AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.50,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2563EB).withValues(alpha: 0.45),
                      const Color(0xFF1E40AF).withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Two Clickable Tab Items
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(false),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSignUp ? FontWeight.w400 : FontWeight.w600,
                          color: isSignUp
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(true),
                    child: Center(
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSignUp ? FontWeight.w600 : FontWeight.w400,
                          color: isSignUp
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inset dark obsidian input field with focus glow
class _ObsidianInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;

  const _ObsidianInputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_ObsidianInputField> createState() => _ObsidianInputFieldState();
}

class _ObsidianInputFieldState extends State<_ObsidianInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF141519), // Inset matte obsidian container
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF3B82F6)
              : Colors.white.withValues(alpha: 0.09),
          width: _isFocused ? 1.2 : 1.0,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            widget.prefixIcon,
            size: 18,
            color: _isFocused
                ? const Color(0xFF60A5FA)
                : Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: widget.hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (widget.suffixIcon != null) widget.suffixIcon!,
          if (widget.suffixIcon == null) const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// Dual-Layer Liquid Glass Tray Button for Form Submission
class _LiquidGlassSubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LiquidGlassSubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_LiquidGlassSubmitButton> createState() =>
      _LiquidGlassSubmitButtonState();
}

class _LiquidGlassSubmitButtonState extends State<_LiquidGlassSubmitButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isLoading) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (!widget.isLoading) {
            setState(() => _isPressed = false);
            widget.onPressed();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              // Outer blue liquid glass body
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.50 : 0.35),
                  const Color(0xFF1E3A8A).withValues(alpha: _isHovered ? 0.60 : 0.45),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: _isHovered ? 0.90 : 0.70),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.50 : 0.30),
                  blurRadius: _isHovered ? 24 : 16,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131418), // Inset obsidian core
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: _isHovered ? 0.14 : 0.08),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isLoading ? 'Authenticating...' : widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF212328),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: Color(0xFF3B82F6),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFF60A5FA),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted Social Pill Button
class _SocialPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SocialPillButton> createState() => _SocialPillButtonState();
}

class _SocialPillButtonState extends State<_SocialPillButton> {
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
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _isHovered ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: _isHovered ? 0.22 : 0.10),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
