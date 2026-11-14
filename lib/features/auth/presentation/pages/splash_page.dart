import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 앱 실행 시 저장된 세션을 확인하는 동안 브랜드 모션을 보여주는 애니메이션 스플래시 화면이다.
class SplashPage extends StatefulWidget {
  /// [SplashPage] 위젯을 생성한다.
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _loopController;

  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    // 진입 시퀀스 컨트롤러 (엠블럼 -> 타이틀 -> 서브 배지 -> 로딩 바)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    // 바퀴 회전, 펄스 링, 강변 웨이브, 쉬머 바를 구동하는 루프 컨트롤러
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _badgeScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _badgeFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.26, 0.68, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.26, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.42, 0.84, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.42, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    _loaderFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 상단 은은한 블루 글로우 배경
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFEAF3FF),
                  AppColors.background,
                  const Color(0xFFF0F5FC),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 하단 여주 남한강 물결 애니메이션 레이어
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: AnimatedBuilder(
              animation: _loopController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RiverWavePainter(progress: _loopController.value),
                );
              },
            ),
          ),

          // 중앙 브랜드 모션 및 로딩 영역
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _badgeFade,
                      child: ScaleTransition(
                        scale: _badgeScale,
                        child: _AnimatedEmblemCard(
                          loopAnimation: _loopController,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          '여주자전거여행',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'MANAGER · LICENSE & SIGN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'MiniPos 시디키 · 간편서명키 통합 관리',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _loaderFade,
                      child: Column(
                        children: [
                          _ShimmerProgressBar(loopAnimation: _loopController),
                          const SizedBox(height: 12),
                          const Text(
                            '인증 세션을 확인하고 있습니다...',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
  }
}

/// 동심원 펄스 링과 회전하는 자전거·열쇠 아이콘 카드를 그리는 위젯이다.
class _AnimatedEmblemCard extends StatelessWidget {
  const _AnimatedEmblemCard({required this.loopAnimation});

  final Animation<double> loopAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loopAnimation,
      builder: (context, _) {
        final t = loopAnimation.value;
        final floatOffset = math.sin(t * 2 * math.pi) * 3.5;

        return SizedBox(
          width: 156,
          height: 156,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(progress: t),
              _PulseRing(progress: (t + 0.5) % 1.0),
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE24A),
                        Color(0xFFFFBE0B),
                        Color(0xFFF29500),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF29500).withValues(alpha: 0.30),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CustomPaint(
                      painter: _AnimatedBikeKeyPainter(progress: t),
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

/// 아이콘 뒤에서 바깥으로 퍼져 나가는 동심원 펄스 링 위젯이다.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 0.72 + (progress * 0.56);
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.24;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: opacity),
            width: 2.0,
          ),
        ),
      ),
    );
  }
}

/// 앱 아이콘과 동일한 자전거·라이선스 키 심볼을 그리며 바퀴 회전과 열쇠 글로우를 표현하는 페인터이다.
class _AnimatedBikeKeyPainter extends CustomPainter {
  _AnimatedBikeKeyPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Offset bpt(double nx, double ny) => Offset(
          w * (0.5 + nx - 0.032),
          h * (0.5 + ny + 0.048),
        );

    Offset pt(double nx, double ny) => Offset(
          w * (0.5 + nx),
          h * (0.5 + ny),
        );

