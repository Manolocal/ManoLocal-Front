import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/star_rating_display.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../jobs/domain/models/job_models.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../domain/models/review_models.dart';
import '../providers/reviews_provider.dart';

/// Modal limpio e interactivo para que el empleador califique un trabajo finalizado (`COMPLETED`).
class CreateReviewModal extends StatefulWidget {
  final JobAgreementModel job;
  final String? specialistName;

  const CreateReviewModal({
    super.key,
    required this.job,
    this.specialistName,
  });

  static Future<CreateReviewResultModel?> show(
    BuildContext context, {
    required JobAgreementModel job,
    String? specialistName,
  }) {
    context.read<ReviewsProvider>().clearSubmitError();
    return showDialog<CreateReviewResultModel>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CreateReviewModal(
        job: job,
        specialistName: specialistName,
      ),
    );
  }

  @override
  State<CreateReviewModal> createState() => _CreateReviewModalState();
}

class _CreateReviewModalState extends State<CreateReviewModal> {
  final _commentController = TextEditingController();
  int _selectedRating = 0;
  String? _localValidationError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      setState(() {
        _localValidationError =
            'Selecciona una calificación de 1 a 5 estrellas antes de publicar.';
      });
      return;
    }

    setState(() => _localValidationError = null);

    final reviewsProvider = context.read<ReviewsProvider>();
    final jobsProvider = context.read<JobsProvider>();

    final result = await reviewsProvider.submitReview(
      jobAgreementId: widget.job.id,
      rating: _selectedRating,
      comment: _commentController.text,
    );

    if (!mounted) return;
    if (result != null) {
      jobsProvider.markJobReviewed(widget.job.id, _selectedRating);
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviews = context.watch<ReviewsProvider>();
    final displayError = _localValidationError ?? reviews.submitError;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.yellowDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Califica el servicio',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.specialistName?.trim().isNotEmpty == true
                              ? widget.specialistName!.trim()
                              : (widget.job.title?.trim().isNotEmpty == true
                                  ? widget.job.title!.trim()
                                  : 'Trabajo finalizado'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: reviews.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.grayDeep
                      : AppColors.silverLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    if (widget.job.title != null &&
                        widget.job.title!.trim().isNotEmpty) ...[
                      Text(
                        widget.job.title!.trim(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    StarRatingInput(
                      rating: _selectedRating,
                      onChanged: (value) {
                        setState(() {
                          _selectedRating = value;
                          _localValidationError = null;
                        });
                        reviews.clearSubmitError();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _commentController,
                enabled: !reviews.isSubmitting,
                maxLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText:
                      '¿Qué te pareció la puntualidad, limpieza y calidad del trabajo?',
                  alignLabelWithHint: true,
                ),
              ),
              if (displayError != null) ...[
                const SizedBox(height: 10),
                AppStatusBanner.error(displayError),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: reviews.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Ahora no'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: reviews.isSubmitting ? null : _submit,
                      icon: reviews.isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gray,
                              ),
                            )
                          : const Icon(Icons.star_rounded),
                      label: Text(
                        reviews.isSubmitting
                            ? 'Publicando...'
                            : 'Publicar reseña',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
