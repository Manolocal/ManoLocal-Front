import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget reutilizable de solo lectura para mostrar reputación con estrellas (1 a 5).
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double starSize;
  final bool compact;
  final bool showEmptyLabel;
  final Color? textColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.starSize = 16,
    this.compact = false,
    this.showEmptyLabel = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = rating.clamp(0.0, 5.0);
    final hasReviews = reviewCount > 0 || normalized > 0;
    final labelColor = textColor ?? theme.colorScheme.onSurfaceVariant;

    if (!hasReviews && showEmptyLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: starSize,
            color: AppColors.grayMuted,
          ),
          const SizedBox(width: 4),
          Text(
            compact ? 'Sin reseñas' : 'Aún sin reseñas',
            style: theme.textTheme.labelMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final threshold = index + 1;
          IconData icon;
          Color color;
          if (normalized >= threshold - 0.25) {
            icon = Icons.star_rounded;
            color = AppColors.yellowDark;
          } else if (normalized >= threshold - 0.75) {
            icon = Icons.star_half_rounded;
            color = AppColors.yellowDark;
          } else {
            icon = Icons.star_outline_rounded;
            color = AppColors.grayMuted;
          }

          return Icon(
            icon,
            size: starSize,
            color: color,
          );
        }),
        const SizedBox(width: 5),
        Text(
          normalized.toStringAsFixed(1),
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (!compact || reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text(
            compact
                ? '($reviewCount)'
                : '($reviewCount ${reviewCount == 1 ? 'reseña' : 'reseñas'})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Selector interactivo de calificación de 1 a 5 estrellas para el modal de reseña.
class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double starSize;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.starSize = 38,
  });

  static String labelForRating(int value) {
    return switch (value) {
      1 => 'Muy malo',
      2 => 'Malo',
      3 => 'Regular',
      4 => 'Muy bueno',
      5 => 'Excelente',
      _ => 'Selecciona una calificación',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isSelected = starValue <= rating;
            return Semantics(
              button: true,
              label: 'Calificar con $starValue estrellas',
              child: IconButton(
                key: ValueKey('star-input-$starValue'),
                onPressed: () => onChanged(starValue),
                iconSize: starSize,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? AppColors.yellow : AppColors.grayMuted,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          labelForRating(rating),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: rating > 0 ? AppColors.gray : AppColors.grayMuted,
          ),
        ),
      ],
    );
  }
}
