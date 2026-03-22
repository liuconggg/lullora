import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/main_navigation_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }
  
  // Remove splash screen
  FlutterNativeSplash.remove();
  
  runApp(
    const ProviderScope(
      child: LulloraApp(),
    ),
  );
}

class LulloraApp extends StatelessWidget {
  const LulloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        title: 'Lullora Sleep Study',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthenticationWrapper(),
        routes: {
          '/main': (context) => const MainNavigationScreen(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
