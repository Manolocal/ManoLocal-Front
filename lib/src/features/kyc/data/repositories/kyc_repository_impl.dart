import 'dart:typed_data';
import '../../domain/models/kyc_models.dart';
import '../../domain/repositories/kyc_repository.dart';
import '../datasources/kyc_remote_data_source.dart';

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource remoteDataSource;

  KycRepositoryImpl({required this.remoteDataSource});

  @override
  Future<KycUploadResultModel> uploadDocuments({
    required String ineFilePath,
    required String selfieFilePath,
    Uint8List? ineBytes,
    String? ineFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  }) {
    return remoteDataSource.uploadDocuments(
      ineFilePath: ineFilePath,
      selfieFilePath: selfieFilePath,
      ineBytes: ineBytes,
      ineFileName: ineFileName,
      selfieBytes: selfieBytes,
      selfieFileName: selfieFileName,
    );
  }
}
