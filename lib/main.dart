import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  runApp(
    MultiProvider(
      providers: buildAppProviders(),
      child: ManoLocalApp(router: sl<GoRouter>()),
    ),
  );
}
