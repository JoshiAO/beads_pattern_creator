import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bead_type.dart';
import '../state/bead_editor_state.dart';
import 'color_picker_screen.dart';

class BeadPalette extends StatelessWidget {
  const BeadPalette({super.key, this.showCard = true});

  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bead Palette',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(editor.paletteSlots.length, (index) {
                final isSelected = index == editor.selectedSlotIndex;
                final color = editor.paletteSlots[index];
                return GestureDetector(
                  onTap: () => editor.setSelectedSlot(index),
                  onLongPress: () =>
                      _editPaletteSlotColor(context, editor, index),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black.withValues(alpha: 0.12),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Text('Selected size: ${editor.sizeLabelMm(editor.selectedSizeMm)}'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: editor.sizeOptionsMm.map((mm) {
                return ChoiceChip(
                  label: Text('${mm}mm'),
                  selected: editor.selectedSizeMm == mm,
                  onSelected: (_) => editor.setSelectedSizeMm(mm),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Vertices points'),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: editor.decreaseMeshVertices,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${editor.meshVertices}'),
                IconButton(
                  onPressed: editor.increaseMeshVertices,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              'Surface points: ${editor.surfacePointCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            const Text('Mesh shape'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: editor.meshShapeOptions.map((shape) {
                return ChoiceChip(
                  label: Text(editor.meshShapeLabel(shape)),
                  selected: editor.selectedMeshShape == shape,
                  onSelected: (_) => editor.setSelectedMeshShape(shape),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            LongPressDraggable<BeadType>(
              data: editor.selectedType,
              feedback: _dragFeedback(editor.selectedColor),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _selectedBeadChip(editor.selectedColor, editor),
              ),
              child: _selectedBeadChip(editor.selectedColor, editor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPaletteSlotColor(
                      context,
                      editor,
                      editor.selectedSlotIndex,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Color'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => editor.savePaletteSettings(),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to select a color slot, long-press a slot to edit its color, and long-press-drag selected bead to place it on the mesh.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    if (!showCard) {
      return content;
    }

    return Card(child: content);
  }

  Widget _selectedBeadChip(Color color, BeadEditorState editor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'Drag selected bead (${editor.sizeLabelMm(editor.selectedSizeMm)})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _dragFeedback(Color color) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPaletteSlotColor(
    BuildContext context,
    BeadEditorState editor,
    int slotIndex,
  ) async {
    final picked = await _showColorPickerScreen(
      context,
      editor.paletteSlots[slotIndex],
    );
    if (picked == null) return;
    editor.updatePaletteSlot(slotIndex, picked);
    editor.setSelectedSlot(slotIndex);
    await editor.savePaletteSettings();
  }

  Future<Color?> _showColorPickerScreen(
    BuildContext context,
    Color initialColor,
  ) async {
    return Navigator.of(context).push<Color>(
      MaterialPageRoute(
        builder: (_) => ColorPickerScreen(initialColor: initialColor),
      ),
    );
  }
}
