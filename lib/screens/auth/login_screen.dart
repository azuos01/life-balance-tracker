import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _loadingProvider;

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
          // LinkedIn: redirect externo — retorno via URL callback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  '🔗 Autorize no LinkedIn e volte para o app'),
              duration: Duration(seconds: 6),
            ));
          }
          return;
        case 'demo':
          await _enterDemoMode();
          return;
      }
      if (result != null && mounted) {
        await context
            .read<UserProvider>()
            .onAuthResult(result);
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
    if (mounted) {
      await context.read<UserProvider>().onAuthResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                const Text('⚖️', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 12),
                const Text(
                  'Life Balance',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'Tracker',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sua jornada para o equilíbrio começa aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Social buttons ────────────────────────────────────────
                _ProviderButton(
                  provider: 'google',
                  label: 'Entrar com Google',
                  color: const Color(0xFF4285F4),
                  icon: _GoogleIcon(),
                  isLoading: _loadingProvider == 'google',
                  onTap: () => _signIn('google'),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  provider: 'github',
                  label: 'Entrar com GitHub',
                  color: const Color(0xFF24292E),
                  icon: _GitHubIcon(),
                  isLoading: _loadingProvider == 'github',
                  onTap: () => _signIn('github'),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  provider: 'linkedin',
                  label: 'Entrar com LinkedIn',
                  color: const Color(0xFF0A66C2),
                  icon: _LinkedInIcon(),
                  isLoading: _loadingProvider == 'linkedin',
                  onTap: () => _signIn('linkedin'),
                ),
                const SizedBox(height: 12),
                _ProviderButton(
                  provider: 'facebook',
                  label: 'Entrar com Facebook',
                  color: const Color(0xFF1877F2),
                  icon: _FacebookIcon(),
                  isLoading: _loadingProvider == 'facebook',
                  onTap: () => _signIn('facebook'),
                ),

                const SizedBox(height: 28),

                // ── Divider ───────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.divider)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Demo mode ─────────────────────────────────────────────
                GestureDetector(
                  onTap: _loadingProvider != null
                      ? null
                      : () => _signIn('demo'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.divider, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _loadingProvider == 'demo'
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppTheme.primary),
                              ),
                            ),
                          )
                        : const Text(
                            '🎮  Modo Demo (sem cadastro)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ao entrar, você concorda com os Termos de Uso\ne a Política de Privacidade.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.5,
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

// ─── Button widget ──────────────────────────────────────────────────────────

class _ProviderButton extends StatelessWidget {
  final String provider;
  final String label;
  final Color color;
  final Widget icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.provider,
    required this.label,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                children: [
                  icon,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Provider icons (SVG-like via CustomPaint) ───────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

class _GitHubIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '🐙',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _LinkedInIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'in',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A66C2),
          ),
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1877F2),
          ),
        ),
      ),
    );
  }
}
