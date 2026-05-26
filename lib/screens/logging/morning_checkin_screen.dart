import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/activities_provider.dart';
import '../../theme/app_theme.dart';

class MorningCheckInScreen extends StatefulWidget {
  const MorningCheckInScreen({super.key});

  @override
  State<MorningCheckInScreen> createState() => _MorningCheckInScreenState();
}

class _MorningCheckInScreenState extends State<MorningCheckInScreen> {
  int _mood = 3;
  int _energy = 3;
  final _intentionController = TextEditingController();
  final _gratitudeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _intentionController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final user = context.read<UserProvider>().user!;
    final activitiesProvider = context.read<ActivitiesProvider>();

    final intentions = _intentionController.text
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    await activitiesProvider.saveMorningCheckIn(
      userId: user.id,
      mood: _mood,
      energy: _energy,
      intentions: intentions,
      gratitude: _gratitudeController.text.trim(),
    );

    await context.read<UserProvider>().addXP(10);
    await context.read<UserProvider>().updateStreak(false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Check-in matinal salvo! +10 XP'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('☀️ Check-in Matinal'),
        leading: CloseButton(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como você está hoje?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 24),
            _EmojiRatingRow(
              label: 'Humor',
              value: _mood,
              emojis: ['😔', '😕', '😐', '😊', '😄'],
              onChanged: (v) => setState(() => _mood = v),
            ),
            SizedBox(height: 20),
            _EmojiRatingRow(
              label: 'Energia',
              value: _energy,
              emojis: ['🪫', '😴', '⚡', '🔋', '⚡⚡'],
              onChanged: (v) => setState(() => _energy = v),
            ),
            SizedBox(height: 24),
            Text(
              'Intenções do dia',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _intentionController,
              maxLines: 3,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Uma intenção por linha...',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Gratidão (opcional)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _gratitudeController,
              maxLines: 2,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Hoje sou grato(a) por...',
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
                      child: const Text('Salvar Check-in'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiRatingRow extends StatelessWidget {
  final String label;
  final int value;
  final List<String> emojis;
  final ValueChanged<int> onChanged;

  _EmojiRatingRow({
    required this.label,
    required this.value,
    required this.emojis,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final selected = value == i + 1;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withOpacity(0.2)
                      : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  emojis[i],
                  style: TextStyle(fontSize: selected ? 28 : 22),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}