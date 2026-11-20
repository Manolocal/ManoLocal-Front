import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Emblema oficial de ManoLocal con acento amarillo industrial sobre grafito.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool lightWordmark;
  final String? subtitle;

  const BrandLogo({
    super.key,
    this.size = 52,
    this.showWordmark = false,
    this.lightWordmark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.handshake_rounded,
          size: size * 0.54,
          color: AppColors.yellow,
        ),
      ),
    );

    if (!showWordmark) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: lightWordmark ? AppColors.white : AppColors.gray,
                ),
                children: const [
                  TextSpan(text: 'Mano'),
                  TextSpan(
                    text: 'Local',
                    style: TextStyle(color: AppColors.yellowDark),
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: lightWordmark ? AppColors.silver : AppColors.grayMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
