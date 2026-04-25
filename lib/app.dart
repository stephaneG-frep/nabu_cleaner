import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cleaner_provider.dart';
import 'screens/shell_screen.dart';
import 'services/duplicate_detector_service.dart';
import 'services/export_service.dart';
import 'services/file_delete_service.dart';
import 'services/history_service.dart';
import 'services/permission_service.dart';
import 'services/storage_scan_service.dart';
import 'theme/app_theme.dart';

class NabuCleanerApp extends StatelessWidget {
  const NabuCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => StorageScanService()),
        Provider(create: (_) => FileDeleteService()),
        Provider(create: (_) => DuplicateDetectorService()),
        Provider(create: (_) => HistoryService()),
        Provider(create: (_) => ExportService()),
        Provider(create: (_) => PermissionService()),
        ChangeNotifierProvider(
          create: (context) => CleanerProvider(
            storageScanService: context.read<StorageScanService>(),
            fileDeleteService: context.read<FileDeleteService>(),
            duplicateDetectorService: context.read<DuplicateDetectorService>(),
            historyService: context.read<HistoryService>(),
            exportService: context.read<ExportService>(),
            permissionService: context.read<PermissionService>(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Nabu Cleaner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const ShellScreen(),
      ),
    );
  }
}
