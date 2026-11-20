import '../../../../core/models/paginated_response.dart';
import '../../domain/models/chat_models.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatRoomModel> createOrGetRoom({
    String? specialistId,
    String? employerId,
    String? targetUserId,
  }) {
    return remoteDataSource.createOrGetRoom(
      specialistId: specialistId,
      employerId: employerId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<List<ChatRoomModel>> getUserRooms() => remoteDataSource.getUserRooms();

  @override
  Future<PaginatedResponse<ChatMessageModel>> getRoomMessages(
    String roomId, {
    int page = 1,
    int limit = 50,
  }) {
    return remoteDataSource.getRoomMessages(
      roomId,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<MarkReadResultModel> markMessagesAsRead(String roomId) {
    return remoteDataSource.markMessagesAsRead(roomId);
  }
}
