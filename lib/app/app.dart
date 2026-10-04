import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../services/storage_service.dart';
import '../state/app_settings_provider.dart';
import '../state/projects_library_provider.dart';
import 'theme.dart';

class MihadAudioApp extends StatelessWidget {
  const MihadAudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<ProjectsLibraryProvider>(
          create: (_) => ProjectsLibraryProvider(storageService)..load(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(storageService)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'MIHAD AUDIO',
        debugShowCheckedModeBanner: false,
        theme: buildMihadTheme(),
        darkTheme: buildMihadTheme(),
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
