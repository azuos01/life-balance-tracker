import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String? _loadingProvider;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic ────────────────────────────────────────────────────────────

  Future<void> _signIn(String provider) async {
    setState(() => _loadingProvider = provider);
    try {
      AuthResult? result;
      switch (provider) {
        case 'google':
          result = await AuthService.instance.signInWithGoogle();
          break;
        case 'github':
          result = await AuthService.instance.signInWithGitHub();
          break;
        case 'facebook':
          result = await AuthService.instance.signInWithFacebook();
          break;
        case 'linkedin':
          await AuthService.instance.signInWithLinkedIn();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('🔗 Autorize no LinkedIn e volte para o app'),
              duration: Duration(seconds: 6),
            ));
          }
          return;
        case 'demo':
          await _enterDemoMode();
          return;
      }
      if (result != null && mounted) {
        await context.read<UserProvider>().onAuthResult(result);
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().contains('popup-closed')
            ? 'Login cancelado.'
            : e.toString().contains('not-configured') ||
                    e.toString().contains('YOUR_')
                ? 'Firebase não configurado. Use Modo Demo para testar.'
                : 'Erro: ${e.toString().replaceAll('Exception: ', '')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Future<void> _enterDemoMode() async {
    final result = AuthResult(
      uid: 'demo_user',
      name: 'Usuário Demo',
      email: 'demo@lifebalance.app',
      provider: 'demo',
    );
    if (mounted) await context.read<UserProvider>().onAuthResult(result);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: LoginBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: math.max(size.height, 680),
              child: Column(
                children: [
                  // ── Hero section (50%) ─────────────────────────────────
                  Expanded(
                    flex: 5,
                    child: _HeroSection(pulseAnim: _pulseAnim),
                  ),

                  // ── Login card (50%) ───────────────────────────────────
                  Expanded(
                    flex: 6,
                    child: _LoginCard(
                      loadingProvider: _loadingProvider,
                      onSignIn: _signIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _HeroSection({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo animado
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: pulseAnim.value,
            child: _BalanceLogo(),
          ),
        ),
        SizedBox(height: 20),
        // Título
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            'Life Balance',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Text(
          'T R A C K E R',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: AppTheme.textSecondary,
            letterSpacing: 6,
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Execute o que importa.\nViva uma vida equilibrada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Balance Logo (CustomPaint) ─────────────────────────────────────────────────

class _BalanceLogo extends StatelessWidget {
  const _BalanceLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Glow externo
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.4),
          AppTheme.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, glowPaint);

    // Anel externo
    final ringOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.primary.withOpacity(0.6);
    canvas.drawCircle(Offset(cx, cy), r * 0.82, ringOuter);

    // Anel interno
    final ringInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.primaryLight.withOpacity(0.35);
    canvas.drawCircle(Offset(cx, cy), r * 0.60, ringInner);

    // Símbolo ⚖️ simplificado — haste central
    final linePaint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Haste vertical
    canvas.drawLine(
      Offset(cx, cy - r * 0.35),
      Offset(cx, cy + r * 0.40),
      linePaint,
    );
    // Barra horizontal
    canvas.drawLine(
      Offset(cx - r * 0.32, cy - r * 0.28),
      Offset(cx + r * 0.32, cy - r * 0.28),
      linePaint,
    );
    // Prato esquerdo
    final platePaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - r * 0.32, cy - r * 0.12),
        width: r * 0.36,
        height: r * 0.14,
      ),
      0,
      math.pi,
      false,
      platePaint..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.accent,
    );
    // Linha prato esquerdo
    canvas.drawLine(
      Offset(cx - r * 0.32, cy - r * 0.28),
      Offset(cx - r * 0.32, cy - r * 0.12),
      linePaint..color = AppTheme.primaryLight.withOpacity(0.7)..strokeWidth = 1.2,
    );
    // Prato direito
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + r * 0.32, cy - r * 0.12),
        width: r * 0.36,
        height: r * 0.14,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.primaryLight,
    );
    canvas.drawLine(
      Offset(cx + r * 0.32, cy - r * 0.28),
      Offset(cx + r * 0.32, cy - r * 0.12),
      Paint()
        ..color = AppTheme.primaryLight.withOpacity(0.7)
        ..strokeWidth = 1.2,
    );

    // Ponto central
    final dotPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + r * 0.40), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

// ── Login Card ─────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final String? loadingProvider;
  final void Function(String) onSignIn;

  _LoginCard({
    required this.loadingProvider,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassCard(
        opacity: 0.08,
        borderRadius: BorderRadius.circular(28),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrar na sua conta',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Seus dados sincronizados em qualquer dispositivo',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Google
            _ProviderButton(
              label: 'Continuar com Google',
              icon: _GoogleIcon(),
              color: const Color(0xFF4285F4),
              isLoading: loadingProvider == 'google',
              onTap: () => onSignIn('google'),
            ),
            const SizedBox(height: 10),

            // GitHub
            _ProviderButton(
              label: 'Continuar com GitHub',
              icon: _GitHubIcon(),
              color: const Color(0xFF2D333B),
              isLoading: loadingProvider == 'github',
              onTap: () => onSignIn('github'),
            ),
            const SizedBox(height: 10),

            // LinkedIn + Facebook em linha
            Row(
              children: [
                Expanded(
                  child: _ProviderButton(
                    label: 'LinkedIn',
                    icon: _LinkedInIcon(),
                    color: const Color(0xFF0A66C2),
                    isLoading: loadingProvider == 'linkedin',
                    onTap: () => onSignIn('linkedin'),
                    compact: true,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _ProviderButton(
                    label: 'Facebook',
                    icon: _FacebookIcon(),
                    color: Color(0xFF1877F2),
                    isLoading: loadingProvider == 'facebook',
                    onTap: () => onSignIn('facebook'),
                    compact: true,
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withOpacity(0.1),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou explore sem cadastro',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withOpacity(0.1),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Demo mode
            GestureDetector(
              onTap: loadingProvider != null ? null : () => onSignIn('demo'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.06),
                      AppTheme.primary.withOpacity(0.02),
                    ],
                  ),
                ),
                child: loadingProvider == 'demo'
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(AppTheme.primary),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎮', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Modo Demo — explorar sem cadastro',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            SizedBox(height: 12),
            Center(
              child: Text(
                'Ao entrar você concorda com os Termos de Uso.',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Provider Button ───────────────────────────────────────────────────────────

class _ProviderButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  final bool compact;

  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 11 : 13,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!compact) ...[
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.white54),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Icons ─────────────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: const Center(
          child: Text('G',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4285F4))),
        ),
      );
}

class _GitHubIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Center(
          child: Text('🐙', style: TextStyle(fontSize: 13)),
        ),
      );
}

class _LinkedInIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(3)),
        child: const Center(
          child: Text('in',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A66C2))),
        ),
      );
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Center(
          child: Text('f',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1877F2))),
        ),
      );
}