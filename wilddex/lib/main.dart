import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_data.dart';
import 'screens/dex_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/camera_host.dart';
import 'screens/park_field_guide_screen.dart';
import 'screens/gallery_screen.dart';
import 'utils/user_data_provider.dart';
import 'utils/settings_provider.dart';
import 'theme/colors.dart';
import 'species_loader.dart';
import 'utils/badge_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appData = await loadAppData();
  runApp(MyApp(appData: appData));
}

class MyApp extends StatelessWidget {
  final AppData appData;
  const MyApp({super.key, required this.appData});

  ThemeData _buildTheme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        background: AppColors.background,
        onPrimary: AppColors.foreground,
        onBackground: AppColors.text,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.text),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: appData,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => UserDataProvider()..initialize(),
          ),
          ChangeNotifierProvider(
            create: (context) => SettingsProvider()..initialize(),
          ),
        ],
        child: MaterialApp(
          title: 'WildDex',
          theme: _buildTheme(),
          home: const MainScreen(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);
    BadgeEngine.syncAwards(context);
    final speciesList =
        settings.useCoreDex ? appData.coreSpeciesList : appData.speciesList;
    final taxaList = appData.taxaList;

    final screens = [
      DexScreen(
        key: ValueKey('dex_${settings.useCoreDex}'),
        speciesList: speciesList,
        taxaList: taxaList,
      ),
      const CameraTabHost(),
      ParkFieldGuideScreen(
        key: ValueKey('field_${settings.useCoreDex}'),
        speciesList: speciesList,
        taxaList: taxaList,
      ),
      const GalleryScreen(),
      ProfileScreen(
        key: ValueKey('profile_${settings.useCoreDex}'),
        speciesList: speciesList,
        taxaList: taxaList,
      ),
    ];
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Dex'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'Camera'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Guides'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: 'Gallery'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

