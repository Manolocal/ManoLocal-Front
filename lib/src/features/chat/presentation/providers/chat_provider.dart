import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../data/datasources/chat_socket_service.dart';
import '../../domain/models/chat_models.dart';
import '../../domain/repositories/chat_repository.dart';

/// Provider para salas 1-a-1, historial persistente y mensajería en vivo Socket.IO.
class ChatProvider extends ChangeNotifier {
  final ChatRepository chatRepository;
  final ChatSocketService socketService;
  final JobsProvider jobsProvider;

  List<ChatRoomModel> _rooms = const [];
  final Map<String, List<ChatMessageModel>> _messagesByRoom = {};
  final Map<String, PaginationMeta> _messageMetaByRoom = {};

  bool _isLoadingRooms = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _activeRoomId;

  SocketConnectionStatus _socketStatus = SocketConnectionStatus.disconnected;

  StreamSubscription<SocketConnectionStatus>? _statusSub;
  StreamSubscription<ChatMessageModel>? _messageSub;
  StreamSubscription<JobSocketUpdateEvent>? _jobSub;
  StreamSubscription<String>? _errorSub;

  ChatProvider({
    required this.chatRepository,
    required this.socketService,
    required this.jobsProvider,
  }) {
    _statusSub = socketService.statusStream.listen((status) {
      _socketStatus = status;
      notifyListeners();
    });

    _messageSub = socketService.messageStream.listen(_handleIncomingMessage);

    _jobSub = socketService.jobUpdateStream.listen((event) {
      jobsProvider.applySocketJobUpdate(event.job);
    });

    _errorSub = socketService.errorStream.listen((msg) {
      _errorMessage = msg;
      notifyListeners();
    });
  }

  List<ChatRoomModel> get rooms => _rooms;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  SocketConnectionStatus get socketStatus => _socketStatus;
  bool get isSocketConnected =>
      _socketStatus == SocketConnectionStatus.connected;

  List<ChatMessageModel> messagesForRoom(String roomId) =>
      _messagesByRoom[roomId] ?? const [];

  bool hasOlderMessages(String roomId) =>
      _messageMetaByRoom[roomId]?.hasNext ?? false;

  ChatRoomModel? findRoomById(String roomId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  int unreadRoomsCount(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return 0;
    return _rooms.where((room) {
      final msg = room.lastMessage;
      return msg != null && !msg.isRead && msg.senderId != currentUserId;
    }).length;
  }

  Future<void> ensureConnected() => socketService.connect();

  Future<bool> loadRooms() async {
    _isLoadingRooms = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rooms = await chatRepository.getUserRooms();
      _isLoadingRooms = false;
      notifyListeners();
      unawaited(socketService.connect());
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoadingRooms = false;
      notifyListeners();
      return false;
    }
  }

