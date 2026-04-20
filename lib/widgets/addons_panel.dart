import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bead_editor_state.dart';

class AddOnsPanel extends StatelessWidget {
  const AddOnsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: editor.addOnStyleOptions.map((style) {
            return ChoiceChip(
              label: Text(editor.addOnStyleLabel(style)),
              selected: editor.addOnStyle == style,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => editor.setAddOnStyle(style),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        _AddOnTile(
          label: 'Ear',
          enabled: editor.earEnabled,
          onEnabledChanged: editor.setEarEnabled,
          points: editor.earPoints,
          onPointsChanged: editor.setEarPoints,
          tightness: editor.earTightness,
          onTightnessChanged: editor.setEarTightness,
          minPoints: 3,
          maxPoints: 6,
        ),
        _AddOnTile(
          label: 'Arms',
          enabled: editor.armsEnabled,
          onEnabledChanged: editor.setArmsEnabled,
          points: editor.armsPoints,
          onPointsChanged: editor.setArmsPoints,
          tightness: editor.armsTightness,
          onTightnessChanged: editor.setArmsTightness,
          minPoints: 3,
          maxPoints: 6,
        ),
        _AddOnTile(
          label: 'Tail',
          enabled: editor.tailEnabled,
          onEnabledChanged: editor.setTailEnabled,
          points: editor.tailPoints,
          onPointsChanged: editor.setTailPoints,
          tightness: editor.tailTightness,
          onTightnessChanged: editor.setTailTightness,
          minPoints: 3,
          maxPoints: 6,
        ),
        _AddOnTile(
          label: 'Foot',
          enabled: editor.footEnabled,
          onEnabledChanged: editor.setFootEnabled,
          points: editor.footPoints,
          onPointsChanged: editor.setFootPoints,
          tightness: editor.footTightness,
          onTightnessChanged: editor.setFootTightness,
          minPoints: 1,
          maxPoints: 3,
        ),
        if (editor.footEnabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Foot count: ${editor.footCount}'),
              Slider(
                value: editor.footCount.toDouble(),
                min: 2,
                max: 4,
                divisions: 2,
                label: '${editor.footCount}',
                onChanged: (v) => editor.setFootCount(v.toInt()),
              ),
            ],
          ),
      ],
    );
  }
}

class _AddOnTile extends StatelessWidget {
  final String label;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final int points;
  final ValueChanged<int> onPointsChanged;
  final double tightness;
  final ValueChanged<double> onTightnessChanged;
  final int minPoints;
  final int maxPoints;

  const _AddOnTile({
    required this.label,
    required this.enabled,
    required this.onEnabledChanged,
    required this.points,
    required this.onPointsChanged,
    required this.tightness,
    required this.onTightnessChanged,
    required this.minPoints,
    required this.maxPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Switch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
        if (enabled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('  Points: $points'),
              Slider(
                value: points.toDouble(),
                min: minPoints.toDouble(),
                max: maxPoints.toDouble(),
                divisions: maxPoints - minPoints,
                label: '$points',
                onChanged: (v) => onPointsChanged(v.toInt()),
              ),
              Text('  Tightness: ${(tightness * 100).round()}%'),
              Slider(
                value: tightness,
                min: 0.65,
                max: 1.20,
                divisions: 11,
                label: '${(tightness * 100).round()}%',
                onChanged: onTightnessChanged,
              ),
            ],
          ),
      ],
    );
  }
}
