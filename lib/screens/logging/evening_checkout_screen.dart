import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/activities_provider.dart';
import '../../theme/app_theme.dart';

class EveningCheckoutScreen extends StatefulWidget {
  const EveningCheckoutScreen({super.key});

  @override
  State<EveningCheckoutScreen> createState() => _EveningCheckoutScreenState();
}

class _EveningCheckoutScreenState extends State<EveningCheckoutScreen> {
  int _dayScore = 7;
  final _reflectionController = TextEditingController();
  final _tomorrowController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reflectionController.dispose();
    _tomorrowController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final user = context.read<UserProvider>().user!;
    final activitiesProvider = context.read<ActivitiesProvider>();

    await activitiesProvider.saveEveningCheckIn(
      userId: user.id,
      reflection: _reflectionController.text.trim(),
      tomorrowPlan: _tomorrowController.text.trim(),
      dayScore: _dayScore,
    );

    await context.read<UserProvider>().addXP(10);

    final eveningCount = activitiesProvider.eveningCheckInsCount;
    await context.read<UserProvider>().checkEveningCheckInsAchievement(eveningCount);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌙 Check-out noturno salvo! +10 XP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌙 Check-out Noturno'),
        leading: const CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como foi seu dia?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nota do dia',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1', style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _dayScore.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _dayScore.toString(),
                    onChanged: (v) => setState(() => _dayScore = v.round()),
                  ),
                ),
                const Text('10', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_dayScore',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'O que aprendi hoje?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reflectionController,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Reflexão do dia...',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Plano para amanhã',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tomorrowController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Amanhã quero...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('Finalizar dia'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
