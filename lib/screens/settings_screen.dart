import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/cleaner_provider.dart';
import '../services/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<Permission, PermissionStatus> _statuses = const {};

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final statusMap = await context.read<PermissionService>().checkStatuses();
    if (!mounted) return;
    setState(() {
      _statuses = statusMap;
    });
  }

  Future<void> _requestPermission() async {
    await context.read<PermissionService>().requestRequired();
    await _refreshStatus();
  }

  Future<void> _openAndroidSettings() async {
    await openAppSettings();
  }

  Future<void> _openFolderPicker() async {
    await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisir un dossier utilisateur',
    );
  }

  String _statusLabel(PermissionStatus? status) {
    if (status == null) return 'Inconnu';
    if (status.isGranted || status.isLimited) return 'Accordee';
    if (status.isPermanentlyDenied) return 'Refusee en permanence';
    return 'Non accordee';
  }

  String _permissionName(Permission permission) {
    if (permission == Permission.storage) {
      return 'Stockage';
    }
    if (permission == Permission.photos) {
      return 'Photos';
    }
    if (permission == Permission.videos) {
      return 'Videos';
    }
    if (permission == Permission.audio) {
      return 'Audio';
    }
    return permission.toString();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();
    final hasPermanentDenied = _statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode securite',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Active par defaut. Bloque les chemins sensibles et limite les suppressions risquées.',
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: provider.safeModeEnabled,
                    onChanged: (value) {
                      if (value) {
                        provider.setSafeMode(true);
                        return;
                      }
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Desactiver le mode securite ?'),
                          content: const Text(
                            'Cela peut augmenter les risques de suppression non voulue. '
                            'Confirmez uniquement si vous comprenez les consequences.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () {
                                provider.setSafeMode(false);
                                Navigator.pop(context);
                              },
                              child: const Text('Confirmer'),
                            ),
                          ],
                        ),
                      );
                    },
                    title: const Text('Mode securite actif'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode de scan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Le mode reel analyse les fichiers accessibles Android. '
                    'Si inaccessible, l\'application bascule en mode simule.',
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: provider.realScanEnabled,
                    onChanged: provider.setRealScanEnabled,
                    title: const Text('Scan reel Android (beta)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_open_outlined),
                    title: const Text('Permissions requises (selon Android)'),
                    subtitle: Text(
                      _statuses.isEmpty
                          ? 'Aucune permission requise ou statut indisponible.'
                          : _statuses.entries
                                .map(
                                  (entry) =>
                                      '${_permissionName(entry.key)}: ${_statusLabel(entry.value)}',
                                )
                                .join('\n'),
                    ),
                    isThreeLine: _statuses.length > 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _requestPermission,
                        child: const Text('Demander'),
                      ),
                      if (hasPermanentDenied) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _openAndroidSettings,
                          child: const Text('Ouvrir reglages Android'),
                        ),
                      ],
                    ],
                  ),
                  if (hasPermanentDenied) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Une permission est refusee en permanence. '
                      'Ouvrez les reglages Android pour l\'autoriser manuellement.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Choisir un dossier utilisateur'),
              subtitle: const Text(
                'Selection manuelle pour futures extensions de scan cible.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openFolderPicker,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limites Android (important)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Certains dossiers sont proteges par Android et restent inaccessibles.\n'
                    '- Les fichiers systeme ne sont jamais cibles.\n'
                    '- Aucune promesse de boost RAM ou acceleration magique.\n'
                    '- Toute suppression necessite une confirmation explicite.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
