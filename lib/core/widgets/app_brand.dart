import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/localization/app_localizations.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class AppLogoMark extends StatelessWidget {
  final double size;

  const AppLogoMark({
    super.key,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppLogoPainter(),
      ),
    );
  }
}

class AppBrandLockup extends StatelessWidget {
  final bool centered;
  final bool showTagline;
  final double logoSize;
  final double titleSize;
  final double taglineSize;
  final Color? titleColor;
  final Color? taglineColor;

  const AppBrandLockup({
    super.key,
    this.centered = false,
    this.showTagline = true,
    this.logoSize = 48,
    this.titleSize = 18,
    this.taglineSize = 12,
    this.titleColor,
    this.taglineColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTitleColor = titleColor ??
        (isDark ? AppColors.textPrimary : AppColors.textPrimaryLight);
    final effectiveTaglineColor = taglineColor ??
        (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight);

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: effectiveTitleColor,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            l10n.marketplaceTagline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: effectiveTaglineColor,
              fontSize: taglineSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );

    if (centered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogoMark(size: logoSize),
          const SizedBox(height: AppSpacing.md),
          text,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: logoSize),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    final inset = size.width * 0.035;
    final radius = size.width * 0.22;
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(radius),
    );

    final bgPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(background, bgPaint);

    final shadowPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.20,
        size.width * 0.64,
        size.height * 0.60,
      ),
      -0.3,
      5.4,
      false,
      shadowPaint,
    );

    final oPainter = TextPainter(
      text: TextSpan(
        text: 'O',
        style: TextStyle(
          color: AppColors.background,
          fontSize: size.width * 0.54,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cPainter = TextPainter(
      text: TextSpan(
        text: 'C',
        style: TextStyle(
          color: AppColors.background,
          fontSize: size.width * 0.48,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    oPainter.paint(
      canvas,
      Offset(size.width * 0.17, size.height * 0.25),
    );
    cPainter.paint(
      canvas,
      Offset(size.width * 0.48, size.height * 0.30),
    );

    final sparkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.78, size.height * 0.24);
    canvas.drawLine(
      center.translate(0, -size.height * 0.09),
      center.translate(0, size.height * 0.09),
      sparkPaint,
    );
    canvas.drawLine(
      center.translate(-size.width * 0.09, 0),
      center.translate(size.width * 0.09, 0),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
