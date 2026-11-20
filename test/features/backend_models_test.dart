import 'package:flutter_test/flutter_test.dart';
import 'package:manolocal_front/src/core/enums/backend_enums.dart';
import 'package:manolocal_front/src/core/models/paginated_response.dart';
import 'package:manolocal_front/src/features/auth/domain/models/auth_models.dart';
import 'package:manolocal_front/src/features/catalog/domain/models/catalog_models.dart';
import 'package:manolocal_front/src/features/chat/domain/models/chat_models.dart';
import 'package:manolocal_front/src/features/jobs/domain/models/job_models.dart';
import 'package:manolocal_front/src/features/search/domain/models/search_models.dart';
import 'package:manolocal_front/src/features/users/domain/models/user_profile_models.dart';
import 'package:manolocal_front/src/features/wallet/domain/models/wallet_models.dart';

void main() {
  group('Serialización de modelos alineados con ManoLocal-Back', () {
    test('AuthSessionModel parsea respuesta de /auth/verify-2fa', () {
      final session = AuthSessionModel.fromJson({
        'accessToken': 'jwt.token.value',
        'user': {
          'id': 'u-1',
          'email': 'carlos@manolocal.com',
          'name': 'Carlos López',
          'role': 'ESPECIALISTA',
        },
      });

      expect(session.accessToken, 'jwt.token.value');
      expect(session.user.id, 'u-1');
      expect(session.user.role, UserRole.especialista);
      expect(session.user.displayName, 'Carlos López');
    });

    test('UserMeModel parsea /users/me con perfil y conocimientos verificados', () {
      final userMe = UserMeModel.fromJson({
        'id': 'u-2',
        'email': 'plomero@manolocal.com',
        'name': 'Ana Ruiz',
        'role': 'ESPECIALISTA',
        'status': 'PENDIENTE_VALIDACION',
        'createdAt': '2026-10-01T10:00:00.000Z',
        'profile': {
          'id': 'p-1',
          'userId': 'u-2',
          'fullName': 'Ana Ruiz',
          'phone': '5512345678',
          'address': 'Av. Revolución 100',
          'postalCode': '01000',
          'ineUrl': 'https://example.com/ine.jpg',
          'selfieUrl': 'https://example.com/selfie.jpg',
        },
        'knowledges': [
          {
            'id': 'k-1',
            'name': 'Plomería residencial',
            'verifications': [
              {
                'id': 'v-1',
                'status': 'VALIDATED',
                'provider': 'google-gemini',
                'score': 0.96,
                'fileUrl': 'https://example.com/cert.pdf',
              },
            ],
          },
        ],
      });

      expect(userMe.status, UserStatus.pendienteValidacion);
      expect(userMe.profile?.postalCode, '01000');
      expect(userMe.knowledges.length, 1);
      expect(
        userMe.knowledges.first.verifications.first.status,
        DocumentVerificationStatus.validated,
      );
      expect(userMe.knowledges.first.verifications.first.score, 0.96);
    });

    test('SearchSpecialistsResultModel parsea /search/specialists', () {
      final result = SearchSpecialistsResultModel.fromJson({
        'specialists': [
          {
            'id': 'esp-1',
            'email': 'esp@manolocal.com',
            'name': 'Luis García',
            'status': 'ACTIVO',
            'profile': {
              'fullName': 'Luis García',
              'phone': '5587654321',
              'postalCode': '01000',
            },
            'knowledges': [
              {'id': 'k-10', 'name': 'Electricista', 'verifications': []},
            ],
          },
        ],
        'geoFilter': {
          'searchedPostalCode': '01000',
          'municipio': 'Álvaro Obregón',
          'totalPostalCodesInMunicipality': 75,
        },
        'pagination': {
          'total': 1,
          'page': 1,
          'limit': 10,
          'totalPages': 1,
          'hasNext': false,
          'hasPrev': false,
        },
      });

      expect(result.specialists.length, 1);
      expect(result.specialists.first.displayName, 'Luis García');
      expect(result.geoFilter.municipio, 'Álvaro Obregón');
      expect(result.geoFilter.totalPostalCodesInMunicipality, 75);
      expect(result.pagination.total, 1);
    });

    test('MyCatalogModel parsea /catalog/me', () {
      final catalog = MyCatalogModel.fromJson({
        'images': [
          {
            'id': 'img-1',
            'userId': 'u-1',
            'imageUrl': 'https://example.com/work.jpg',
            'title': 'Instalación de regadera',
            'description': 'Tubería de cobre',
            'isActive': true,
          },
        ],
        'quota': {
          'active': 1,
          'limit': 10,
          'remaining': 9,
        },
      });

      expect(catalog.images.length, 1);
      expect(catalog.images.first.title, 'Instalación de regadera');
      expect(catalog.quota.remaining, 9);
    });

    test('ChatRoomModel parsea tanto GET /chat/rooms como POST /chat/rooms', () {
      final fromList = ChatRoomModel.fromJson({
        'id': 'room-1',
        'employerId': 'emp-1',
        'specialistId': 'esp-1',
        'counterpart': {
          'id': 'esp-1',
          'name': 'Luis',
          'email': 'luis@manolocal.com',
          'role': 'ESPECIALISTA',
          'profile': {'fullName': 'Luis Pérez', 'phone': '5500001111'},
        },
        'lastMessage': {
          'id': 'msg-1',
          'roomId': 'room-1',
          'senderId': 'esp-1',
          'content': 'Hola, paso mañana a cotizar.',
          'isRead': false,
        },
      });

      expect(fromList.counterpart?.displayName, 'Luis Pérez');
      expect(fromList.lastMessage?.content, 'Hola, paso mañana a cotizar.');
    });

    test('WalletModel y PaginatedResponse<WalletTransactionModel> parsean billetera', () {
      final wallet = WalletModel.fromJson({
        'id': 'w-1',
        'userId': 'esp-1',
        'balanceDisponible': 200.0,
        'balanceCongelado': 50.0,
        'balanceTotal': 250.0,
      });

      final txs = PaginatedResponse<WalletTransactionModel>.fromJson(
        {
          'data': [
            {
              'id': 't-1',
              'walletId': 'w-1',
              'monto': 50,
              'tipo': 'CONGELAMIENTO',
              'descripcion': 'Cuota de confirmación',
            },
          ],
          'meta': {'total': 1, 'page': 1, 'limit': 10, 'totalPages': 1},
        },
        WalletTransactionModel.fromJson,
      );

      expect(wallet.balanceTotal, 250.0);
      expect(txs.items.first.tipo, TransactionType.congelamiento);
      expect(txs.meta.hasNext, isFalse);
    });

    test('JobAgreementModel parsea acuerdo de trabajo con cuota de 50 MXN', () {
      final job = JobAgreementModel.fromJson({
        'id': 'job-1',
        'roomId': 'room-1',
        'title': 'Calentador solar',
        'agreedPrice': 1200.0,
        'feeAmount': 50.0,
        'status': 'CONFIRMED',
        'room': {
          'id': 'room-1',
          'employerId': 'emp-1',
          'specialistId': 'esp-1',
        },
      });

      expect(job.status, JobStatus.confirmed);
      expect(job.agreedPrice, 1200.0);
      expect(job.feeAmount, 50.0);
      expect(job.room?.specialistId, 'esp-1');
    });
  });
}
