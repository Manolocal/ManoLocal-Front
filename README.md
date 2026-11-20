# ManoLocal-Front (Flutter)

Aplicación móvil Flutter estructurada bajo una **arquitectura modular por capas** (**Presentación / Dominio / Datos**) e integrada con el backend NestJS (`ManoLocal-Back`).

---

## Paleta de Colores Oficial

Definida en `lib/src/core/theme/app_colors.dart` y aplicada en `lib/src/core/theme/app_theme.dart`:

- **Gray**: `#2B2D31` (`AppColors.gray`)
- **Silver**: `#D9DADC` (`AppColors.silver`)
- **Yellow**: `#FFC93C` (`AppColors.yellow`)

---

## Arquitectura Modular por Capas

```text
lib/
├── main.dart
└── src/
    ├── app.dart
    ├── core/
    │   ├── constants/        # ApiConstants (URLs y endpoints de NestJS), StorageKeys
    │   ├── di/               # GetIt + MultiProvider (injection_container.dart)
    │   ├── enums/            # UserRole, UserStatus, DocumentVerificationStatus, JobStatus, TransactionType
    │   ├── models/           # PaginationMeta y PaginatedResponse<T>
    │   ├── network/          # ApiClient, dio_interceptor.dart, error_handler.dart, network_exceptions.dart
    │   ├── router/           # AppRoutes y GoRouter (Login, Dashboard, Perfil)
    │   ├── services/         # TokenStorageService (SharedPreferences)
    │   ├── theme/            # AppColors y AppTheme
    │   └── utils/            # GlobalNotifier y navigator/scaffold keys
    └── features/
        ├── auth/             # Registro, Login 2FA (/auth/login -> /auth/verify-2fa), Perfil auth
        ├── users/            # Perfil completo (/users/me), actualización y oficios
        ├── kyc/              # Subida multipart de INE + Selfie (/kyc/documents)
        ├── ai/               # Verificación OCR/Gemini de certificados (/ai/*)
        ├── search/           # Búsqueda geolocalizada SEPOMEX / Copomex (/search/*)
        ├── catalog/          # Galería de trabajos del especialista (/catalog/*)
        ├── chat/             # Salas e historial REST (/chat/*) + eventos Socket.IO
        ├── wallet/           # Saldo, transacciones y recarga mock (/wallet/*)
        ├── jobs/             # Acuerdos de trabajo y cuota de $50 MXN (/jobs/*)
        └── dashboard/        # Pantalla base de diagnóstico y navegación
```

Cada módulo sigue la separación:
- `domain/`: Modelos de negocio e interfaces de repositorio.
- `data/`: DataSources remotos/locales e implementaciones de repositorio.
- `presentation/`: Providers (`ChangeNotifier`) y pantallas (`Screens`).

---

## Cliente HTTP, Interceptores y Manejo de Errores

- **Interceptor JWT** (`lib/src/core/network/dio_interceptor.dart`): inyecta automáticamente `Authorization: Bearer <token>` en peticiones salientes hacia NestJS (respetando `extra: {'requiresAuth': false}` en rutas públicas y preservando el `Content-Type` multipart en `FormData`).
- **Manejador global de errores** (`lib/src/core/network/error_handler.dart`): interpreta el formato `{ statusCode, message, error, code, details, path, timestamp }` de `HttpExceptionFilter` en NestJS y ejecuta acciones centralizadas para `401` (cierre de sesión y redirección a `/login`), `402` (`INSUFFICIENT_BALANCE`), `403`, `500+` y fallos de red/timeout.
- **Envoltorio de respuestas**: `ApiClient.unwrapData` extrae el payload real de `{ "data": ... }` generado por `ResponseInterceptor` en NestJS.

---

## Conexión al Backend Local (`ManoLocal-Back`)

El servidor NestJS corre por defecto en el puerto **`3000` sin prefijo `/api`**:

- **Emulador Android**: `http://10.0.2.2:3000` (seleccionado automáticamente).
- **Web / Desktop / iOS**: `http://localhost:3000`.
- **Dispositivo físico Android** (en la misma red Wi-Fi que tu PC):
  ```bash
  flutter run --dart-define=API_URL=http://<IP_LOCAL_DE_TU_PC>:3000
  ```

---

## Comandos Útiles

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
