import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/file_category.dart';
import '../models/scan_file_item.dart';

class FileResultTile extends StatelessWidget {
  const FileResultTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onChanged,
    this.recommended = false,
  });

  final ScanFileItem item;
  final bool selected;
  final bool recommended;
  final ValueChanged<bool> onChanged;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat(
      'dd/MM/yyyy - HH:mm',
      'fr_FR',
    ).format(item.modifiedAt);

    return Card(
      margin: EdgeInsets.zero,
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onChanged(v ?? false),
        secondary: const Icon(Icons.insert_drive_file_outlined),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${item.category.label} • ${_formatBytes(item.sizeBytes)}'),
            Text('Date: $dateLabel'),
            if (recommended)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Recommande a supprimer',
                  style: TextStyle(
                    color: Color(0xFF2EAF61),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (item.isSystemFile)
              const Text(
                'Fichier systeme protege',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
