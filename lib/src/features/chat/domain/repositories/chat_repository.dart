import '../../../../core/models/paginated_response.dart';
import '../models/chat_models.dart';

/// Contrato de repositorio para salas e historial de mensajes de chat.
abstract class ChatRepository {
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
