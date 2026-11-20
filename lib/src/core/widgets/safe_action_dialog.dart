import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Diálogo estandarizado de confirmación segura para acciones financieras o destructivas.
/// Requiere mantener presionado el botón durante [holdDuration] (1 s por defecto)
/// para evitar toques accidentales.
class SafeActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool isDestructive;
  final Duration holdDuration;
  final Widget? extraContent;

  const SafeActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Volver',
    this.icon = Icons.warning_amber_rounded,
    this.isDestructive = false,
    this.holdDuration = const Duration(seconds: 1),
    this.extraContent,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Volver',
    IconData icon = Icons.warning_amber_rounded,
    bool isDestructive = false,
    Duration holdDuration = const Duration(seconds: 1),
    Widget? extraContent,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SafeActionDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDestructive: isDestructive,
        holdDuration: holdDuration,
        extraContent: extraContent,
      ),
    );
    return result ?? false;
  }

  @override
  State<SafeActionDialog> createState() => _SafeActionDialogState();
}

class _SafeActionDialogState extends State<SafeActionDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed && mounted) {
          _completed = true;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true);
        }
      });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_completed) return;
    _holdController.forward();
  }

  void _cancelHold() {
    if (_completed) return;
    _holdController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        widget.isDestructive ? AppColors.error : AppColors.yellowDark;
    final softBg =
        widget.isDestructive ? AppColors.errorSoft : AppColors.yellowSoft;
    final fillColor =
        widget.isDestructive ? AppColors.error : AppColors.yellow;
    final idleBg = isDark ? AppColors.graySurface : softBg;
    final idleTextColor = widget.isDestructive
        ? (isDark ? AppColors.white : AppColors.error)
        : (isDark ? AppColors.yellow : AppColors.gray);
    final activeTextColor =
        widget.isDestructive ? AppColors.white : AppColors.gray;

    final holdHint = widget.holdDuration.inMilliseconds >= 1000 &&
            widget.holdDuration.inMilliseconds % 1000 == 0
        ? '${widget.holdDuration.inSeconds} s'
        : '${widget.holdDuration.inMilliseconds} ms';

    return AlertDialog(
      icon: CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? AppColors.graySurface : softBg,
        child: Icon(
          widget.icon,
          color: widget.isDestructive ? AppColors.error : AppColors.warning,
          size: 26,
        ),
      ),
      title: Text(widget.title, textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (widget.extraContent != null) ...[
              const SizedBox(height: 12),
              widget.extraContent!,
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 15,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mantén presionado el botón $holdHint para confirmar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.silver : AppColors.grayMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: widget.confirmLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _startHold(),
                onTapUp: (_) => _cancelHold(),
                onTapCancel: _cancelHold,
                child: AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, _) {
                    final progress = _holdController.value;
                    final fgColor =
                        progress >= 0.45 ? activeTextColor : idleTextColor;
                    return Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        color: idleBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.7),
                          width: 1.4,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  heightFactor: 1,
                                  child: Container(color: fillColor),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isDestructive
                                        ? Icons.shield_outlined
                                        : Icons.verified_outlined,
                                    size: 18,
                                    color: fgColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.confirmLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: fgColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
      ],
    );
  }
}
