class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'AppException(statusCode: $statusCode, message: $message)';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Sesión expirada o no autorizada. Por favor inicia sesión nuevamente.',
    super.statusCode = 401,
    super.details,
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Acceso denegado: no tienes permisos suficientes para realizar esta acción.',
    super.statusCode = 403,
    super.details,
  });
}

class ServerErrorException extends AppException {
  const ServerErrorException({
    super.message = 'Error interno en el servidor (500). Por favor intente más tarde.',
    super.statusCode = 500,
    super.details,
  });
}

class BadRequestException extends AppException {
  const BadRequestException({
    required super.message,
    super.statusCode = 400,
    super.details,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'El recurso solicitado no fue encontrado.',
    super.statusCode = 404,
    super.details,
  });
}

class TimeoutNetworkException extends AppException {
  const TimeoutNetworkException({
    super.message = 'Tiempo de espera agotado al conectar con el servidor.',
    super.statusCode,
    super.details,
  });
}

class NoInternetConnectionException extends AppException {
  const NoInternetConnectionException({
    super.message = 'No se pudo conectar al servidor. Revisa tu conexión de red o la IP configurada.',
    super.statusCode,
    super.details,
  });
}
