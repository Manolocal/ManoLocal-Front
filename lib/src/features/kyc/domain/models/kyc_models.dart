import '../../../../core/enums/backend_enums.dart';

/// Resultado de la subida de documentos KYC (`POST /kyc/documents`).
class KycUploadResultModel {
  final String ineUrl;
  final String selfieUrl;
  final UserStatus? userStatus;

  const KycUploadResultModel({
    required this.ineUrl,
    required this.selfieUrl,
    this.userStatus,
  });

  factory KycUploadResultModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    UserStatus? status;
    if (rawUser is Map<String, dynamic> && rawUser['status'] != null) {
      status = UserStatus.fromString(rawUser['status']?.toString());
    }

    return KycUploadResultModel(
      ineUrl: json['ineUrl']?.toString() ?? '',
      selfieUrl: json['selfieUrl']?.toString() ?? '',
      userStatus: status,
    );
  }
}
