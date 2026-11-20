import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/kyc_models.dart';
import '../../domain/repositories/kyc_repository.dart';

/// Imagen seleccionada localmente para KYC (compatible con móvil, escritorio y web).
class SelectedKycFile {
  final String path;
  final String name;
  final Uint8List? bytes;

  const SelectedKycFile({
    required this.path,
    required this.name,
    this.bytes,
  });
}

/// Provider para la captura y envío seguro de documentos de identidad KYC (`POST /kyc/documents`).
class KycProvider extends ChangeNotifier {
  final KycRepository kycRepository;

  SelectedKycFile? _ineFile;
  SelectedKycFile? _selfieFile;
  bool _acceptedPrivacy = false;
  bool _isUploading = false;
  KycUploadResultModel? _lastResult;
  String? _errorMessage;

  KycProvider({required this.kycRepository});

  SelectedKycFile? get ineFile => _ineFile;
  SelectedKycFile? get selfieFile => _selfieFile;
  bool get acceptedPrivacy => _acceptedPrivacy;
  bool get isUploading => _isUploading;
  KycUploadResultModel? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      _ineFile != null &&
      _selfieFile != null &&
      _acceptedPrivacy &&
      !_isUploading;

  void setIneFile(SelectedKycFile? file) {
    _ineFile = file;
    _errorMessage = null;
    notifyListeners();
  }

  void setSelfieFile(SelectedKycFile? file) {
    _selfieFile = file;
    _errorMessage = null;
    notifyListeners();
  }

  void setAcceptedPrivacy(bool accepted) {
    _acceptedPrivacy = accepted;
    _errorMessage = null;
    notifyListeners();
  }

  Future<KycUploadResultModel?> submitDocuments() async {
    if (_ineFile == null || _selfieFile == null) {
      _errorMessage = 'Debes seleccionar tu INE y tu selfie antes de enviar.';
      notifyListeners();
      return null;
    }
    if (!_acceptedPrivacy) {
      _errorMessage =
          'Debes aceptar el Aviso de Privacidad y Deslinde de Responsabilidad.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await kycRepository.uploadDocuments(
        ineFilePath: _ineFile!.path,
        selfieFilePath: _selfieFile!.path,
        ineBytes: _ineFile!.bytes,
        ineFileName: _ineFile!.name,
        selfieBytes: _selfieFile!.bytes,
        selfieFileName: _selfieFile!.name,
      );
      _lastResult = result;
      _isUploading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _ineFile = null;
    _selfieFile = null;
    _acceptedPrivacy = false;
    _lastResult = null;
    _errorMessage = null;
    _isUploading = false;
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
