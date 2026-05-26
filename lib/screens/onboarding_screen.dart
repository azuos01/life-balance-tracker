import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/areas_provider.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Page 0: welcome + name
  final _nameController = TextEditingController();

  // Page 1: scores per area (all 10)
  final Map<String, double> _scores = {
    for (final a in kAreas) a.id: 5.0,
  };

  // Page 2: first goal per area (optional)
  final Map<String, TextEditingController> _goalControllers = {
    for (final a in kAreas) a.id: TextEditingController(),
  };

  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    for (final c in _goalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira seu nome')),
      );
      return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    final userProvider = context.read<UserProvider>();
    final areasProvider = context.read<AreasProvider>();

    await userProvider.createUser(_nameController.text.trim());
    await areasProvider.updateAllScores(_scores);
    await userProvider.completeOnboarding();

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildProgress(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _WelcomePage(controller: _nameController),
                    _ScoresPage(scores: _scores, onChanged: (id, v) {
                      setState(() => _scores[id] = v);
                    }),
                    _GoalsPage(controllers: _goalControllers),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _currentPage
                    ? AppTheme.primary
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
              )
            : ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentPage == 2 ? 'Começar Jornada 🚀' : 'Continuar',
                ),
              ),
      ),
    );
  }
}

// --- Page 1: Welcome ---
class _WelcomePage extends StatelessWidget {
  final TextEditingController controller;
  const _WelcomePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // ── Logo ──────────────────────────────────────────────────────────
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text('⚖️', style: TextStyle(fontSize: 42)),
            ),
          ),
          const SizedBox(height: 18),

          // ── App name ──────────────────────────────────────────────────────
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: const Text(
              kAppName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white, // masked by ShaderMask
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(height: 10),

          // ── Version badge ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.30),
              ),
            ),
            child: Text(
              'v$kAppVersion',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 20),

          // ── Tagline ───────────────────────────────────────────────────────
          Text(
            kAppTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.55,
            ),
          ),
          SizedBox(height: 28),

          // ── Divider ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.divider, height: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Vamos começar',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.divider, height: 1)),
            ],
          ),
          SizedBox(height: 24),

          // ── Name input ────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Como você quer ser chamado?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
            ),
          ),
          SizedBox(height: 28),

          // ── Area chips ────────────────────────────────────────────────────
          _AreaPreviewGrid(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AreaPreviewGrid extends StatelessWidget {
  _AreaPreviewGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kAreas.map((a) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${a.icon} ${a.name}',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- Page 2: Scores ---
class _ScoresPage extends StatelessWidget {
  final Map<String, double> scores;
  final void Function(String id, double value) onChanged;

  _ScoresPage({required this.scores, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Como está cada área?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Avalie sua satisfação atual em cada área (1 = péssimo, 10 = excelente)',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ...kAreas.asMap().entries.map((entry) {
            final i = entry.key;
            final area = entry.value;
            final color = AppTheme.areaColors[i % AppTheme.areaColors.length];
            return _ScoreSlider(
              icon: area.icon,
              name: area.name,
              value: scores[area.id] ?? 5,
              color: color,
              onChanged: (v) => onChanged(area.id, v),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  final String icon;
  final String name;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  _ScoreSlider({
    required this.icon,
    required this.name,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              overlayColor: color.withOpacity(0.15),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page 3: Goals ---
class _GoalsPage extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  _GoalsPage({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Defina seus objetivos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Opcional — adicione um objetivo principal por área. Você pode editar depois.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 20),
          ...kAreas.map((area) => Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: TextField(
                  controller: controllers[area.id],
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '${area.icon} ${area.name}',
                    prefixText: '  ',
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}