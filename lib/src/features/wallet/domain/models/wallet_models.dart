import '../../../../core/enums/backend_enums.dart';

/// Billetera virtual del especialista (`GET /wallet/balance` y `GET /wallet`).
class WalletModel {
  final String id;
  final String userId;
  final double balanceDisponible;
  final double balanceCongelado;
  final double balanceTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balanceDisponible,
    required this.balanceCongelado,
    required this.balanceTotal,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balanceDisponible:
          (json['balanceDisponible'] as num?)?.toDouble() ?? 0.0,
      balanceCongelado: (json['balanceCongelado'] as num?)?.toDouble() ?? 0.0,
      balanceTotal: (json['balanceTotal'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

/// Movimiento monetario registrado en la billetera (`GET /wallet/transactions`).
class WalletTransactionModel {
  final String id;
  final String? walletId;
  final String? jobAgreementId;
  final double monto;
  final TransactionType tipo;
  final String? descripcion;
  final DateTime? fecha;

  const WalletTransactionModel({
    required this.id,
    this.walletId,
    this.jobAgreementId,
    required this.monto,
    required this.tipo,
    this.descripcion,
    this.fecha,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString(),
      jobAgreementId: json['jobAgreementId']?.toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      tipo: TransactionType.fromString(json['tipo']?.toString()),
      descripcion: json['descripcion']?.toString(),
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString())
          : null,
    );
  }
}

/// Respuesta de recarga simulada (`POST /wallet/mock-recharge` o `/wallet/recharge`).
class RechargeWalletResultModel {
  final String message;
  final WalletModel wallet;
  final WalletTransactionModel transaction;

  const RechargeWalletResultModel({
    required this.message,
    required this.wallet,
    required this.transaction,
  });

  factory RechargeWalletResultModel.fromJson(Map<String, dynamic> json) {
    final rawWallet = json['wallet'];
    final rawTransaction = json['transaction'];

    return RechargeWalletResultModel(
      message: json['message']?.toString() ?? '',
      wallet: rawWallet is Map<String, dynamic>
          ? WalletModel.fromJson(rawWallet)
          : const WalletModel(
              id: '',
              userId: '',
              balanceDisponible: 0,
              balanceCongelado: 0,
              balanceTotal: 0,
            ),
      transaction: rawTransaction is Map<String, dynamic>
          ? WalletTransactionModel.fromJson(rawTransaction)
          : const WalletTransactionModel(
              id: '',
              monto: 0,
              tipo: TransactionType.recarga,
            ),
    );
  }
}
