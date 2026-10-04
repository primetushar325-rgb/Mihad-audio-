import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/export_settings.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../state/app_settings_provider.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/mihad_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  int? _cacheBytes;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refreshCacheSize();
  }

  Future<void> _refreshCacheSize() async {
    final bytes = await _storage.temporaryStorageUsageBytes();
    if (mounted) setState(() => _cacheBytes = bytes);
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '...';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettingsProvider>();
    final settings = appSettings.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Appearance'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.dark_mode, color: MihadColors.accentPrimary),
              title: Text('Theme'),
              subtitle: Text(
                'Dark (MIHAD AUDIO is designed dark-first for editing)',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Export defaults'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default resolution'),
                  trailing: DropdownButton<ExportResolutionPreset>(
                    value: settings.defaultResolution,
                    dropdownColor: MihadColors.surfaceElevated,
                    underline: const SizedBox.shrink(),
                    items: ExportResolutionPreset.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      appSettings.update(
                        (s) => AppSettings(
                          defaultResolution: value,
                          defaultFps: s.defaultFps,
                          defaultPrimaryColorValue: s.defaultPrimaryColorValue,
                          previewQuality: s.previewQuality,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default frame rate'),
                  trailing: DropdownButton<ExportFpsPreset>(
                    value: settings.defaultFps,
                    dropdownColor: MihadColors.surfaceElevated,
                    underline: const SizedBox.shrink(),
                    items: ExportFpsPreset.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      appSettings.update(
                        (s) => AppSettings(
                          defaultResolution: s.defaultResolution,
                          defaultFps: value,
                          defaultPrimaryColorValue: s.defaultPrimaryColorValue,
                          previewQuality: s.previewQuality,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default visualizer color'),
                  trailing: GestureDetector(
                    onTap: () async {
                      final color = await showMihadColorPicker(
                        context,
                        settings.defaultPrimaryColorValue,
                      );
                      if (color != null) {
                        appSettings.update(
                          (s) => AppSettings(
                            defaultResolution: s.defaultResolution,
                            defaultFps: s.defaultFps,
                            defaultPrimaryColorValue: color,
                            previewQuality: s.previewQuality,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(settings.defaultPrimaryColorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Preview'),
          Card(
            child: ListTile(
              title: const Text('Preview quality'),
              subtitle: const Text(
                'Lower quality analyzes audio faster on slower devices',
              ),
              trailing: DropdownButton<PreviewQuality>(
                value: settings.previewQuality,
                dropdownColor: MihadColors.surfaceElevated,
                underline: const SizedBox.shrink(),
                items: PreviewQuality.values
                    .map(
                      (e) => DropdownMenuItem(value: e, child: Text(e.label)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  appSettings.update(
                    (s) => AppSettings(
                      defaultResolution: s.defaultResolution,
                      defaultFps: s.defaultFps,
                      defaultPrimaryColorValue: s.defaultPrimaryColorValue,
                      previewQuality: value,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Storage'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Temporary files'),
                  subtitle: Text(
                    '${_formatBytes(_cacheBytes)} used by '
                    'in-progress render/analysis cache',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _clearing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.delete_sweep_outlined,
                          color: MihadColors.danger,
                        ),
                  title: const Text('Clear temporary files'),
                  onTap: _clearing
                      ? null
                      : () async {
                          setState(() => _clearing = true);
                          await _storage.clearTemporaryFiles();
                          await _refreshCacheSize();
                          if (mounted) setState(() => _clearing = false);
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: MihadLogo(size: 36),
                  title: Text('MIHAD AUDIO'),
                  subtitle: Text(
                    'Offline audio visualizer video editor. No account, '
                    'no cloud, no ads - all processing happens on this '
                    'device.',
                  ),
                ),
                const Divider(height: 1),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data == null
                        ? '...'
                        : '${snapshot.data!.version} (${snapshot.data!.buildNumber})';
                    return ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('App version'),
                      trailing: Text(
                        version,
                        style: const TextStyle(
                          color: MihadColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licenses'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'MIHAD AUDIO',
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8),
                      child: MihadLogo(size: 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: MihadColors.textSecondary,
        ),
      ),
    );
  }
}
