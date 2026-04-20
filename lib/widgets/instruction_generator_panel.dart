import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/export_service.dart';
import '../state/bead_editor_state.dart';

class InstructionGeneratorPanel extends StatefulWidget {
  const InstructionGeneratorPanel({super.key});

  @override
  State<InstructionGeneratorPanel> createState() =>
      _InstructionGeneratorPanelState();
}

class _InstructionGeneratorPanelState extends State<InstructionGeneratorPanel> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instruction Generator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _exportText(editor.instructions),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Export TXT'),
                ),
                FilledButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _exportPdf(editor.instructions),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _exportObj(editor),
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Export OBJ'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      editor.instructions,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportText(String instructions) async {
    await _withExporting(() async {
      final path = await ExportService.exportText(instructions);
      _showResult('Text exported to:\n$path');
    });
  }

  Future<void> _exportPdf(String instructions) async {
    await _withExporting(() async {
      final path = await ExportService.exportPdf(instructions);
      _showResult('PDF exported to:\n$path');
    });
  }

  Future<void> _exportObj(BeadEditorState editor) async {
    await _withExporting(() async {
      final path = await ExportService.exportObj(editor.placements);
      _showResult('OBJ exported to:\n$path');
    });
  }

  Future<void> _withExporting(Future<void> Function() action) async {
    setState(() => _exporting = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _showResult(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
