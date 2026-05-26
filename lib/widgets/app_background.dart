import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fundo decorativo que representa "vida equilibrada + execução de tarefas".
///
/// Elementos visuais:
///  • Orbes coloridas suaves (as 10 áreas da vida)
///  • Anéis de equilíbrio ao centro (metáfora da balança)
///  • Curvas de fluxo (jornada / progresso)
///  • Grid de partículas (energia / foco)
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const AppBackground({super.key, required this.child, this.showOrbs = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // ── Gradiente de fundo ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF07071A),
                      Color(0xFF0C0C25),
                      Color(0xFF0A0A1F),
                    ]
                  : const [
                      Color(0xFFF2F2FF),
                      Color(0xFFEAEAFF),
                      Color(0xFFF5F5FF),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // ── Pintura decorativa ───────────────────────────────────────────
        if (showOrbs)
          RepaintBoundary(
            child: CustomPaint(
              painter: _BalanceBackgroundPainter(isDark: isDark),
              child: const SizedBox.expand(),
            ),
          ),

        // ── Conteúdo ─────────────────────────────────────────────────────
        child,
      ],
    );
  }
}

class _BalanceBackgroundPainter extends CustomPainter {
  final bool isDark;
  const _BalanceBackgroundPainter({required this.isDark});

  @override
  bool shouldRepaint(_BalanceBackgroundPainter old) => old.isDark != isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Orbes das áreas da vida ──────────────────────────────────────────
    final orbData = [
      // (dx, dy, radius, color)
      (0.0, 0.0, w * 0.55, AppTheme.areaColors[0]),   // Saúde Física - vermelho
      (w, 0.0, w * 0.45, AppTheme.areaColors[4]),       // Relacionamentos - rosa
      (0.0, h, w * 0.50, AppTheme.areaColors[3]),        // Finanças - verde
      (w, h, w * 0.48, AppTheme.areaColors[6]),           // Intelectual - ciano
      (w * 0.5, h * 0.4, w * 0.35, AppTheme.areaColors[7]), // Espiritualidade - dourado
    ];

    final orbAlpha = isDark ? 0.10 : 0.08;
    for (final (cx, cy, r, color) in orbData) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(orbAlpha),
            color.withOpacity(orbAlpha * 0.3),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, cy),
          radius: r,
        ))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // ── Anéis de equilíbrio (centro da tela) ────────────────────────────
    final cx = w * 0.5;
    final cy = h * 0.38;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 4; i++) {
      final radius = w * 0.12 * i;
      ringPaint.color = AppTheme.primary.withOpacity(0.04 - i * 0.006);
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }

    // Anel principal mais nítido
    ringPaint
      ..color = AppTheme.primary.withOpacity(0.10)
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), w * 0.18, ringPaint);

    // Cruz interna da balança (horizontal + vertical)
    final linePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.07)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(cx - w * 0.18, cy),
      Offset(cx + w * 0.18, cy),
      linePaint,
    );
    canvas.drawLine(
      Offset(cx, cy - w * 0.18),
      Offset(cx, cy + w * 0.18),
      linePaint,
    );

    // ── Curvas de fluxo (jornada / progresso) ───────────────────────────
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    // Curva 1: sweeping arc (inferior → superior)
    curvePaint.color = AppTheme.areaColors[1].withOpacity(0.08);
    final path1 = Path()
      ..moveTo(0, h * 0.75)
      ..cubicTo(w * 0.3, h * 0.6, w * 0.7, h * 0.3, w, h * 0.15);
    canvas.drawPath(path1, curvePaint);

    // Curva 2: gentle S
    curvePaint.color = AppTheme.areaColors[5].withOpacity(0.07);
    final path2 = Path()
      ..moveTo(0, h * 0.4)
      ..cubicTo(w * 0.25, h * 0.55, w * 0.75, h * 0.25, w, h * 0.45);
    canvas.drawPath(path2, curvePaint);

    // Curva 3: upward sweep
    curvePaint.color = AppTheme.areaColors[9].withOpacity(0.06);
    final path3 = Path()
      ..moveTo(w * 0.2, h)
      ..cubicTo(w * 0.4, h * 0.7, w * 0.6, h * 0.5, w * 0.9, h * 0.2);
    canvas.drawPath(path3, curvePaint);

    // ── Partículas (grid de pontos) ──────────────────────────────────────
    final dotPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.04)
          : AppTheme.primary.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 38.0;
    final cols = (w / spacing).ceil();
    final rows = (h / spacing).ceil();

    final rng = math.Random(42); // semente fixa → sempre igual
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (rng.nextDouble() > 0.35) continue; // ~65% dos pontos são invisíveis
        final px = c * spacing + rng.nextDouble() * 10 - 5;
        final py = r * spacing + rng.nextDouble() * 10 - 5;
        final radius = rng.nextDouble() * 1.2 + 0.4;
        canvas.drawCircle(Offset(px, py), radius, dotPaint);
      }
    }

    // ── Estrelas brilhantes (pontos maiores, aleatórios) ─────────────────
    final starPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.12)
          : AppTheme.primary.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final starPositions = [
      (w * 0.15, h * 0.08),
      (w * 0.82, h * 0.05),
      (w * 0.45, h * 0.12),
      (w * 0.68, h * 0.22),
      (w * 0.08, h * 0.35),
      (w * 0.93, h * 0.45),
      (w * 0.30, h * 0.65),
      (w * 0.75, h * 0.72),
      (w * 0.55, h * 0.88),
      (w * 0.12, h * 0.92),
    ];
    for (final (sx, sy) in starPositions) {
      canvas.drawCircle(Offset(sx, sy), 1.4, starPaint);
    }
  }

}

/// Fundo dedicado para a tela de login — mais imersivo
class LoginBackground extends StatelessWidget {
  final Widget child;
  const LoginBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      Color(0xFF06061A),
                      Color(0xFF0D0D2B),
                      Color(0xFF0A0A20),
                    ]
                  : const [
                      Color(0xFFF0F0FF),
                      Color(0xFFE8E8FF),
                      Color(0xFFF0F0FF),
                    ],
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _LoginBackgroundPainter(isDark: isDark),
            child: const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  final bool isDark;
  const _LoginBackgroundPainter({required this.isDark});

  @override
  bool shouldRepaint(_LoginBackgroundPainter old) => old.isDark != isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grande orbe superior central (logo area)
    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.18),
          AppTheme.primary.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.22),
        radius: w * 0.6,
      ));
    canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.6, topGlow);

    // Orbe inferior (acento)
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accent.withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.95),
        radius: w * 0.5,
      ));
    canvas.drawCircle(Offset(w * 0.5, h * 0.95), w * 0.5, bottomGlow);

    // Anéis concêntricos no topo
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (int i = 1; i <= 5; i++) {
      ringPaint.color = AppTheme.primary.withOpacity(0.06 - i * 0.008);
      canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.15 * i, ringPaint);
    }

    // Partículas
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark
          ? Colors.white.withOpacity(0.05)
          : AppTheme.primary.withOpacity(0.06);
    final rng = math.Random(99);
    for (int i = 0; i < 60; i++) {
      final px = rng.nextDouble() * w;
      final py = rng.nextDouble() * h;
      final r = rng.nextDouble() * 1.5 + 0.3;
      canvas.drawCircle(Offset(px, py), r, dotPaint);
    }
  }
}

/// Widget de card glassmorphism reutilizável
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? tintColor;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.opacity = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white)
                .withOpacity(isDark ? opacity : 0.60),
            borderRadius: br,
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : AppTheme.primary.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
