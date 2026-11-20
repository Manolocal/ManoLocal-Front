import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../models/wallet_models.dart';

/// Contrato de repositorio para la billetera virtual de especialistas.
abstract class WalletRepository {
  Future<WalletModel> getBalance();

  Future<PaginatedResponse<WalletTransactionModel>> getTransactions({
    int page = 1,
    int limit = 10,
    TransactionType? tipo,
  });

  Future<RechargeWalletResultModel> mockRecharge({
    required double monto,
    String? descripcion,
  });
}
