import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

// ▼▼▼ УБЕДИСЬ, ЧТО ЭТИ ИМПОРТЫ ОСТАЛИСЬ ▼▼▼
import 'widgets/connectivity_wrapper.dart';
import 'firebase_options.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/root_shell.dart';
import 'screens/direction_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/debug_data_screen.dart';
// ▼▼▼ А ЭТИ НАМ ЗДЕСЬ БОЛЬШЕ НЕ НУЖНЫ (мы перенесем их) ▼▼▼
// import 'models/user.dart';
// import 'models/place.dart';
// import 'models/region.dart';
// import 'services/favorites_service.dart';
// import 'services/likes_service.dart';
// import 'services/json_import_service.dart';
// import 'services/firebase_data_service.dart';

// Импорт kIsWeb
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ▼▼▼ ЕДИНСТВЕННАЯ ОПЕРАЦИЯ HIVE ЗДЕСЬ ▼▼▼
  await Hive.initFlutter();
  // ▲▲▲ ВСЕ ОСТАЛЬНОЕ (OPENBOX, ADAPTERS, INIT СЕРВИСОВ) МЫ УБРАЛИ ▲▲▲

  runApp(const KazakhstanTravelApp());
}

class KazakhstanTravelApp extends StatelessWidget {
  const KazakhstanTravelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kazakhstan Travel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      routes: {
        '/directions': (_) => const DirectionsScreen(),
        '/profile': (_) => const UserProfileScreen(),
        '/admin': (_) => const AdminPanelScreen(),
        '/debug': (_) => const DebugDataScreen(),
      },
      home: const ConnectivityWrapper(
        child: AuthGate(),
      ),
    );
  }
}



class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  
  late final StreamSubscription<fb.User?> _authSubscription;
  
  fb.User? _currentUser;
  
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen((fb.User? user) {
      
      setState(() {
        _currentUser = user; 
        _isInitialized = true; 
      });
    });
  }

  @override
  void dispose() {
    
    
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    
    if (_currentUser == null) {
      return const LoginScreen();
    }
    
    else {
      return const LoadingScreen();
    }
  }
}
