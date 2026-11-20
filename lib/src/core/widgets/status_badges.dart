import 'package:flutter/material.dart';
import '../enums/backend_enums.dart';
import '../theme/app_colors.dart';

/// Insignia tipo cápsula con icono opcional y contraste garantizado.
class AppPillBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final Color? borderColor;

  const AppPillBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignia oficial de rol (`EMPLEADOR`, `ESPECIALISTA`, `ADMIN`).
class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (role) {
      UserRole.especialista => (
          Icons.handyman_rounded,
          AppColors.gray,
          AppColors.yellow,
        ),
      UserRole.empleador => (
          Icons.person_search_rounded,
          AppColors.yellowSoft,
          AppColors.gray,
        ),
      UserRole.admin => (
          Icons.admin_panel_settings_rounded,
          AppColors.infoSoft,
          AppColors.info,
        ),
    };

    return AppPillBadge(
      label: role.label,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}

/// Insignia oficial de estado de cuenta y confianza KYC.
class UserStatusBadge extends StatelessWidget {
  final UserStatus status;

  const UserStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg, border) = switch (status) {
      UserStatus.activo => (
          'Identidad Validada',
          Icons.verified_rounded,
          AppColors.successSoft,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.35),
        ),
      UserStatus.pendienteValidacion => (
          'En Validación KYC',
          Icons.hourglass_top_rounded,
          AppColors.warningSoft,
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.35),
        ),
      UserStatus.inactivo => (
          'Perfil Incompleto',
          Icons.info_outline_rounded,
          AppColors.silverLight,
          AppColors.grayMuted,
          AppColors.silver,
        ),
    };

    return AppPillBadge(
      label: label,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: border,
    );
  }
}

/// Insignia para estados de acuerdos de trabajo (`PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`).
class JobStatusBadge extends StatelessWidget {
  final JobStatus status;

  const JobStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg, border) = switch (status) {
      JobStatus.pending => (
          Icons.schedule_rounded,
          AppColors.warningSoft,
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.3),
        ),
      JobStatus.confirmed => (
          Icons.lock_clock_rounded,
          AppColors.infoSoft,
          AppColors.info,
          AppColors.info.withValues(alpha: 0.3),
        ),
      JobStatus.completed => (
          Icons.check_circle_rounded,
          AppColors.successSoft,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.3),
        ),
      JobStatus.cancelled => (
          Icons.cancel_rounded,
          AppColors.errorSoft,
          AppColors.error,
          AppColors.error.withValues(alpha: 0.3),
        ),
    };

    return AppPillBadge(
      label: status.label,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
      borderColor: border,
    );
  }
}

/// Insignia para el resultado de verificación OCR/Gemini de un certificado.
class DocumentVerificationBadge extends StatelessWidget {
  final DocumentVerificationStatus status;
  final double? score;

  const DocumentVerificationBadge({
    super.key,
    required this.status,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final pct = score != null ? ' ${(score! * 100).round()}%' : '';
    final (label, icon, bg, fg) = switch (status) {
      DocumentVerificationStatus.validated => (
          'Certificado IA$pct',
          Icons.workspace_premium_rounded,
          AppColors.successSoft,
          AppColors.success,
        ),
      DocumentVerificationStatus.pending => (
          'Revisando IA',
          Icons.auto_awesome_rounded,
          AppColors.warningSoft,
          AppColors.warning,
        ),
      DocumentVerificationStatus.rejected => (
          'No validado',
          Icons.gpp_bad_rounded,
          AppColors.errorSoft,
          AppColors.error,
        ),
    };

    return AppPillBadge(
      label: label,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}

/// Insignia de tipo de movimiento en billetera virtual.
class TransactionTypeBadge extends StatelessWidget {
  final TransactionType type;

  const TransactionTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (type) {
      TransactionType.recarga => (
          Icons.add_circle_outline_rounded,
          AppColors.successSoft,
          AppColors.success,
        ),
      TransactionType.devolucion => (
          Icons.replay_rounded,
          AppColors.infoSoft,
          AppColors.info,
        ),
      TransactionType.congelamiento => (
          Icons.ac_unit_rounded,
          AppColors.warningSoft,
          AppColors.warning,
        ),
      TransactionType.pago => (
          Icons.receipt_long_rounded,
          AppColors.errorSoft,
          AppColors.error,
        ),
    };

    return AppPillBadge(
      label: type.label,
      icon: icon,
      backgroundColor: bg,
      foregroundColor: fg,
    );
  }
}
