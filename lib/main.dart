import 'package:flutter/material.dart';

import 'services/mesh_service.dart';
import 'services/store.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

/// Simple app-wide access to services without a DI package.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.mesh,
    required super.child,
  });

  final Store store;
  final MeshService mesh;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      old.store != store || old.mesh != mesh;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store();
  await store.init();
  final mesh = MeshService(store);
  runApp(MeshApp(store: store, mesh: mesh));
}

class MeshApp extends StatelessWidget {
  const MeshApp({super.key, required this.store, required this.mesh});
  final Store store;
  final MeshService mesh;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6D5DF6);

    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: b),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
          ),
        );

    return AppScope(
      store: store,
      mesh: mesh,
      child: MaterialApp(
        title: 'Mesh',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        home: AnimatedBuilder(
          animation: store,
          builder: (_, __) => store.profile.isComplete
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
