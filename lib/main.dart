import 'package:flutter/material.dart';
import 'package:pixelshot_flutter/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:pixelshot_flutter/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: MaterialApp(
        title: 'Skarmy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D1B2A), // Dark Blue
            primary: const Color(0xFF0D1B2A),
            secondary: Colors.blue.shade100,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
