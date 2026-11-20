import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/navigation_keys.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/domain/models/job_models.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../users/presentation/providers/profile_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../data/datasources/chat_socket_service.dart';
import '../../domain/models/chat_models.dart';
import '../providers/chat_provider.dart';

/// Sala privada de chat en tiempo real con Barra de Acuerdos de Trabajo ($50 MXN).
/// Flujo: Especialista envía propuesta aceptando comisión -> Empleador acepta o rechaza ->
/// Empleador marca completado o cualquiera de los dos puede cancelar con rollback.
class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final ChatRoomModel? initialRoom;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.initialRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatProvider _chatProvider;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatProvider.enterRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    _chatProvider.leaveRoom(widget.roomId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final ok = await context.read<ChatProvider>().sendMessage(
          roomId: widget.roomId,
          content: text,
        );
    if (!ok && mounted) {
      _messageController.text = text;
      final err = context.read<ChatProvider>().errorMessage;
      if (err != null) GlobalNotifier.showErrorSnackBar(err);
    } else {
      _scrollToBottom();
    }
  }

  /// Solo el Especialista envía la propuesta aceptando de paso la comisión de $50 MXN.
  Future<void> _openCreateJobSheet() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    var acceptedCommission = false;

    final submitted = await showModalBottomSheet<CreateJobRequestModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enviar acuerdo de trabajo',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Envía los detalles del servicio al empleador. Al enviarlo se congelará la comisión de \$50.00 MXN de tu saldo disponible.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del servicio *',
                      hintText: 'Ej. Instalación de calentador solar',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.length < 3) {
                        return 'Escribe al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Alcance y detalles (opcional)',
                      hintText:
                          'Materiales incluidos, fecha acordada, garantía...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio acordado MXN (opcional)',
                      hintText: '1200.00',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (v) =>
                        AppValidators.positiveAmount(v, required: false),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.yellowDark.withValues(alpha: 0.45),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: acceptedCommission,
                      onChanged: (v) =>
                          setModalState(() => acceptedCommission = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.gray,
                      checkColor: AppColors.yellow,
                      title: const Text(
                        'Acepto la comisión de \$50.00 MXN',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: const Text(
                        'Se congelará de mi saldo disponible ahora y se devolverá automáticamente si el empleador rechaza o si se cancela.',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: !acceptedCommission
                        ? null
                        : () {
                            if (!formKey.currentState!.validate()) return;
                            final rawPrice =
                                priceCtrl.text.trim().replaceAll(',', '');
                            Navigator.of(ctx).pop(
                              CreateJobRequestModel(
                                roomId: widget.roomId,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                                agreedPrice: rawPrice.isEmpty
                                    ? null
                                    : double.tryParse(rawPrice),
                                acceptCommission: true,
                              ),
                            );
                          },
                    icon: const Icon(Icons.handshake_rounded),
                    label: const Text('Enviar acuerdo y congelar \$50 MXN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submitted == null || !mounted) return;
    final outcome = await context.read<JobsProvider>().createJob(submitted);
    if (!mounted) return;

    if (outcome.isSuccess) {
      context.read<WalletProvider>().syncWallet(outcome.result!.wallet);
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.isInsufficientBalance) {
      _showInsufficientBalanceDialog(outcome.insufficientBalance!);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  /// Solo el Empleador acepta el acuerdo propuesto por el especialista.
  Future<void> _acceptJob(JobAgreementModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aceptar acuerdo de trabajo'),
        content: Text(
          '¿Deseas aceptar la propuesta "${job.title ?? 'Acuerdo de servicio'}"'
          '${job.agreedPrice != null ? ' por ${AppFormatters.currency(job.agreedPrice!)}' : ''}? '
          'Al aceptar, el servicio pasará a estado en curso y cualquiera de las dos partes podrá cancelarlo antes de completarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Aceptar acuerdo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final outcome = await context.read<JobsProvider>().confirmJob(job.id);
    if (!mounted) return;

    if (outcome.isSuccess) {
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  void _showInsufficientBalanceDialog(InsufficientBalanceException error) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 40,
          color: AppColors.warning,
        ),
        title: const Text('Saldo insuficiente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error.message, textAlign: TextAlign.center),
            if (error.availableBalance != null &&
                error.requiredAmount != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.silverLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _BalanceLine(
                      'Disponible actual',
                      AppFormatters.currency(error.availableBalance!),
                    ),
                    const SizedBox(height: 4),
                    _BalanceLine(
                      'Comisión requerida',
                      AppFormatters.currency(error.requiredAmount!),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.wallet);
            },
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Recargar Billetera'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeJob(JobAgreementModel job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar trabajo como completado'),
        content: Text(
          '¿Confirmas que el especialista completó "${job.title ?? 'el servicio'}" satisfactoriamente? Esto finalizará el acuerdo de trabajo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Aún no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, trabajo completado'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final outcome = await context.read<JobsProvider>().completeJob(job.id);
    if (!mounted) return;

    if (outcome.isSuccess) {
      context.read<WalletProvider>().syncWallet(outcome.result!.wallet);
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  /// Permite rechazar (Empleador en PENDING) o cancelar (ambos en PENDING/CONFIRMED).
  Future<void> _cancelOrRejectJob(
    JobAgreementModel job, {
    bool isRejection = false,
    bool isSpecialist = false,
  }) async {
    final reasonCtrl = TextEditingController();

    final descriptionText = isSpecialist
        ? 'Al cancelar este acuerdo, los ${AppFormatters.currency(job.feeAmount)} congelados se devolverán automáticamente a tu saldo disponible.'
        : (isRejection
            ? '¿Deseas rechazar esta propuesta de trabajo? Podrás seguir acordando los detalles en el chat.'
            : '¿Seguro que deseas cancelar este acuerdo de trabajo?');

    final confirmCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isRejection
              ? 'Rechazar propuesta de trabajo'
              : 'Cancelar acuerdo de trabajo',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(descriptionText),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isRejection
                    ? 'Motivo del rechazo (opcional)'
                    : 'Motivo de cancelación (opcional)',
                hintText: isRejection
                    ? 'Ej. Ajustar presupuesto o fecha'
                    : 'Ej. Reprogramación por mutuo acuerdo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isRejection ? 'Rechazar propuesta' : 'Cancelar acuerdo'),
          ),
        ],
      ),
    );

    if (confirmCancel != true || !mounted) return;
    final enteredReason = reasonCtrl.text.trim();
    final reason = enteredReason.isNotEmpty
        ? enteredReason
        : (isRejection ? 'Propuesta rechazada por el empleador' : null);

    final outcome = await context.read<JobsProvider>().cancelJob(
          job.id,
          reason: reason,
        );
    if (!mounted) return;

    if (outcome.isSuccess) {
      context.read<WalletProvider>().syncWallet(outcome.result!.wallet);
      GlobalNotifier.showSuccessSnackBar(outcome.result!.message);
    } else if (outcome.errorMessage != null) {
      GlobalNotifier.showErrorSnackBar(outcome.errorMessage!);
    }
  }

  void _showRoomJobsHistory(List<JobAgreementModel> roomJobs) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de acuerdos en esta sala',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (roomJobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aún no hay acuerdos registrados en esta sala.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: roomJobs.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (_, index) {
                    final j = roomJobs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        j.title ?? 'Acuerdo de trabajo',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (j.agreedPrice != null)
                            AppFormatters.currency(j.agreedPrice!),
                          AppFormatters.dateTime(j.createdAt),
                          if (j.cancellationReason != null)
                            'Motivo: ${j.cancellationReason}',
                        ].join('\n'),
                      ),
                      trailing: JobStatusBadge(status: j.status),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final chat = context.watch<ChatProvider>();
    final jobs = context.watch<JobsProvider>();

    final currentUserId =
        (auth.user?.id.isNotEmpty == true ? auth.user!.id : null) ??
            profile.userMe?.id ??
            '';
    final myDisplayName =
        profile.userMe?.displayName ?? auth.user?.displayName ?? 'Tú';

    final room = chat.findRoomById(widget.roomId) ?? widget.initialRoom;
    final counterpart = room?.counterpart ??
        (room?.employerId == currentUserId ? room?.specialist : room?.employer);
    final counterpartName = counterpart?.displayName ?? 'Conversación';

    final messages = chat.messagesForRoom(widget.roomId);
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    final roomJobsData = jobs.roomJobs(widget.roomId);
    final activeJob = roomJobsData?.activeJob;
    final roomSpecialistId = room?.specialistId ?? activeJob?.room?.specialistId;
    final roomEmployerId = room?.employerId ?? activeJob?.room?.employerId;
    final userRole = profile.userMe?.role ?? auth.user?.role;
    final isRoomSpecialist = roomSpecialistId != null &&
            roomSpecialistId.isNotEmpty
        ? (roomSpecialistId == currentUserId && currentUserId.isNotEmpty)
        : userRole == UserRole.especialista;
    final isRoomEmployer = roomEmployerId != null && roomEmployerId.isNotEmpty
        ? (roomEmployerId == currentUserId && currentUserId.isNotEmpty)
        : userRole == UserRole.empleador;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              initials: AppFormatters.initials(counterpartName),
              radius: 17,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counterpartName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5),
                  ),
                  Text(
                    chat.socketStatus == SocketConnectionStatus.connected
                        ? 'En línea · WebSocket activo'
                        : 'Sincronizando sala...',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.silver,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Historial de acuerdos',
            icon: const Icon(Icons.history_rounded),
            onPressed: () =>
                _showRoomJobsHistory(roomJobsData?.jobs ?? const []),
          ),
        ],
      ),
      body: Column(
        children: [
          _JobAgreementActionBar(
            activeJob: activeJob,
            isMutating: jobs.isMutating,
            isSpecialist: isRoomSpecialist,
            isEmployer: isRoomEmployer,
            onCreateJob: _openCreateJobSheet,
            onAcceptJob: activeJob != null ? () => _acceptJob(activeJob) : null,
            onRejectJob: activeJob != null
                ? () => _cancelOrRejectJob(
                      activeJob,
                      isRejection: true,
                      isSpecialist: isRoomSpecialist,
                    )
                : null,
            onCompleteJob:
                activeJob != null ? () => _completeJob(activeJob) : null,
            onCancelJob: activeJob != null
                ? () => _cancelOrRejectJob(
                      activeJob,
                      isRejection: false,
                      isSpecialist: isRoomSpecialist,
                    )
                : null,
          ),
          Expanded(
            child: chat.isLoadingMessages && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.chat_outlined,
                        title: 'Inicia la conversación',
                        description:
                            'Acuerden los detalles del servicio, horario y presupuesto. El especialista puede enviar el acuerdo formal desde la barra superior.',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                        itemCount: messages.length +
                            (chat.hasOlderMessages(widget.roomId) ? 1 : 0),
                        itemBuilder: (context, index) {
                          final hasOlder = chat.hasOlderMessages(widget.roomId);
                          if (hasOlder && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      chat.loadOlderMessages(widget.roomId),
                                  icon: const Icon(Icons.expand_less_rounded),
                                  label:
                                      const Text('Cargar mensajes anteriores'),
                                ),
                              ),
                            );
                          }

                          final msgIdx = hasOlder ? index - 1 : index;
                          final message = messages[msgIdx];
                          final prev = msgIdx > 0 ? messages[msgIdx - 1] : null;
                          final showDateHeader = message.createdAt != null &&
                              (prev?.createdAt == null ||
                                  !_isSameDay(
                                    prev!.createdAt!.toLocal(),
                                    message.createdAt!.toLocal(),
                                  ));

                          final isMine = currentUserId.isNotEmpty &&
                              message.senderId == currentUserId;
                          final senderName = isMine
                              ? myDisplayName
                              : (message.sender?.displayName ??
                                  counterpartName);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.silverLight,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        AppFormatters.chatDayHeader(
                                          message.createdAt!,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grayMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              _MessageBubble(
                                message: message,
                                isMine: isMine,
                                senderName: senderName,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _MessageComposer(
            controller: _messageController,
            isSending: chat.isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _JobAgreementActionBar extends StatelessWidget {
  final JobAgreementModel? activeJob;
  final bool isMutating;
  final bool isSpecialist;
  final bool isEmployer;
  final VoidCallback onCreateJob;
  final VoidCallback? onAcceptJob;
  final VoidCallback? onRejectJob;
  final VoidCallback? onCompleteJob;
  final VoidCallback? onCancelJob;

  const _JobAgreementActionBar({
    required this.activeJob,
    required this.isMutating,
    required this.isSpecialist,
    required this.isEmployer,
    required this.onCreateJob,
    this.onAcceptJob,
    this.onRejectJob,
    this.onCompleteJob,
    this.onCancelJob,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.graySurface : AppColors.yellowTint;
    final border = isDark ? AppColors.grayElevated : AppColors.silver;

    if (activeJob == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.handshake_outlined,
              size: 20,
              color: AppColors.yellowDark,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSpecialist
                    ? '¿Listos? Envía el acuerdo aceptando la comisión (\$50 MXN).'
                    : 'El especialista enviará el acuerdo formal cuando definan el trabajo.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (isSpecialist) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: isMutating ? null : onCreateJob,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded, size: 16),
                label: const Text('Enviar Acuerdo'),
              ),
            ],
          ],
        ),
      );
    }

    final job = activeJob!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title?.isNotEmpty == true
                      ? job.title!
                      : 'Acuerdo de trabajo activo',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              JobStatusBadge(status: job.status),
            ],
          ),
          if (job.description != null && job.description!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              job.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final details = <String>[
                if (job.agreedPrice != null)
                  'Precio acordado: ${AppFormatters.currency(job.agreedPrice!, withSuffix: false)}'
                else
                  'Precio a convenir',
                if (isSpecialist)
                  'Comisión congelada: ${AppFormatters.currency(job.feeAmount, withSuffix: false)}',
              ];
              return Text(
                details.join('  ·  '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job.status == JobStatus.pending && isEmployer) ...[
                FilledButton.icon(
                  onPressed: isMutating ? null : onAcceptJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Aceptar Acuerdo'),
                ),
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onRejectJob,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Rechazar'),
                ),
              ],
              if (job.status == JobStatus.pending && isSpecialist) ...[
                const AppPillBadge(
                  label: 'Esperando aceptación del empleador',
                  icon: Icons.hourglass_bottom_rounded,
                  backgroundColor: AppColors.silverLight,
                  foregroundColor: AppColors.gray,
                ),
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onCancelJob,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar propuesta'),
                ),
              ],
              if (job.status == JobStatus.confirmed && isEmployer)
                FilledButton.icon(
                  onPressed: isMutating ? null : onCompleteJob,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Trabajo Completado'),
                ),
              if (job.status == JobStatus.confirmed && isSpecialist)
                const AppPillBadge(
                  label: 'Acuerdo aceptado · En progreso',
                  icon: Icons.engineering_rounded,
                  backgroundColor: AppColors.infoSoft,
                  foregroundColor: AppColors.info,
                ),
              if (job.status == JobStatus.confirmed)
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onCancelJob,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: Text(
                    isSpecialist ? 'Cancelar (Devolver \$50)' : 'Cancelar',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isMine
        ? AppColors.gray
        : (isDark ? AppColors.graySurface : AppColors.white);
    final textColor = isMine
        ? AppColors.white
        : (isDark ? AppColors.white : AppColors.gray);
    final nameColor = isMine ? AppColors.yellow : AppColors.yellowDark;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
        border: isMine
            ? null
            : Border.all(
                color: isDark ? AppColors.grayElevated : AppColors.silver,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMine ? 'Tú · $senderName' : senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: nameColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            message.content,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppFormatters.shortTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isMine ? AppColors.silver : AppColors.grayMuted,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: message.isRead ? AppColors.yellow : AppColors.silver,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            UserAvatar(
              initials: AppFormatters.initials(senderName),
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.graySurface : AppColors.silver,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.grayMuted : AppColors.silver,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.yellowDark,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.yellow,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: isSending ? null : onSend,
                tooltip: 'Enviar',
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gray,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: AppColors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.grayMuted),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.gray,
          ),
        ),
      ],
    );
  }
}
