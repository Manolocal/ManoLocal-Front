import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Claves globales para disparar navegación y notificaciones fuera del árbol de widgets
/// (por ejemplo, desde interceptores HTTP).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notificador global estilizado con la paleta oficial de ManoLocal.
class GlobalNotifier {
  GlobalNotifier._();

  static void showErrorSnackBar(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppColors.error,
      foregroundColor: AppColors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void showWarningSnackBar(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.yellow,
      foregroundColor: AppColors.gray,
      duration: const Duration(seconds: 4),
    );
  }

  static void showSuccessSnackBar(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.success,
      foregroundColor: AppColors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfoSnackBar(String message) {
    _showSnackBar(
      message: message,
      icon: Icons.info_outline,
      backgroundColor: AppColors.gray,
      foregroundColor: AppColors.silver,
      duration: const Duration(seconds: 3),
    );
  }

  static void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required Duration duration,
  }) {
    final state = rootScaffoldMessengerKey.currentState;
    if (state == null) return;

    state.removeCurrentSnackBar();
    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