  Future<ChatRoomModel?> openOrCreateRoom({
    String? specialistId,
    String? employerId,
    String? targetUserId,
  }) async {
    _errorMessage = null;
    try {
      final room = await chatRepository.createOrGetRoom(
        specialistId: specialistId,
        employerId: employerId,
        targetUserId: targetUserId,
      );
      _upsertRoom(room);
      notifyListeners();
      return room;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> enterRoom(String roomId) async {
    _activeRoomId = roomId;
    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    await socketService.connect();
    socketService.joinRoom(roomId);

    try {
      final results = await Future.wait([
        chatRepository.getRoomMessages(roomId, page: 1, limit: 50),
        jobsProvider.loadRoomJobs(roomId),
      ]);
      final page = results[0] as PaginatedResponse<ChatMessageModel>;
      _messagesByRoom[roomId] = page.items;
      _messageMetaByRoom[roomId] = page.meta;
      _isLoadingMessages = false;
      notifyListeners();

      // Marcar mensajes recibidos como leídos
      unawaited(_markRoomReadSilently(roomId));
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> loadOlderMessages(String roomId) async {
    final currentMeta = _messageMetaByRoom[roomId];
    if (currentMeta == null || !currentMeta.hasNext || _isLoadingMessages) {
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final page = await chatRepository.getRoomMessages(
        roomId,
        page: currentMeta.page + 1,
        limit: currentMeta.limit,
      );
      final existing = _messagesByRoom[roomId] ?? const <ChatMessageModel>[];
      final existingIds = existing.map((m) => m.id).toSet();
      final olderUnique =
          page.items.where((m) => !existingIds.contains(m.id)).toList();
      _messagesByRoom[roomId] = [...olderUnique, ...existing];
      _messageMetaByRoom[roomId] = page.meta;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void leaveRoom(String roomId) {
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
    }
    socketService.leaveRoom(roomId);
  }

  Future<bool> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ackMessage = await socketService.sendMessage(
        roomId: roomId,
        content: trimmed,
      );
      if (ackMessage != null) {
        _handleIncomingMessage(ackMessage);
      }
      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  void _handleIncomingMessage(ChatMessageModel message) {
    final list = [...(_messagesByRoom[message.roomId] ?? const <ChatMessageModel>[])];
    final exists = list.any((m) => m.id == message.id);
    if (!exists) {
      list.add(message);
      _messagesByRoom[message.roomId] = list;
    }

    // Actualizar vista previa del último mensaje en la bandeja
    final roomIdx = _rooms.indexWhere((r) => r.id == message.roomId);
    if (roomIdx >= 0) {
      final current = _rooms[roomIdx];
      final updated = ChatRoomModel(
        id: current.id,
        employerId: current.employerId,
        specialistId: current.specialistId,
        createdAt: current.createdAt,
        updatedAt: message.createdAt ?? DateTime.now(),
        employer: current.employer,
        specialist: current.specialist,
        counterpart: current.counterpart,
        lastMessage: message,
      );
      final nextRooms = [..._rooms]..removeAt(roomIdx);
      nextRooms.insert(0, updated);
      _rooms = nextRooms;
    }

    if (_activeRoomId == message.roomId) {
      unawaited(_markRoomReadSilently(message.roomId));
    }

    notifyListeners();
  }

  void _upsertRoom(ChatRoomModel room) {
    final idx = _rooms.indexWhere((r) => r.id == room.id);
    if (idx >= 0) {
      final next = [..._rooms];
      next[idx] = room;
      _rooms = next;
    } else {
      _rooms = [room, ..._rooms];
    }
  }

  Future<void> _markRoomReadSilently(String roomId) async {
    try {
      await chatRepository.markMessagesAsRead(roomId);
      final idx = _rooms.indexWhere((r) => r.id == roomId);
      if (idx >= 0 && _rooms[idx].lastMessage != null) {
        final room = _rooms[idx];
        final lm = room.lastMessage!;
        final updatedRooms = [..._rooms];
        updatedRooms[idx] = ChatRoomModel(
          id: room.id,
          employerId: room.employerId,
          specialistId: room.specialistId,
          createdAt: room.createdAt,
          updatedAt: room.updatedAt,
          employer: room.employer,
          specialist: room.specialist,
          counterpart: room.counterpart,
          lastMessage: ChatMessageModel(
            id: lm.id,
            roomId: lm.roomId,
            senderId: lm.senderId,
            content: lm.content,
            isRead: true,
            createdAt: lm.createdAt,
            sender: lm.sender,
          ),
        );
        _rooms = updatedRooms;
        notifyListeners();
      }
    } catch (_) {
      // Operación silenciosa en segundo plano.
    }
  }

  void clear() {
    socketService.disconnect();
    _rooms = const [];
    _messagesByRoom.clear();
    _messageMetaByRoom.clear();
    _activeRoomId = null;
    _errorMessage = null;
    _isLoadingRooms = false;
    _isLoadingMessages = false;
    _isSending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _messageSub?.cancel();
    _jobSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is AppException) {
      return error.message;
    }
    return error.toString();
  }
}
