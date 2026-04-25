import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/cleaner_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PermissionStatus? _storageStatus;
  PermissionStatus? _photosStatus;
  PermissionStatus? _videosStatus;
  PermissionStatus? _audioStatus;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final statuses = await Future.wait([
      Permission.storage.status,
      Permission.photos.status,
      Permission.videos.status,
      Permission.audio.status,
    ]);

    if (!mounted) return;
    setState(() {
      _storageStatus = statuses[0];
      _photosStatus = statuses[1];
      _videosStatus = statuses[2];
      _audioStatus = statuses[3];
    });
  }

  Future<void> _requestPermission() async {
    await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    await _refreshStatus();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CleanerProvider>();

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
            child: ListTile(
              leading: const Icon(Icons.lock_open_outlined),
              title: const Text('Permissions stockage/media'),
              subtitle: Text(
                'Stockage: ${_statusLabel(_storageStatus)}\n'
                'Photos: ${_statusLabel(_photosStatus)}\n'
                'Videos: ${_statusLabel(_videosStatus)}\n'
                'Audio: ${_statusLabel(_audioStatus)}',
              ),
              isThreeLine: true,
              trailing: FilledButton.tonal(
                onPressed: _requestPermission,
                child: const Text('Demander'),
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
