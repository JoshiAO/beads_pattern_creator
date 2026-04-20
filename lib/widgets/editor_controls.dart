import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bead_editor_state.dart';

class EditorControls extends StatelessWidget {
  const EditorControls({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _cameraSlider('Yaw', editor.yaw, -180, 180, editor.setCameraYaw),
              _cameraSlider(
                'Pitch',
                editor.pitch,
                -80,
                80,
                editor.setCameraPitch,
              ),
              _cameraSlider('Zoom', editor.zoom, 6, 40, editor.setCameraZoom),
              const SizedBox(height: 12),
              Text(
                'Layer: ${editor.activeLayer + 1}/${editor.gridZ}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Slider(
                value: editor.activeLayer.toDouble(),
                min: 0,
                max: (editor.gridZ - 1).toDouble(),
                divisions: editor.gridZ - 1,
                label: '${editor.activeLayer + 1}',
                onChanged: (v) => editor.setActiveLayer(v.toInt()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: editor.resetCamera,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Reset Camera'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
