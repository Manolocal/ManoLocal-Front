import 'package:intl/intl.dart';

/// Utilidades de formato (MXN, fechas en español) y validadores alineados con NestJS.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  static String currency(double amount, {bool withSuffix = true}) {
    final formatted = _currencyFormat.format(amount);
    return withSuffix ? '$formatted MXN' : formatted;
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month ${local.year} · $hour:$minute';
  }

  static String shortTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    if (sameDay) return '$hh:$mm';

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Ayer';
    }

    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd/$mo';
  }

  static String chatDayHeader(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Hoy';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Ayer';
    }
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${local.day} de ${months[local.month - 1]} de ${local.year}';
  }

  static String initials(String? text) {
    final clean = (text ?? '').trim();
    if (clean.isEmpty) return 'ML';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Validadores alineados con los decoradores `class-validator` de ManoLocal-Back.
class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // Alineado con IsStrongPassword de ManoLocal-Back
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#])[A-Za-z\d@$!%*?&_\-#]{8,}$',
  );

  // Alineado con IsPhoneNumberMx de ManoLocal-Back
  static final RegExp _phoneMxRegex = RegExp(r'^[1-9][0-9]{9}$');

  // Alineado con IsPostalCodeMx de ManoLocal-Back
  static final RegExp _postalCodeMxRegex = RegExp(r'^[0-9]{5}$');

  static String? email(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_emailRegex.hasMatch(clean)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa una contraseña';
    if (!_strongPasswordRegex.hasMatch(text)) {
      return 'Mín. 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 símbolo (@\$!%*?&_-#)';
    }
    return null;
  }

  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);
  static bool hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);
  static bool hasDigit(String value) => RegExp(r'\d').hasMatch(value);
  static bool hasSpecialChar(String value) =>
      RegExp(r'[@$!%*?&_\-#]').hasMatch(value);

  static String? phoneMx(String? value, {bool required = false}) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return required ? 'Ingresa tu número telefónico a 10 dígitos' : null;
    }
    final digits = clean.replaceFirst(RegExp(r'^\+52'), '').replaceAll(RegExp(r'[\s-]'), '');
    if (!_phoneMxRegex.hasMatch(digits)) {
      return 'Debe ser un teléfono válido de México de 10 dígitos';
    }
    return null;
  }

  static String? postalCodeMx(String? value, {bool required = false}) {
    final clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return required ? 'Ingresa un código postal de 5 dígitos' : null;
    }
    if (!_postalCodeMxRegex.hasMatch(clean)) {
      return 'El código postal debe tener exactamente 5 dígitos';
    }
    return null;
  }

  static String? positiveAmount(
    String? value, {
    bool required = true,
    double min = 1,
    double max = 100000,
  }) {
    final clean = (value ?? '').trim().replaceAll(',', '');
    if (clean.isEmpty) {
      return required ? 'Ingresa un monto válido' : null;
    }
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un número mayor a cero';
    }
    if (parsed < min) {
      return 'El monto mínimo es \$${min.toStringAsFixed(2)}';
    }
    if (parsed > max) {
      return 'El monto máximo permitido es \$${max.toStringAsFixed(0)}';
    }
    return null;
  }
}
