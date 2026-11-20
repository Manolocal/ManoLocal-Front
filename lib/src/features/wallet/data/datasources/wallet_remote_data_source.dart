import '../../../../core/constants/api_constants.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/wallet_models.dart';

abstract class WalletRemoteDataSource {
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

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiClient apiClient;

  WalletRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<WalletModel> getBalance() async {
    final response = await apiClient.get(ApiConstants.walletBalance);
    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return WalletModel.fromJson(payload);
    }
    throw FormatException('Respuesta inválida en /wallet/balance: $payload');
  }

  @override
  Future<PaginatedResponse<WalletTransactionModel>> getTransactions({
    int page = 1,
    int limit = 10,
    TransactionType? tipo,
  }) async {
    final response = await apiClient.get(
      ApiConstants.walletTransactions,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (tipo != null) 'tipo': tipo.value,
      },
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return PaginatedResponse<WalletTransactionModel>.fromJson(
        payload,
        WalletTransactionModel.fromJson,
      );
    }
    throw FormatException(
      'Respuesta inválida en /wallet/transactions: $payload',
    );
  }

  @override
  Future<RechargeWalletResultModel> mockRecharge({
    required double monto,
    String? descripcion,
  }) async {
    final response = await apiClient.post(
      ApiConstants.walletMockRecharge,
      data: {
        'monto': monto,
        if (descripcion != null && descripcion.trim().isNotEmpty)
          'descripcion': descripcion.trim(),
      },
    );

    final payload = ApiClient.unwrapData(response.data);
    if (payload is Map<String, dynamic>) {
      return RechargeWalletResultModel.fromJson(payload);
    }
    throw FormatException(
      'Respuesta inválida en /wallet/mock-recharge: $payload',
    );
  }
}
