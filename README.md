# ManoLocal-Front (Flutter)

Aplicación móvil y responsiva en Flutter para **ManoLocal**, construida bajo arquitectura modular por capas (**Presentación / Dominio / Datos**) y completamente integrada con todos los módulos REST y Socket.IO de `ManoLocal-Back` (NestJS).

---

## Identidad Visual Oficial

Conserva la paleta definida en `lib/src/core/theme/app_colors.dart` y `lib/src/core/theme/app_theme.dart` con soporte para **Modo Claro** y **Modo Oscuro** persistente:

- **Gray**: `#2B2D31` (`AppColors.gray`)
- **Silver**: `#D9DADC` (`AppColors.silver`)
- **Yellow**: `#FFC93C` (`AppColors.yellow`)

---

## Módulos y Pantallas Implementadas

1. **Autenticación 2FA y Registro** (`/login`, `/register`)
   - Registro con selección visual de rol (**Empleador** / **Especialista**) y checklist en vivo de contraseña fuerte (`IsStrongPassword`).
   - Inicio de sesión en 2 pasos (`POST /auth/login` → PIN de 6 dígitos en `POST /auth/verify-2fa`) y protección automática de rutas con `GoRouter`.
2. **Inicio Adaptativo por Rol** (`/dashboard`)
   - Shell responsivo (`NavigationBar` en móvil, `NavigationRail` en pantallas amplias).
   - **Empleador**: búsqueda rápida, oficios populares, acuerdos activos, conversaciones recientes y acceso al Asistente IA.
   - **Especialista**: métricas de saldo disponible/congelado, cuota de catálogo (`X/10`), progreso de verificación KYC y acuerdos activos.
3. **Búsqueda Geográfica SEPOMEX / Copomex y Portafolio Público** (`/search`, `/specialist/:id`)
   - Búsqueda paginada por oficio y código postal (`GET /search/specialists`) con resolución municipal en vivo (`GET /search/geo-info/:cp`).
   - Vista pública del especialista con insignias de identidad/certificados IA, galería zoomable (`GET /catalog/specialist/:id`) y botón directo **Contactar**.
4. **Chat 1-a-1 en Tiempo Real y Acuerdos de Trabajo** (`/chat`, `/chat/:roomId`, `/jobs`)
   - Salas privadas REST (`/chat/rooms`, `/messages`, `/read`) sincronizadas en vivo con **Socket.IO** (`ChatGateway` + `WsJwtGuard`).
   - **Barra interactiva de contratación** dentro del chat y centro `/jobs`: proponer acuerdo, confirmar y congelar cuota de `$50 MXN` (con alerta dedicada para HTTP `402` saldo insuficiente), marcar completado y cancelar con rollback automático.
5. **Billetera Virtual** (`/wallet`)
   - Consulta de saldo disponible, congelado y total (`GET /wallet/balance`).
   - Recarga simulada con montos rápidos (`POST /wallet/mock-recharge`) e historial paginado y filtrable por tipo de movimiento (`GET /wallet/transactions`).
6. **Catálogo Multimedia del Especialista** (`/catalog`)
   - Gestión de hasta 10 fotografías activas (`GET /catalog/me`, `POST /catalog/images`, `DELETE /catalog/images/:id`) con cámara/galería, visor ampliable y control de cuota.
7. **Verificación KYC Bilateral** (`/kyc`)
   - Captura guiada de **INE + Selfie** (`POST /kyc/documents`), previsualización y aceptación de Aviso de Privacidad.
8. **Perfil, Oficios y Certificados OCR con Gemini AI** (`/profile`, `/ai-assistant`)
   - Edición de datos personales (`PATCH /users/me/profile`) con validación de teléfono/CP mexicano y consulta municipal.
   - Gestión de oficios (`PUT /users/me/knowledge`), carga de certificados PDF/Imagen para verificación OCR (`POST /ai/verify-document`, historial `GET /ai/knowledge/:id/verifications`) y **Asistente IA Gemini** (`GET /ai/status`, `POST /ai/generate-text`).

---

## Conexión al Backend Local (`ManoLocal-Back`)

El servidor NestJS corre por defecto en el puerto **`3000` sin prefijo `/api`**:

- **Emulador Android**: `http://10.0.2.2:3000` (automático).
- **Web / Desktop / iOS**: `http://localhost:3000`.
- **Dispositivo físico Android**:
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
