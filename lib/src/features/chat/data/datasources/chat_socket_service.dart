import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/token_storage_service.dart';
import '../../../jobs/domain/models/job_models.dart';
import '../../domain/models/chat_models.dart';

enum SocketConnectionStatus { disconnected, connecting, connected }

/// Evento en tiempo real emitido por `ChatGateway` al cambiar el estado de un trabajo.
class JobSocketUpdateEvent {
  final String action;
  final String roomId;
  final JobAgreementModel job;
  final String? actorId;

  const JobSocketUpdateEvent({
    required this.action,
    required this.roomId,
    required this.job,
    this.actorId,
  });
}

/// Cliente Socket.IO singleton alineado con `ChatGateway` y `WsJwtGuard` de ManoLocal-Back.
class ChatSocketService {
  final TokenStorageService tokenStorage;
  final bool enabled;

  io.Socket? _socket;
  String? _activeRoomId;
  String? _connectedToken;
  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;

  final _statusController = StreamController<SocketConnectionStatus>.broadcast();
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  final _jobUpdateController = StreamController<JobSocketUpdateEvent>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  ChatSocketService({
    required this.tokenStorage,
    this.enabled = true,
  });

  SocketConnectionStatus get status => _status;
  bool get isConnected => _status == SocketConnectionStatus.connected;

  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;
  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<JobSocketUpdateEvent> get jobUpdateStream =>
      _jobUpdateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<void> connect({String? customSocketUrl}) async {
    if (!enabled) return;

    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }

    if (_socket != null && _socket!.connected && _connectedToken == token) {
      _setStatus(SocketConnectionStatus.connected);
      return;
    }

    _disposeSocketOnly();
    _connectedToken = token;
    _setStatus(SocketConnectionStatus.connecting);

    final url = customSocketUrl ?? ApiConstants.socketUrl;
    final options = io.OptionBuilder()
        .setTransports(['websocket'])
        .enableForceNew()
        .enableForceNewConnection()
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1500)
        .setAuth({'token': 'Bearer $token'})
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .setQuery({'token': 'Bearer $token'})
        .build();

    io.cache.clear();
    final socket = io.io(url, options);
    _socket = socket;

    final connectCompleter = Completer<void>();

    socket.onConnect((_) {
      _setStatus(SocketConnectionStatus.connected);
      if (_activeRoomId != null) {
        socket.emit(SocketEvents.joinRoom, {'roomId': _activeRoomId});
      }
      if (!connectCompleter.isCompleted) {
        connectCompleter.complete();
      }
    });

    socket.onReconnect((_) {
      _setStatus(SocketConnectionStatus.connected);
      if (_activeRoomId != null) {
        socket.emit(SocketEvents.joinRoom, {'roomId': _activeRoomId});
      }
    });

    socket.onDisconnect((_) {
      _setStatus(SocketConnectionStatus.disconnected);
    });

    socket.onConnectError((err) {
      debugPrint('[Socket.IO] Error de conexión: $err');
      _setStatus(SocketConnectionStatus.disconnected);
      if (!connectCompleter.isCompleted) {
        connectCompleter.complete();
      }
    });

    socket.on(SocketEvents.newMessage, (data) {
      final map = _asMap(data);
      if (map != null) {
        _messageController.add(ChatMessageModel.fromJson(map));
      }
    });

    socket.on(SocketEvents.jobCreated, _handleJobEvent);
    socket.on(SocketEvents.jobUpdated, _handleJobEvent);

    socket.on('error', (data) {
      final map = _asMap(data);
      final message = map?['message']?.toString() ?? data?.toString();
      if (message != null && message.isNotEmpty) {
        _errorController.add(message);
      }
    });

    socket.connect();

    await connectCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  void joinRoom(String roomId) {
    _activeRoomId = roomId;
    if (_socket?.connected == true) {
      _socket!.emit(SocketEvents.joinRoom, {'roomId': roomId});
    }
  }

  void leaveRoom(String roomId) {
    if (_activeRoomId == roomId) {
      _activeRoomId = null;
    }
    if (_socket?.connected == true) {
      _socket!.emit(SocketEvents.leaveRoom, {'roomId': roomId});
    }
  }

  Future<ChatMessageModel?> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final currentToken = await tokenStorage.getToken();
    if (_socket == null ||
        !_socket!.connected ||
        currentToken != _connectedToken) {
      await connect();
    }

    final socket = _socket;
    if (socket == null || !socket.connected) {
      throw StateError(
        'Sin conexión en tiempo real con el servidor de chat. Intenta nuevamente.',
      );
    }

    final completer = Completer<ChatMessageModel?>();
    socket.emitWithAck(
      SocketEvents.sendMessage,
      {'roomId': roomId, 'content': content.trim()},
      ack: (dynamic response) {
        if (completer.isCompleted) return;
        final map = _asMap(response);
        final payload = map?['data'];
        final msgMap = _asMap(payload) ?? map;
        if (msgMap != null && msgMap.containsKey('id')) {
          completer.complete(ChatMessageModel.fromJson(msgMap));
        } else {
          completer.complete(null);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
  }

  void disconnect() {
    _activeRoomId = null;
    _connectedToken = null;
    _disposeSocketOnly();
    _setStatus(SocketConnectionStatus.disconnected);
  }

  void _disposeSocketOnly() {
    final socket = _socket;
    if (socket != null) {
      socket.clearListeners();
      socket.disconnect();
      socket.close();
      socket.dispose();
      _socket = null;
    }
    io.cache.clear();
  }

  void _handleJobEvent(dynamic data) {
    final map = _asMap(data);
    if (map == null) return;
    final rawJob = _asMap(map['job']);
    if (rawJob == null) return;
    _jobUpdateController.add(
      JobSocketUpdateEvent(
        action: map['action']?.toString() ?? 'UPDATED',
        roomId: map['roomId']?.toString() ?? rawJob['roomId']?.toString() ?? '',
        job: JobAgreementModel.fromJson(rawJob),
        actorId: map['actorId']?.toString(),
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) {
      return data.map(
        (k, v) => MapEntry(k.toString(), _normalizeValue(v)),
      );
    }
    return null;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), _normalizeValue(v)),
      );
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  void _setStatus(SocketConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
    _jobUpdateController.close();
    _errorController.close();
  }
}
