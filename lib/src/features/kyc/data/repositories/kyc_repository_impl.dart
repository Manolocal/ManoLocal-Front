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
  }) {
    return remoteDataSource.uploadDocuments(
      ineFilePath: ineFilePath,
      selfieFilePath: selfieFilePath,
    );
  }
}
