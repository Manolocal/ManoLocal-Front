import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/models/wallet_models.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WalletModel> getBalance() => remoteDataSource.getBalance();

  @override
  Future<PaginatedResponse<WalletTransactionModel>> getTransactions({
    int page = 1,
    int limit = 10,
    TransactionType? tipo,
  }) {
    return remoteDataSource.getTransactions(
      page: page,
      limit: limit,
      tipo: tipo,
    );
  }

  @override
  Future<RechargeWalletResultModel> mockRecharge({
    required double monto,
    String? descripcion,
  }) {
    return remoteDataSource.mockRecharge(
      monto: monto,
      descripcion: descripcion,
    );
  }
}
