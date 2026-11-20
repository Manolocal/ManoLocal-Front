import '../../../../core/enums/backend_enums.dart';

/// Vista previa de usuario participante en una sala de chat.
class ChatUserPreviewModel {
  final String id;
  final String? name;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phone;

  const ChatUserPreviewModel({
    required this.id,
    this.name,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
  });

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : ((name != null && name!.trim().isNotEmpty) ? name!.trim() : email);

  factory ChatUserPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    String? fullName;
    String? phone;
    if (rawProfile is Map) {
      fullName = rawProfile['fullName']?.toString();
      phone = rawProfile['phone']?.toString();
    }

    return ChatUserPreviewModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
      fullName: fullName,
      phone: phone,
    );
  }
}

/// Mensaje persistido en una sala de chat (`Message` + `sender`).
class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime? createdAt;
  final ChatUserPreviewModel? sender;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    this.createdAt,
    this.sender,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final rawSender = json['sender'];
    ChatUserPreviewModel? parsedSender;
    if (rawSender is Map) {
      final normalizedSender = rawSender.map(
        (k, v) => MapEntry(k.toString(), v),
      );
      parsedSender = ChatUserPreviewModel.fromJson(normalizedSender);
    }

    final rawSenderId =
        json['senderId']?.toString().trim() ??
        json['sender_id']?.toString().trim() ??
        '';
    final resolvedSenderId =
        rawSenderId.isNotEmpty ? rawSenderId : (parsedSender?.id ?? '');

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? json['room_id']?.toString() ?? '',
      senderId: resolvedSenderId,
      content: json['content']?.toString() ?? '',
      isRead: (json['isRead'] as bool?) ?? (json['is_read'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
      sender: parsedSender,
    );
  }
}

/// Sala privada de chat entre Empleador y Especialista (`POST /chat/rooms` y `GET /chat/rooms`).
class ChatRoomModel {
  final String id;
  final String employerId;
  final String specialistId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ChatUserPreviewModel? employer;
  final ChatUserPreviewModel? specialist;
  final ChatUserPreviewModel? counterpart;
  final ChatMessageModel? lastMessage;

  const ChatRoomModel({
    required this.id,
    required this.employerId,
    required this.specialistId,
    this.createdAt,
    this.updatedAt,
    this.employer,
    this.specialist,
    this.counterpart,
    this.lastMessage,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final rawEmployer = json['employer'];
    final rawSpecialist = json['specialist'];
    final rawCounterpart = json['counterpart'];
    final rawLastMessage = json['lastMessage'];
    final rawMessages = json['messages'];

    ChatMessageModel? resolvedLastMessage;
    if (rawLastMessage is Map<String, dynamic>) {
      resolvedLastMessage = ChatMessageModel.fromJson(rawLastMessage);
    } else if (rawMessages is List &&
        rawMessages.isNotEmpty &&
        rawMessages.first is Map<String, dynamic>) {
      resolvedLastMessage = ChatMessageModel.fromJson(
        rawMessages.first as Map<String, dynamic>,
      );
    }

    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      specialistId: json['specialistId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      employer: rawEmployer is Map<String, dynamic>
          ? ChatUserPreviewModel.fromJson(rawEmployer)
          : null,
      specialist: rawSpecialist is Map<String, dynamic>
          ? ChatUserPreviewModel.fromJson(rawSpecialist)
          : null,
      counterpart: rawCounterpart is Map<String, dynamic>
          ? ChatUserPreviewModel.fromJson(rawCounterpart)
          : null,
      lastMessage: resolvedLastMessage,
    );
  }
}

/// Respuesta de `PATCH /chat/rooms/:roomId/read`.
class MarkReadResultModel {
  final String roomId;
  final int markedCount;

  const MarkReadResultModel({
    required this.roomId,
    required this.markedCount,
  });

  factory MarkReadResultModel.fromJson(Map<String, dynamic> json) {
    return MarkReadResultModel(
      roomId: json['roomId']?.toString() ?? '',
      markedCount: (json['markedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
