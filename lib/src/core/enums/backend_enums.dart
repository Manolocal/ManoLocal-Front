// Enums reflejados desde `prisma/schema.prisma` de ManoLocal-Back.

enum UserRole {
  admin('ADMIN', 'Administrador'),
  empleador('EMPLEADOR', 'Empleador'),
  especialista('ESPECIALISTA', 'Especialista');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return UserRole.values.firstWhere(
      (role) => role.value == normalized,
      orElse: () => UserRole.empleador,
    );
  }
}

enum UserStatus {
  inactivo('INACTIVO', 'Inactivo'),
  pendienteValidacion('PENDIENTE_VALIDACION', 'Pendiente de validación'),
  activo('ACTIVO', 'Activo');

  final String value;
  final String label;

  const UserStatus(this.value, this.label);

  static UserStatus fromString(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return UserStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => UserStatus.inactivo,
    );
  }
}

enum DocumentVerificationStatus {
  pending('PENDING', 'Pendiente'),
  validated('VALIDATED', 'Validado'),
  rejected('REJECTED', 'Rechazado');

  final String value;
  final String label;

  const DocumentVerificationStatus(this.value, this.label);

  static DocumentVerificationStatus fromString(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return DocumentVerificationStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => DocumentVerificationStatus.pending,
    );
  }
}

enum JobStatus {
  pending('PENDING', 'Pendiente'),
  confirmed('CONFIRMED', 'Confirmado'),
  completed('COMPLETED', 'Completado'),
  cancelled('CANCELLED', 'Cancelado');

  final String value;
  final String label;

  const JobStatus(this.value, this.label);

  static JobStatus fromString(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return JobStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => JobStatus.pending,
    );
  }
}

enum TransactionType {
  recarga('RECARGA', 'Recarga'),
  pago('PAGO', 'Pago'),
  congelamiento('CONGELAMIENTO', 'Congelamiento'),
  devolucion('DEVOLUCION', 'Devolución');

  final String value;
  final String label;

  const TransactionType(this.value, this.label);

  static TransactionType fromString(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return TransactionType.values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => TransactionType.recarga,
    );
  }
}
