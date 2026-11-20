import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Emblema oficial de ManoLocal con acento amarillo industrial sobre grafito.
class BrandLogo extends StatelessWidget {
  static const String appName = 'ManoLocal';
  static const String appSlogan =
      'El oficio que necesitas a la vuelta de la esquina.';
  static const String logoAssetPath = 'assets/images/manolocal_logo.png';

  final double size;
  final bool showWordmark;
  final bool lightWordmark;
  final String? subtitle;
  final bool showSlogan;

  const BrandLogo({
    super.key,
    this.size = 52,
    this.showWordmark = false,
    this.lightWordmark = false,
    this.subtitle,
    this.showSlogan = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.28);
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((size * 0.28) - 1.5),
        child: Image.asset(
          logoAssetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              Icons.handyman_rounded,
              size: size * 0.54,
              color: AppColors.yellow,
            ),
          ),
        ),
      ),
    );

    if (!showWordmark) return badge;

    final effectiveSubtitle = subtitle ?? (showSlogan ? appSlogan : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 12),
        Flexible(
          child: Column(
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
                  children: [
                    const TextSpan(text: 'Mano'),
                    TextSpan(
                      text: 'Local',
                      style: TextStyle(
                        color: lightWordmark
                            ? AppColors.yellow
                            : AppColors.yellowDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (effectiveSubtitle != null)
                Text(
                  effectiveSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: lightWordmark
                        ? AppColors.silver
                        : AppColors.grayMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
