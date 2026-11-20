import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badges.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/chat_socket_service.dart';
import '../../domain/models/chat_models.dart';
import '../providers/chat_provider.dart';

/// Bandeja de salas privadas 1-a-1 entre Empleadores y Especialistas.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id;
    final role = auth.user?.role ?? UserRole.empleador;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _SocketStatusPill(status: chat.socketStatus),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gray,
        backgroundColor: AppColors.yellow,
        onRefresh: () => chat.loadRooms(),
        child: chat.isLoadingRooms && chat.rooms.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : chat.errorMessage != null && chat.rooms.isEmpty
                ? ErrorStateView(
                    message: chat.errorMessage!,
                    onRetry: () => chat.loadRooms(),
                  )
                : chat.rooms.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.65,
                            child: EmptyStateView(
                              icon: Icons.forum_outlined,
                              title: 'Aún no tienes conversaciones',
                              description: role == UserRole.especialista
                                  ? 'Cuando un empleador te contacte para cotizar un oficio, su conversación aparecerá aquí en tiempo real.'
                                  : 'Busca un especialista verificado en tu municipio y presiona "Contactar" para abrir una sala privada.',
                              actionLabel: role == UserRole.especialista
                                  ? 'Ir a Mi Catálogo'
                                  : 'Buscar especialistas',
                              onAction: () => context.go(
                                role == UserRole.especialista
                                    ? AppRoutes.catalog
                                    : AppRoutes.search,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: chat.rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final room = chat.rooms[index];
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: _ChatRoomTile(
                                room: room,
                                currentUserId: currentUserId,
                                onTap: () => context.push(
                                  AppRoutes.chatRoomPath(room.id),
                                  extra: room,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _SocketStatusPill extends StatelessWidget {
  final SocketConnectionStatus status;

  const _SocketStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SocketConnectionStatus.connected => ('En vivo', AppColors.success),
      SocketConnectionStatus.connecting => ('Conectando', AppColors.yellow),
      SocketConnectionStatus.disconnected => ('Sin conexión', AppColors.silver),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.graySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final String? currentUserId;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.room,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counterpart = room.counterpart ??
        (room.employerId == currentUserId ? room.specialist : room.employer);
    final name = counterpart?.displayName ?? 'Conversación privada';
    final lastMessage = room.lastMessage;
    final hasUnread = lastMessage != null &&
        !lastMessage.isRead &&
        lastMessage.senderId != currentUserId;
    final sentByMe = lastMessage?.senderId == currentUserId;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(
                initials: AppFormatters.initials(name),
                radius: 24,
                highlighted: hasUnread,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.shortTime(
                            lastMessage?.createdAt ?? room.updatedAt,
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: hasUnread
                                ? AppColors.yellowDark
                                : AppColors.grayMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (sentByMe) ...[
                          Icon(
                            lastMessage!.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 15,
                            color: lastMessage.isRead
                                ? AppColors.info
                                : AppColors.grayMuted,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMessage?.content ??
                                'Toca para iniciar la conversación',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                              color: hasUnread
                                  ? Theme.of(context).colorScheme.onSurface
                                  : AppColors.grayMuted,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.yellowDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (counterpart != null) ...[
                      const SizedBox(height: 6),
                      RoleBadge(role: counterpart.role),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
