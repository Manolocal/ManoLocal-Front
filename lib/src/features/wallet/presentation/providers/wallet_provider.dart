import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/enums/backend_enums.dart';
import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/wallet_models.dart';
import '../../domain/repositories/wallet_repository.dart';

/// Provider para la Billetera Virtual del especialista (saldo, recarga y movimientos).
class WalletProvider extends ChangeNotifier {
  final WalletRepository walletRepository;

  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = const [];
  PaginationMeta? _meta;
  TransactionType? _selectedFilter;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRecharging = false;
  String? _errorMessage;

  WalletProvider({required this.walletRepository});

  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  PaginationMeta? get meta => _meta;
  TransactionType? get selectedFilter => _selectedFilter;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRecharging => _isRecharging;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _meta?.hasNext ?? false;

  Future<bool> loadWallet({TransactionType? filter}) async {
    _selectedFilter = filter;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        walletRepository.getBalance(),
        walletRepository.getTransactions(
          page: 1,
          limit: 15,
          tipo: _selectedFilter,
        ),
      ]);

      _wallet = results[0] as WalletModel;
      final txPage = results[1] as PaginatedResponse<WalletTransactionModel>;
      _transactions = txPage.items;
      _meta = txPage.meta;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setFilter(TransactionType? filter) async {
    if (_selectedFilter == filter && _transactions.isNotEmpty) return;
    _selectedFilter = filter;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final txPage = await walletRepository.getTransactions(
        page: 1,
        limit: 15,
        tipo: _selectedFilter,
      );
      _transactions = txPage.items;
      _meta = txPage.meta;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !hasMore) return;
    final nextPage = (_meta?.page ?? 1) + 1;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final txPage = await walletRepository.getTransactions(
        page: nextPage,
        limit: _meta?.limit ?? 15,
        tipo: _selectedFilter,
      );
      _transactions = [..._transactions, ...txPage.items];
      _meta = txPage.meta;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<RechargeWalletResultModel?> recharge({
    required double monto,
    String? descripcion,
  }) async {
    _isRecharging = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await walletRepository.mockRecharge(
        monto: monto,
        descripcion: descripcion,
      );
      _wallet = result.wallet;
      if (_selectedFilter == null ||
          _selectedFilter == TransactionType.recarga) {
        _transactions = [result.transaction, ..._transactions];
      }
      _isRecharging = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isRecharging = false;
      notifyListeners();
      return null;
    }
  }

  void syncWallet(WalletModel? updated) {
    if (updated == null) return;
    _wallet = updated;
    notifyListeners();
  }

  void clear() {
    _wallet = null;
    _transactions = const [];
    _meta = null;
    _selectedFilter = null;
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    _isRecharging = false;
    notifyListeners();
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
