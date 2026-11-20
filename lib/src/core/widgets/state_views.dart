import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Encabezado consistente para secciones dentro de pantallas y paneles.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

/// Banner informativo / de alerta reutilizable.
class AppStatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? trailing;

  const AppStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.trailing,
  });

  factory AppStatusBanner.error(String message) => AppStatusBanner(
        message: message,
        icon: Icons.error_outline_rounded,
        backgroundColor: AppColors.errorSoft,
        foregroundColor: AppColors.error,
      );

  factory AppStatusBanner.warning(String message, {Widget? trailing}) =>
      AppStatusBanner(
        message: message,
        icon: Icons.warning_amber_rounded,
        backgroundColor: AppColors.yellowSoft,
        foregroundColor: AppColors.gray,
        trailing: trailing,
      );

  factory AppStatusBanner.success(String message) => AppStatusBanner(
        message: message,
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: AppColors.successSoft,
        foregroundColor: AppColors.success,
      );

  factory AppStatusBanner.info(String message, {Widget? trailing}) =>
      AppStatusBanner(
        message: message,
        icon: Icons.info_outline_rounded,
        backgroundColor: AppColors.infoSoft,
        foregroundColor: AppColors.info,
        trailing: trailing,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Estado vacío elegante con icono, mensaje y acción sugerida.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.graySurface : AppColors.yellowSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDark ? AppColors.yellow : AppColors.gray,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de error con botón de reintento.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.cloud_off_rounded,
      title: 'No pudimos cargar la información',
      description: message,
      actionLabel: 'Reintentar',
      onAction: onRetry,
    );
  }
}

/// Avatar circular con iniciales y anillo de acento ManoLocal.
class UserAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final bool highlighted;

  const UserAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: highlighted ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.yellow, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.gray,
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.yellow,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.68,
          ),
        ),
      ),
    );
  }
}
