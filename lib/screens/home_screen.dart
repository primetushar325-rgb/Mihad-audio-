import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/project.dart';
import '../services/media_picker_service.dart';
import '../state/projects_library_provider.dart';
import '../widgets/mihad_logo.dart';
import '../widgets/pick_feedback.dart';
import '../widgets/project_card.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'template_gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = MediaPickerService();
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version} (${info.buildNumber})');
      }
    });
  }

  Future<void> _createProject() async {
    final name = await _promptForName(context, title: 'New project name');
    if (name == null || !mounted) return;

    final library = context.read<ProjectsLibraryProvider>();
    final project = await library.createProject(name);
    if (!mounted) return;

    final videoPath = await resolvePick(context, _picker.pickVideo());
    if (videoPath != null) {
      project.sourceVideoPath = videoPath;
      await library.upsert(project);
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(projectId: project.id)),
    );
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
  }) {
    final controller = TextEditingController(text: 'My Project');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MihadColors.surfaceElevated,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameProject(Project project) async {
    final name = await _promptForName(context, title: 'Rename project');
    if (name == null || name.trim().isEmpty || !mounted) return;
    await context.read<ProjectsLibraryProvider>().rename(project.id, name);
  }

  Future<void> _deleteProject(Project project) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MihadColors.surfaceElevated,
        title: const Text('Delete project?'),
        content: Text(
          'This removes "${project.name}" from MIHAD AUDIO. '
          'Exported videos already saved to your device are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MihadColors.danger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProjectsLibraryProvider>().delete(project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ProjectsLibraryProvider>();
    final recents = library.projectsByRecent;
    final exports = library.allExports;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const MihadLogo(size: 52),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MIHAD AUDIO',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Offline audio visualizer video editor',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: MihadColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createProject,
                icon: const Icon(Icons.add),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Create New Project'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TemplateGalleryScreen(),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Browse Template Gallery'),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Recent Projects', count: recents.length),
            const SizedBox(height: 12),
            if (recents.isEmpty)
              const _EmptyHint(text: 'Your projects will appear here.')
            else
              ...recents.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProjectCard(
                    project: p,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(projectId: p.id),
                      ),
                    ),
                    onRename: () => _renameProject(p),
                    onDelete: () => _deleteProject(p),
                  ),
                ),
              ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'My Exports', count: exports.length),
            const SizedBox(height: 12),
            if (exports.isEmpty)
              const _EmptyHint(text: 'Exported videos will appear here.')
            else
              ...exports
                  .take(10)
                  .map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.video_file_outlined,
                          color: MihadColors.accentPrimary,
                        ),
                        title: Text(
                          entry.value.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'From "${entry.key.name}"',
                          style: const TextStyle(
                            color: MihadColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _version.isEmpty ? ' ' : 'MIHAD AUDIO $_version',
                style: const TextStyle(
                  color: MihadColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: MihadColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: MihadColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MihadColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22252F)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: MihadColors.textSecondary, fontSize: 13),
      ),
    );
  }
}
