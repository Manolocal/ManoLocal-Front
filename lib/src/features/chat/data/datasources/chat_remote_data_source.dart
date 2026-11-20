import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/chat_models.dart';

abstract class ChatRemoteDataSource {
  Future<ChatRoomModel> createOrGetRoom({
    String? specialistId,
    String? employerId,
    String? targetUserId,
  });

  Future<List<ChatRoomModel>> getUserRooms();

  Future<PaginatedResponse<ChatMessageModel>> getRoomMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  });

  Future<MarkReadResultModel> markMessagesAsRead(String roomId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ChatRoomModel> createOrGetRoom({
    String? specialistId,
    String? employerId,
    String? targetUserId,
  }) async {
    final response = await apiClient.post(
      ApiConstants.chatRooms,
      data: {
        'specialistId': ?specialistId,
        'employerId': ?employerId,
        'targetUserId': ?targetUserId,
      },
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return ChatRoomModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en POST /chat/rooms: $payload');
  }

  @override
  Future<List<ChatRoomModel>> getUserRooms() async {
    final response = await apiClient.get(ApiConstants.chatRooms);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(ChatRoomModel.fromJson)
          .toList();
    }
    throw FormatException('Respuesta inválida en GET /chat/rooms: $payload');
  }

  @override
  Future<PaginatedResponse<ChatMessageModel>> getRoomMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      ApiConstants.chatRoomMessages(roomId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return PaginatedResponse<ChatMessageModel>.fromJson(
        payload,
        ChatMessageModel.fromJson,
      );
    }
    throw FormatException(
      'Respuesta inválida en /chat/rooms/$roomId/messages: $payload',
    );
  }

  @override
  Future<MarkReadResultModel> markMessagesAsRead(String roomId) async {
    final response = await apiClient.patch(
      ApiConstants.chatRoomRead(roomId),
    );
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return MarkReadResultModel.fromJson(payload);
    }
    throw FormatException(
      'Respuesta inválida en /chat/rooms/$roomId/read: $payload',
    );
  }
}
