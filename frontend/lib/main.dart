import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/context_screen.dart';
import 'screens/results_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AdForgeApp());
}

class AdForgeApp extends StatelessWidget {
  const AdForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is essential to provide the AppProvider to the whole app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Ad-Forge',
        theme: AppTheme.darkTheme, // Using your custom theme
        home: const MainNavScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// MainNavScreen is now simpler and controlled by the provider
class MainNavScreen extends StatelessWidget {
  const MainNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget listens for changes in the AppProvider
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: PageView(
            controller: provider.pageController,
            // Prevent user from swiping between pages manually
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              ScannerScreen(),
              ContextScreen(),
              ResultsScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1F1F3A), width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: provider.selectedIndex,
              onTap: (index) => provider.goToTab(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: const Color(0xFF0F0F23),
              selectedItemColor: const Color(0xFF6366F1),
              unselectedItemColor: Colors.grey,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.article), label: 'Context'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle), label: 'Results'),
              ],
            ),
          ),
        );
      },
    );
  }
}
