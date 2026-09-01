import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/verificacao_provider.dart';
import 'screens/verificacoes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VerificacaoProvider(),
      child: MaterialApp(
        title: 'Gerenciador de Verificações',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1F2A3C),
            onPrimary: Colors.white,
            secondary: Color(0xFFBA1636),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1F2A3C),
            error: Color(0xFFC62828),
          ),
          scaffoldBackgroundColor: const Color(0xFFEEEADD),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1F2A3C),
            surfaceTintColor: Colors.white,
            elevation: 1,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFBA1636),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: Colors.white,
            shadowColor: const Color(0xFF1F2A3C).withValues(alpha: 0.15),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        home: const VerificacoesScreen(),
      ),
    );
  }
}
