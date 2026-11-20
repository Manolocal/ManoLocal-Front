/// Excepciones de red tipadas alineadas con el `HttpExceptionFilter` de ManoLocal-Back.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;
  final String? path;
  final String? timestamp;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
    this.path,
    this.timestamp,
  });

  @override
  String toString() =>
      'AppException(statusCode: $statusCode, code: $errorCode, message: $message)';
}

class BadRequestException extends AppException {
  const BadRequestException({
    required super.message,
    super.statusCode = 400,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message =
        'Sesión expirada o no autorizada. Por favor inicia sesión nuevamente.',
    super.statusCode = 401,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

/// Mapea la respuesta HTTP 402 `INSUFFICIENT_BALANCE` al confirmar un trabajo.
class InsufficientBalanceException extends AppException {
  const InsufficientBalanceException({
    super.message =
        'Saldo insuficiente en tu billetera para realizar esta operación.',
    super.statusCode = 402,
    super.errorCode = 'INSUFFICIENT_BALANCE',
    super.details,
    super.path,
    super.timestamp,
  });

  double? get requiredAmount => _readAmount('requiredAmount');
  double? get availableBalance => _readAmount('availableBalance');
  double? get missingAmount => _readAmount('missingAmount');
  String get currency =>
      details is Map ? (details['currency']?.toString() ?? 'MXN') : 'MXN';

  double? _readAmount(String key) {
    if (details is Map && details[key] is num) {
      return (details[key] as num).toDouble();
    }
    return null;
  }
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message =
        'Acceso denegado: no tienes permisos suficientes para realizar esta acción.',
    super.statusCode = 403,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'El recurso solicitado no fue encontrado.',
    super.statusCode = 404,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.statusCode = 409,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class ServerErrorException extends AppException {
  const ServerErrorException({
    super.message =
        'Error interno en el servidor (500). Por favor intente más tarde.',
    super.statusCode = 500,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class TimeoutNetworkException extends AppException {
  const TimeoutNetworkException({
    super.message = 'Tiempo de espera agotado al conectar con el servidor.',
    super.statusCode,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}

class NoInternetConnectionException extends AppException {
  const NoInternetConnectionException({
    super.message =
        'No se pudo conectar al servidor. Revisa tu conexión o que NestJS esté corriendo.',
    super.statusCode,
    super.errorCode,
    super.details,
    super.path,
    super.timestamp,
  });
}
