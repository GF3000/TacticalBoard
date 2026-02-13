import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/tactical_board.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations to landscape
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    // Enable edge-to-edge mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    runApp(const TacticalBoardApp());
  });
}

class TacticalBoardApp extends StatelessWidget {
  const TacticalBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandBoard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: TacticalBoard(),
        ),
      ),
    );
  }
}
