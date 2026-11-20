import '../../../../core/enums/backend_enums.dart';
import '../../../wallet/domain/models/wallet_models.dart';

/// Referencia resumida de sala incluida dentro de un acuerdo de trabajo.
class JobRoomRefModel {
  final String id;
  final String employerId;
  final String specialistId;

  const JobRoomRefModel({
    required this.id,
    required this.employerId,
    required this.specialistId,
  });

  factory JobRoomRefModel.fromJson(Map<String, dynamic> json) {
    return JobRoomRefModel(
      id: json['id']?.toString() ?? '',
      employerId: json['employerId']?.toString() ?? '',
      specialistId: json['specialistId']?.toString() ?? '',
    );
  }
}

/// Acuerdo de trabajo formalizado dentro de una sala de chat (`/jobs`).
class JobAgreementModel {
  final String id;
  final String roomId;
  final String? title;
  final String? description;
  final double? agreedPrice;
  final double feeAmount;
  final JobStatus status;
  final String? createdById;
  final String? cancelledById;
  final String? cancellationReason;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final JobRoomRefModel? room;

  const JobAgreementModel({
    required this.id,
    required this.roomId,
    this.title,
    this.description,
    this.agreedPrice,
    required this.feeAmount,
    required this.status,
    this.createdById,
    this.cancelledById,
    this.cancellationReason,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.room,
  });

  factory JobAgreementModel.fromJson(Map<String, dynamic> json) {
    final rawRoom = json['room'];
    return JobAgreementModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      agreedPrice: (json['agreedPrice'] as num?)?.toDouble(),
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 50.0,
      status: JobStatus.fromString(json['status']?.toString()),
      createdById: json['createdById']?.toString(),
      cancelledById: json['cancelledById']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      confirmedAt: _tryParseDate(json['confirmedAt']),
      completedAt: _tryParseDate(json['completedAt']),
      cancelledAt: _tryParseDate(json['cancelledAt']),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      room: rawRoom is Map<String, dynamic>
          ? JobRoomRefModel.fromJson(rawRoom)
          : null,
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// DTO de creación equivalente a `CreateJobDto` en NestJS.
class CreateJobRequestModel {
  final String roomId;
  final String? title;
  final String? description;
  final double? agreedPrice;
  final bool acceptCommission;

  const CreateJobRequestModel({
    required this.roomId,
    this.title,
    this.description,
    this.agreedPrice,
    this.acceptCommission = true,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        'acceptCommission': acceptCommission,
      };
}

/// Respuesta de `GET /jobs/room/:roomId`.
class RoomJobsModel {
  final String roomId;
  final JobAgreementModel? activeJob;
  final List<JobAgreementModel> jobs;

  const RoomJobsModel({
    required this.roomId,
    this.activeJob,
    required this.jobs,
  });

  factory RoomJobsModel.fromJson(Map<String, dynamic> json) {
    final rawActive = json['activeJob'];
    final rawJobs = json['jobs'];

    return RoomJobsModel(
      roomId: json['roomId']?.toString() ?? '',
      activeJob: rawActive is Map<String, dynamic>
          ? JobAgreementModel.fromJson(rawActive)
          : null,
      jobs: rawJobs is List
          ? rawJobs
              .whereType<Map<String, dynamic>>()
              .map(JobAgreementModel.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Respuesta de mutación (`POST /jobs`, `confirm`, `complete`, `cancel`).
class JobMutationResultModel {
  final String message;
  final JobAgreementModel job;
  final WalletModel? wallet;
  final WalletTransactionModel? transaction;

  const JobMutationResultModel({
    required this.message,
    required this.job,
    this.wallet,
    this.transaction,
  });

  factory JobMutationResultModel.fromJson(Map<String, dynamic> json) {
    final rawJob = json['job'];
    final rawWallet = json['wallet'];
    final rawTransaction = json['transaction'];

    return JobMutationResultModel(
      message: json['message']?.toString() ?? '',
      job: rawJob is Map<String, dynamic>
          ? JobAgreementModel.fromJson(rawJob)
          : const JobAgreementModel(
              id: '',
              roomId: '',
              feeAmount: 50.0,
              status: JobStatus.pending,
            ),
      wallet: rawWallet is Map<String, dynamic>
          ? WalletModel.fromJson(rawWallet)
          : null,
      transaction: rawTransaction is Map<String, dynamic>
          ? WalletTransactionModel.fromJson(rawTransaction)
          : null,
    );
  }
}