    // 하단 강변 곡선
    final wavePath = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.25, h * 0.76, w * 0.5, h * 0.81)
      ..quadraticBezierTo(w * 0.75, h * 0.86, w, h * 0.79)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wavePath,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );

    // 주행감 있는 도로 대시 라인
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    final roadY = h * 0.82;
    final shift = (progress * w * 0.40) % (w * 0.40);
    for (var i = -1; i < 4; i++) {
      final startX = i * w * 0.40 - shift + w * 0.12;
      canvas.drawLine(
        Offset(startX, roadY),
        Offset(startX + w * 0.16, roadY),
        dashPaint,
      );
    }

    // 자전거 바퀴 (회전하는 스포크 포함)
    const bikeNavy = Color(0xFF0F2342);
    final rearCenter = bpt(-0.175, 0.115);
    final frontCenter = bpt(0.165, 0.115);
    final wheelRadius = w * 0.122;
    final tirePaint = Paint()
      ..color = bikeNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030;
    final spokePaint = Paint()
      ..color = bikeNavy.withValues(alpha: 0.45)
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;

    final wheelAngle = progress * 2 * math.pi;
    for (final center in [rearCenter, frontCenter]) {
      canvas.drawCircle(center, wheelRadius, tirePaint);
      for (var s = 0; s < 3; s++) {
        final angle = wheelAngle + (s * math.pi / 3);
        final dx = math.cos(angle) * (wheelRadius * 0.78);
        final dy = math.sin(angle) * (wheelRadius * 0.78);
        canvas.drawLine(
          Offset(center.dx - dx, center.dy - dy),
          Offset(center.dx + dx, center.dy + dy),
          spokePaint,
        );
      }
      canvas.drawCircle(center, w * 0.022, Paint()..color = bikeNavy);
    }

    // 자전거 프레임
    final bb = bpt(-0.015, 0.115);
    final seatTop = bpt(-0.088, -0.072);
    final headTop = bpt(0.085, -0.062);
    final headBot = bpt(0.102, -0.020);
    final saddleL = bpt(-0.140, -0.095);
    final saddleR = bpt(-0.045, -0.095);
    final seatPostTop = bpt(-0.096, -0.095);
    final stemTop = bpt(0.072, -0.112);
    final barFwd = bpt(0.128, -0.112);
    final barDrop = bpt(0.142, -0.075);

    final framePaint = Paint()
      ..color = bikeNavy
      ..strokeWidth = w * 0.026
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rearCenter, bb, framePaint);
    canvas.drawLine(rearCenter, seatTop, framePaint);
    canvas.drawLine(bb, seatTop, framePaint);
    canvas.drawLine(bb, headBot, framePaint);
    canvas.drawLine(seatTop, headTop, framePaint);
    canvas.drawLine(headTop, headBot, framePaint);
    canvas.drawLine(headBot, frontCenter, framePaint);
    canvas.drawLine(seatTop, seatPostTop, framePaint);
    canvas.drawLine(saddleL, saddleR, framePaint);
    canvas.drawLine(headTop, stemTop, framePaint);
    canvas.drawLine(stemTop, barFwd, framePaint);
    canvas.drawLine(barFwd, barDrop, framePaint);
    canvas.drawCircle(bb, w * 0.027, Paint()..color = bikeNavy);

    // 우상단 라이선스 키 브랜드 블루 배지 (부드러운 회전/글로우 호흡)
    final badgeCenter = pt(0.205, -0.195);
    final badgeRadius = w * 0.112;
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);

    canvas.drawCircle(
      badgeCenter,
      badgeRadius + w * (0.014 + pulse * 0.012),
      Paint()..color = AppColors.primary.withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      badgeCenter,
      badgeRadius + w * 0.014,
      Paint()..color = Colors.white.withValues(alpha: 0.98),
    );
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E8BFF), AppColors.primaryDark],
        ).createShader(
          Rect.fromCircle(center: badgeCenter, radius: badgeRadius),
        ),
    );

    // 배지 내부 열쇠 심볼
    canvas.save();
    canvas.translate(badgeCenter.dx, badgeCenter.dy);
    canvas.rotate(0.68 + math.sin(progress * 2 * math.pi) * 0.06);

    final keyPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(0, -w * 0.032), w * 0.028, keyPaint);
    canvas.drawLine(
      Offset(0, -w * 0.004),
      Offset(0, w * 0.066),
      keyPaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(0, w * 0.036),
      Offset(w * 0.028, w * 0.036),
      keyPaint,
    );
    canvas.drawLine(
      Offset(0, w * 0.058),
      Offset(w * 0.022, w * 0.058),
      keyPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedBikeKeyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 하단 남한강 자전거길을 형상화한 2겹 물결 애니메이션 페인터이다.
class _RiverWavePainter extends CustomPainter {
  _RiverWavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(
      canvas: canvas,
      size: size,
      baseY: size.height * 0.48,
      amplitude: 14,
      phase: progress * 2 * math.pi,
      color: AppColors.primary.withValues(alpha: 0.07),
    );
    _drawWave(
      canvas: canvas,
      size: size,
      baseY: size.height * 0.62,
      amplitude: 11,
      phase: progress * 2 * math.pi + 1.8,
      color: AppColors.primary.withValues(alpha: 0.11),
    );
  }

  void _drawWave({
    required Canvas canvas,
    required Size size,
    required double baseY,
    required double amplitude,
    required double phase,
    required Color color,
  }) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 12) {
      final t = (x / size.width) * 2 * math.pi;
      final y = baseY + math.sin(t * 1.4 + phase) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RiverWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 좌우로 부드럽게 왕복하는 커스텀 필(Pill) 프로그레스 바 위젯이다.
class _ShimmerProgressBar extends StatelessWidget {
  const _ShimmerProgressBar({required this.loopAnimation});

  final Animation<double> loopAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 5,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedBuilder(
        animation: loopAnimation,
        builder: (context, _) {
          // 코사인 곡선을 사용해 0 -> 1 -> 0 구간을 끊김 없이 왕복 이동한다.
          final eased = 0.5 - 0.5 * math.cos(loopAnimation.value * 2 * math.pi);
          final alignX = -1.0 + (eased * 2.0);
          return Align(
            alignment: Alignment(alignX, 0),
            child: Container(
              width: 68,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF389BFF),
                    AppColors.primary,
                    Color(0xFF005BB5),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
