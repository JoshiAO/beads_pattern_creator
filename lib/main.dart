import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/bead_editor_state.dart';
import 'widgets/bead_palette.dart';
import 'widgets/instruction_generator_panel.dart';
import 'widgets/mesh_canvas_3d.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BeadEditorState()..initialize(),
      child: const BeadPatternApp(),
    ),
  );
}

class BeadPatternApp extends StatelessWidget {
  const BeadPatternApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Bead Pattern Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7A5C)),
        useMaterial3: true,
      ),
      home: const BeadEditorScreen(),
    );
  }
}

class BeadEditorScreen extends StatelessWidget {
  const BeadEditorScreen({super.key});

  Future<void> _openBeadPaletteModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BeadPalette(showCard: false),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openExportModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: InstructionGeneratorPanel(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Bead Pattern Generator'),
        actions: [
          IconButton(
            tooltip: 'Bead palette',
            onPressed: () => _openBeadPaletteModal(context),
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'Export',
            onPressed: () => _openExportModal(context),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: editor.canUndo ? editor.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: editor.canRedo ? editor.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: 'Clear all beads',
            onPressed: editor.clearAll,
            icon: const Icon(Icons.layers_clear_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return const MeshCanvas3D();
        },
      ),
    );
  }
}

// Removed unused _LeftPanel class
