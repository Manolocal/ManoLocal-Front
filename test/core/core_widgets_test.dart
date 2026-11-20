import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manolocal_front/src/core/helpers/camera_helper.dart';
import 'package:manolocal_front/src/core/theme/app_theme.dart';
import 'package:manolocal_front/src/core/widgets/custom_image_cache.dart';
import 'package:manolocal_front/src/core/widgets/safe_action_dialog.dart';
import 'package:manolocal_front/src/core/widgets/skeleton_loader_widget.dart';

class _FakeImagePicker extends ImagePicker {
  final XFile? fileToReturn;
  CameraDevice? lastPreferredDevice;
  ImageSource? lastSource;

  _FakeImagePicker({this.fileToReturn});

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    lastPreferredDevice = preferredCameraDevice;
    return fileToReturn;
  }
}

void main() {
  group('Core Widgets y CameraHelper', () {
    testWidgets(
      'SkeletonLoaderWidget.specialistList renderiza tarjetas skeleton animadas',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: SkeletonLoaderWidget.specialistList(itemCount: 2),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Card), findsNWidgets(2));
        expect(find.byType(SkeletonBox), findsWidgets);
      },
    );

    testWidgets(
      'CustomImageCache renderiza fallback limpio cuando imageUrl está vacía',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: SizedBox(
                width: 120,
                height: 120,
                child: CustomImageCache(
                  imageUrl: '',
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
        expect(find.byType(ClipRRect), findsOneWidget);
      },
    );

    testWidgets(
      'SafeActionDialog exige mantener presionado 1s y rechaza toques rápidos',
      (tester) async {
        bool? outcome;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () async {
                      outcome = await SafeActionDialog.show(
                        context,
                        title: 'Confirmar acción crítica',
                        message: 'Advertencia financiera de prueba.',
                        confirmLabel: 'Confirmar Ahora',
                        isDestructive: true,
                      );
                    },
                    child: const Text('Abrir diálogo'),
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Abrir diálogo y probar botón Cancelar ("Volver")
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar acción crítica'), findsOneWidget);
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(outcome, isFalse);

        // 2. Reabrir y probar toque rápido (NO debe confirmar)
        outcome = null;
        await tester.tap(find.text('Abrir diálogo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirmar Ahora'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Confirmar acción crítica'), findsOneWidget);
        expect(outcome, isNull);

        // 3. Mantener presionado 1 segundo completo -> SÍ confirma
        final holdCenter = tester.getCenter(find.text('Confirmar Ahora'));
        final gesture = await tester.startGesture(holdCenter);
        await tester.pump(const Duration(milliseconds: 120));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Confirmar acción crítica'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 700));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Confirmar acción crítica'), findsNothing);
        expect(outcome, isTrue);
      },
    );

    test(
      'CameraHelper usa cámara trasera para INE/Catálogo, frontal para Selfie y maneja cancelación',
      () async {
        final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);
        final fakeFile = XFile.fromData(fakeBytes, name: 'doc.jpg', path: '/tmp/doc.jpg');
        final picker = _FakeImagePicker(fileToReturn: fakeFile);
        final helper = CameraHelper(picker: picker);

        final ine = await helper.captureIne(ImageSource.camera);
        expect(picker.lastPreferredDevice, CameraDevice.rear);
        expect(picker.lastSource, ImageSource.camera);
        expect(ine?.name, 'doc.jpg');
        expect(ine?.bytes, fakeBytes);

        await helper.captureSelfie(ImageSource.camera);
        expect(picker.lastPreferredDevice, CameraDevice.front);

        await helper.captureCatalogPhoto(ImageSource.gallery);
        expect(picker.lastPreferredDevice, CameraDevice.rear);
        expect(picker.lastSource, ImageSource.gallery);

        final emptyHelper = CameraHelper(picker: _FakeImagePicker());
        expect(await emptyHelper.captureIne(ImageSource.camera), isNull);
      },
    );
  });
}
