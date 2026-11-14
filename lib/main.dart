import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/repository.dart';
import 'screens/home_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/shapes_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );
  await Future.wait([StyleRepository.instance.load(), AppState.instance.load()]);
  runApp(const FaceFitApp());
}

class FaceFitApp extends StatelessWidget {
  const FaceFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'FaceFit', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const MainShell());
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onBrowseShapes: () => setState(() => _index = 1)),
          const ShapesScreen(),
          const SavedScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.center_focus_weak_outlined),
              selectedIcon: Icon(Icons.center_focus_strong),
              label: 'Analiz',
            ),
            NavigationDestination(icon: Icon(Icons.face_outlined), selectedIcon: Icon(Icons.face), label: 'Yüz Şekilleri'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Kaydedilenler'),
          ],
        ),
      ),
    );
  }
}
