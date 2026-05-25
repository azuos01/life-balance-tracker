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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('⚖️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Bem-vindo ao\nLife Balance Tracker',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Monitore e melhore as 10 áreas fundamentais\nda sua vida com gamificação e insights.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Como você quer ser chamado?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Seu nome',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 32),
          const _AreaPreviewGrid(),
        ],
      ),
    );
  }
}

class _AreaPreviewGrid extends StatelessWidget {
  const _AreaPreviewGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kAreas.map((a) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${a.icon} ${a.name}',
            style: const TextStyle(
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

  const _ScoresPage({required this.scores, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Como está cada área?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
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

  const _ScoreSlider({
    required this.icon,
    required this.name,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
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
  const _GoalsPage({required this.controllers});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Defina seus objetivos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Opcional — adicione um objetivo principal por área. Você pode editar depois.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ...kAreas.map((area) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextField(
                  controller: controllers[area.id],
                  style: const TextStyle(color: AppTheme.textPrimary),
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
