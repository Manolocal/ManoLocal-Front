import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/safe_action_dialog.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reviews/presentation/widgets/create_review_modal.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/models/job_models.dart';
import '../providers/jobs_provider.dart';

/// Centro de gestión de Acuerdos de Trabajo (`/jobs/me`) con filtros y ciclo de vida ACID.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JobsProvider>().loadMyJobs();
    });
  }

  Future<void> _handleAccept(JobAgreementModel job) async {
    final confirm = await SafeActionDialog.show(
      context,
      title: 'Aceptar acuerdo de trabajo',
      message:
          '¿Deseas aceptar "${job.title ?? 'este acuerdo'}"? El trabajo pasará a estado en curso.',
      confirmLabel: 'Aceptar acuerdo',
      cancelLabel: 'Volver',
      icon: Icons.handshake_outlined,
      isDestructive: false,
    );
    if (!confirm || !mounted) return;
    final outcome = await context.read<JobsProvider>().confirmJob(job.id);
    if (!mounted) return;
    if (outcome.isSuccess) {
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  Future<void> _handleComplete(JobAgreementModel job) async {
    final confirm = await SafeActionDialog.show(
      context,
      title: 'Confirmar finalización',
      message:
          '¿Deseas marcar "${job.title ?? 'este trabajo'}" como completado? Esto cerrará el acuerdo de trabajo.',
      confirmLabel: 'Completar trabajo',
      cancelLabel: 'Cancelar',
      icon: Icons.check_circle_outline_rounded,
      isDestructive: false,
    );
    if (!confirm || !mounted) return;
    final outcome = await context.read<JobsProvider>().completeJob(job.id);
    if (!mounted) return;
    if (outcome.isSuccess) {
      context.read<WalletProvider>().syncWallet(outcome.result!.wallet);
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
      await _openReviewModal(outcome.result!.job);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  Future<void> _openReviewModal(JobAgreementModel job) async {
    final result = await CreateReviewModal.show(context, job: job);
    if (!mounted || result == null) return;
    GlobalNotifier.showSuccessSnackBar(
      '¡Reseña publicada! Promedio actualizado: ${result.specialistReputation.ratingAverage.toStringAsFixed(1)}★',
    );
  }

  Future<void> _handleCancel(
    JobAgreementModel job, {
    bool isRejection = false,
    bool isSpecialist = false,
  }) async {
    final reasonCtrl = TextEditingController();
    final confirm = await SafeActionDialog.show(
      context,
      title: isRejection ? 'Rechazar propuesta' : 'Cancelar acuerdo',
      message: isSpecialist
          ? 'Se devolverán automáticamente ${AppFormatters.currency(job.feeAmount)} a tu saldo disponible.'
          : (isRejection
              ? '¿Deseas rechazar esta propuesta de trabajo?'
              : '¿Seguro que deseas cancelar este acuerdo de trabajo?'),
      confirmLabel: isRejection ? 'Sí, rechazar' : 'Sí, cancelar',
      cancelLabel: 'Volver',
      icon: Icons.cancel_outlined,
      isDestructive: true,
      extraContent: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Motivo (opcional)',
        ),
      ),
    );
    if (!confirm || !mounted) return;
    final entered = reasonCtrl.text.trim();
    final reason = entered.isNotEmpty
        ? entered
        : (isRejection ? 'Propuesta rechazada por el empleador' : null);
    final outcome = await context
        .read<JobsProvider>()
        .cancelJob(job.id, reason: reason);
    if (!mounted) return;
    if (outcome.isSuccess) {
      context.read<WalletProvider>().syncWallet(outcome.result!.wallet);
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobsProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acuerdos de Trabajo'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: jobs.selectedStatus == null,
                  onTap: () => jobs.loadMyJobs(status: null),
                ),
                const SizedBox(width: 8),
                ...JobStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: status.label,
                      selected: jobs.selectedStatus == status,
                      onTap: () => jobs.loadMyJobs(status: status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gray,
              backgroundColor: AppColors.yellow,
              onRefresh: () => jobs.loadMyJobs(status: jobs.selectedStatus),
              child: jobs.isLoading && jobs.myJobs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : jobs.errorMessage != null && jobs.myJobs.isEmpty
                      ? ErrorStateView(
                          message: jobs.errorMessage!,
                          onRetry: () =>
                              jobs.loadMyJobs(status: jobs.selectedStatus),
                        )
                      : jobs.myJobs.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.6,
                                  child: EmptyStateView(
                                    icon: Icons.assignment_outlined,
                                    title: 'Sin acuerdos en esta categoría',
                                    description:
                                        'Los acuerdos de servicio se proponen y confirman directamente dentro de cada sala de chat.',
                                    actionLabel: 'Ir a Mensajes',
                                    onAction: () => context.go(AppRoutes.chat),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount:
                                  jobs.myJobs.length + (jobs.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == jobs.myJobs.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: jobs.isLoadingMore
                                            ? null
                                            : () => jobs.loadMoreJobs(),
                                        child: Text(
                                          jobs.isLoadingMore
                                              ? 'Cargando...'
                                              : 'Cargar más acuerdos',
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final job = jobs.myJobs[index];
                                final isSpecialist =
                                    job.room?.specialistId == currentUserId;
                                final isEmployer =
                                    job.room?.employerId == currentUserId;

                                return Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 840),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _JobAgreementCard(
                                        job: job,
                                        isSpecialist: isSpecialist,
                                        isEmployer: isEmployer,
                                        isMutating: jobs.isMutating,
                                        onOpenChat: () => context.push(
                                          AppRoutes.chatRoomPath(job.roomId),
                                        ),
                                        onAccept: () => _handleAccept(job),
                                        onReject: () => _handleCancel(
                                          job,
                                          isRejection: true,
                                          isSpecialist: isSpecialist,
                                        ),
                                        onComplete: () => _handleComplete(job),
                                        onCancel: () => _handleCancel(
                                          job,
                                          isSpecialist: isSpecialist,
                                        ),
                                        onReview: () => _openReviewModal(job),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _JobAgreementCard extends StatelessWidget {
  final JobAgreementModel job;
  final bool isSpecialist;
  final bool isEmployer;
  final bool isMutating;
  final VoidCallback onOpenChat;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback? onReview;

  const _JobAgreementCard({
    required this.job,
    required this.isSpecialist,
    required this.isEmployer,
    required this.isMutating,
    required this.onOpenChat,
    required this.onAccept,
    required this.onReject,
    required this.onComplete,
    required this.onCancel,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title?.isNotEmpty == true
                            ? job.title!
                            : 'Acuerdo de servicio',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Creado el ${AppFormatters.dateTime(job.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                JobStatusBadge(status: job.status),
              ],
            ),
            if (job.description != null && job.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                job.description!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            _JobLifecycleStepper(
              status: job.status,
              isSpecialist: isSpecialist,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.graySurface
                    : AppColors.silverLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio acordado',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          job.agreedPrice != null
                              ? AppFormatters.currency(job.agreedPrice!)
                              : 'A convenir',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (isSpecialist)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comisión ManoLocal',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            AppFormatters.currency(job.feeAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (job.cancellationReason != null &&
                job.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              AppStatusBanner.error('Motivo: ${job.cancellationReason!}'),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text('Abrir Chat'),
                ),
                if (job.status == JobStatus.pending && isEmployer) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: isMutating ? null : onAccept,
                    icon:
                        const Icon(Icons.check_circle_outline_rounded, size: 17),
                    label: const Text('Aceptar Acuerdo'),
                  ),
                  TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: isMutating ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Rechazar'),
                  ),
                ],
                if (job.status == JobStatus.pending && isSpecialist)
                  TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: isMutating ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancelar propuesta'),
                  ),
                if (job.status == JobStatus.confirmed && isEmployer)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: isMutating ? null : onComplete,
                    icon: const Icon(Icons.check_circle_rounded, size: 17),
                    label: const Text('Marcar Completado'),
                  ),
                if (job.status == JobStatus.confirmed)
                  TextButton.icon(
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: isMutating ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: const Text('Cancelar'),
                  ),
                if (job.status == JobStatus.completed && isEmployer) ...[
                  if (!job.hasReview)
                    FilledButton.icon(
                      onPressed: isMutating ? null : onReview,
                      icon: const Icon(Icons.star_rounded, size: 17),
                      label: const Text('Calificar especialista'),
                    )
                  else
                    AppPillBadge(
                      label: job.reviewRating != null
                          ? 'Calificado (${job.reviewRating}★)'
                          : 'Calificado',
                      icon: Icons.star_rounded,
                      backgroundColor: AppColors.yellowSoft,
                      foregroundColor: AppColors.gray,
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobLifecycleStepper extends StatelessWidget {
  final JobStatus status;
  final bool isSpecialist;

  const _JobLifecycleStepper({
    required this.status,
    this.isSpecialist = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == JobStatus.cancelled) {
      return AppStatusBanner(
        message: isSpecialist
            ? 'Acuerdo cancelado · Tu comisión congelada fue devuelta.'
            : 'Acuerdo cancelado.',
        icon: Icons.replay_rounded,
        backgroundColor: AppColors.errorSoft,
        foregroundColor: AppColors.error,
      );
    }

    final step = switch (status) {
      JobStatus.pending => 1,
      JobStatus.confirmed => 2,
      JobStatus.completed => 3,
      JobStatus.cancelled => 0,
    };

    return Row(
      children: [
        _StepDot(label: 'Propuesto', reached: step >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: step >= 2 ? AppColors.yellowDark : AppColors.silver,
          ),
        ),
        _StepDot(label: 'Confirmado', reached: step >= 2),
        Expanded(
          child: Container(
            height: 2,
            color: step >= 3 ? AppColors.success : AppColors.silver,
          ),
        ),
        _StepDot(
          label: 'Completado',
          reached: step >= 3,
          completedColor: AppColors.success,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool reached;
  final Color? completedColor;

  const _StepDot({
    required this.label,
    required this.reached,
    this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = reached
        ? (completedColor ?? AppColors.yellowDark)
        : AppColors.silver;
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
            color: reached
                ? Theme.of(context).colorScheme.onSurface
                : AppColors.grayMuted,
          ),
        ),
      ],
    );
  }
}
