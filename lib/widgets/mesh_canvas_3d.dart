import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../models/bead_type.dart';
import '../services/mesh_factory.dart';
import '../state/bead_editor_state.dart';
import 'addons_panel.dart';

class MeshCanvas3D extends StatefulWidget {
  const MeshCanvas3D({super.key});

  @override
  State<MeshCanvas3D> createState() => _MeshCanvas3DState();
}

class _MeshCanvas3DState extends State<MeshCanvas3D> {
  final GlobalKey _dropAreaKey = GlobalKey();

  Scene? _scene;
  Object? _gridRoot;
  Object? _beadRoot;
  int _lastRevision = -1;
  int _lastCameraRevision = -1;
  double _gestureStartZoom = 18;

  Future<void> _openAddOnsModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.34,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: const [0.34, 0.58, 0.78, 0.94],
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                        child: AddOnsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<BeadEditorState>();

    if (_scene != null && _lastRevision != editor.sceneRevision) {
      _syncFromState(editor);
    }
    if (_scene != null && _lastCameraRevision != editor.cameraRevision) {
      _updateCamera(editor);
      _lastCameraRevision = editor.cameraRevision;
    }

    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          DragTarget<BeadType>(
            onAcceptWithDetails: (details) => _handleDrop(details, editor),
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTapUp: editor.eraseMode
                    ? (details) => _removeByTap(details.localPosition, editor)
                    : null,
                onScaleStart: (details) {
                  _gestureStartZoom = editor.zoom;
                },
                onScaleUpdate: (details) {
                  // One-finger drag: orbit camera.
                  if (details.pointerCount <= 1) {
                    editor.setCameraYaw(
                      editor.yaw + (details.focalPointDelta.dx * 0.35),
                    );
                    editor.setCameraPitch(
                      editor.pitch - (details.focalPointDelta.dy * 0.25),
                    );
                    return;
                  }

                  // Two-finger pinch: zoom. Two-finger drag: pan target.
                  editor.setCameraZoom(_gestureStartZoom / details.scale);
                  editor.setPanX(
                    editor.panX + (details.focalPointDelta.dx * 0.02),
                  );
                  editor.setPanY(
                    editor.panY - (details.focalPointDelta.dy * 0.02),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  key: _dropAreaKey,
                  color: const Color(0xFFEAF4EF),
                  child: Cube(
                    onSceneCreated: (scene) {
                      _scene = scene;
                      _gridRoot = Object(name: 'gridRoot', scene: scene);
                      _beadRoot = Object(name: 'beadRoot', scene: scene);
                      scene.world.add(_gridRoot!);
                      scene.world.add(_beadRoot!);
                      _updateCamera(editor);
                      _lastCameraRevision = editor.cameraRevision;
                      _syncFromState(editor);
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 10,
            top: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  editor.eraseMode
                      ? 'Erase mode: tap a bead on the surface to remove it.'
                      : 'Drag bead from bottom selector and drop on the shape surface.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            child: _EditToolsOverlay(editor: editor),
          ),
          Positioned(
            right: 10,
            top: 110,
            child: _CameraIconDock(editor: editor),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: _InCanvasBeadPalette(
              editor: editor,
              onOpenAddOns: () => _openAddOnsModal(context),
            ),
          ),
        ],
      ),
    );
  }

  void _syncFromState(BeadEditorState editor) {
    final scene = _scene;
    final gridRoot = _gridRoot;
    final beadRoot = _beadRoot;
    if (scene == null || gridRoot == null || beadRoot == null) return;

    gridRoot.children.clear();
    beadRoot.children.clear();

    final detail = editor.meshVertices;

    final guideMesh = _buildGuideMesh(editor, detail);
    if (guideMesh != null) {
      gridRoot.add(
        Object(
          mesh: guideMesh,
          lighting: false,
          backfaceCulling: false,
          position: vmath.Vector3(
            (editor.gridX - 1) / 2,
            (editor.gridY - 1) / 2,
            (editor.gridZ - 1) / 2,
          ),
        ),
      );
    }

    final ghostMesh = MeshFactory.createSphere(
      radius: 0.10,
      color: const Color(0x55333333),
      latSegments: math.max(4, detail ~/ 2),
      lonSegments: math.max(6, detail),
    );

    for (final point in editor.surfacePoints) {
      gridRoot.add(
        Object(
          mesh: ghostMesh,
          lighting: false,
          backfaceCulling: true,
          position: vmath.Vector3(
            point.$1.toDouble(),
            point.$2.toDouble(),
            point.$3.toDouble(),
          ),
        ),
      );
    }

    for (final bead in editor.placements) {
      final mesh = MeshFactory.createSphere(
        radius: bead.size,
        color: Color(bead.colorValue),
        latSegments: detail,
        lonSegments: detail + 2,
      );
      beadRoot.add(
        Object(
          mesh: mesh,
          lighting: editor.shadowEnabled,
          backfaceCulling: true,
          position: vmath.Vector3(
            bead.x.toDouble(),
            bead.y.toDouble(),
            bead.z.toDouble(),
          ),
        ),
      );
    }

    scene.updateTexture();
    scene.update();
    _lastRevision = editor.sceneRevision;
  }

  Mesh? _buildGuideMesh(BeadEditorState editor, int detail) {
    final inset = 0.6;
    final radiusX = ((editor.gridX - 1) / 2) - inset;
    final radiusY = ((editor.gridY - 1) / 2) - inset;
    final radiusZ = ((editor.gridZ - 1) / 2) - inset;
    if (radiusX <= 0 || radiusY <= 0 || radiusZ <= 0) return null;

    const guideColor = Color(0x3346A3FF);

    switch (editor.selectedMeshShape) {
      case MeshShape.sphere:
        final r = math.min(radiusX, math.min(radiusY, radiusZ));
        return MeshFactory.createSphere(
          radius: r,
          color: guideColor,
          latSegments: math.max(8, detail),
          lonSegments: math.max(10, detail + 2),
        );
      case MeshShape.cube:
        return MeshFactory.createCube(
          width: radiusX * 2,
          height: radiusY * 2,
          depth: radiusZ * 2,
          color: guideColor,
        );
      case MeshShape.cylinder:
        final r = math.min(radiusX, radiusY);
        return MeshFactory.createCylinder(
          radius: r,
          height: radiusZ * 2,
          color: guideColor,
          segments: math.max(16, detail + 4),
        );
      case MeshShape.diamond:
        return MeshFactory.createDiamond(
          radiusX: radiusX,
          radiusY: radiusY,
          radiusZ: radiusZ,
          color: guideColor,
        );
    }
  }

  void _updateCamera(BeadEditorState editor) {
    final scene = _scene;
    if (scene == null) return;

    final yaw = editor.yaw * math.pi / 180;
    final pitch = editor.pitch * math.pi / 180;
    final radius = editor.zoom;

    final target = vmath.Vector3(
      ((editor.gridX - 1) / 2) + editor.panX,
      ((editor.gridY - 1) / 2) + editor.panY,
      editor.activeLayer.toDouble() + editor.panZ,
    );

    final position = vmath.Vector3(
      target.x + radius * math.cos(pitch) * math.sin(yaw),
      target.y + radius * math.sin(pitch),
      target.z - radius * math.cos(pitch) * math.cos(yaw),
    );

    scene.camera.position.setFrom(position);
    scene.camera.target.setFrom(target);
    scene.update();
  }

  void _handleDrop(
    DragTargetDetails<BeadType> details,
    BeadEditorState editor,
  ) {
    final box = _dropAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.offset);
    final snapped = _snapToSurfaceFromScreen(local, box.size, editor);
    editor.placeBead(
      x: snapped.$1,
      y: snapped.$2,
      z: snapped.$3,
      type: details.data,
    );
  }

  void _removeByTap(Offset local, BeadEditorState editor) {
    final box = _dropAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final snapped = _snapToSurfaceFromScreen(local, box.size, editor);
    editor.removeAt(x: snapped.$1, y: snapped.$2, z: snapped.$3);
  }

  (int, int, int) _snapToSurfaceFromScreen(
    Offset local,
    Size size,
    BeadEditorState editor,
  ) {
    final scene = _scene;
    if (scene == null || size.width <= 0 || size.height <= 0) {
      return _fallbackSurfaceSnap(editor);
    }

    final ndcX = (2 * (local.dx / size.width)) - 1;
    final ndcY = 1 - (2 * (local.dy / size.height));

    final cam = scene.camera;
    final cameraPos = cam.position.clone();
    final target = cam.target.clone();
    final up = cam.up.clone();

    final forward = (target - cameraPos)..normalize();
    final right = forward.cross(up)..normalize();
    final trueUp = right.cross(forward)..normalize();

    final fovTan = math.tan((cam.fov * math.pi / 180) / 2) / cam.zoom;
    final aspect = size.width / size.height;

    final rayDirection =
        (forward +
              (right * (ndcX * aspect * fovTan)) +
              (trueUp * (ndcY * fovTan)))
          ..normalize();

    final points = editor.surfacePoints;
    if (points.isEmpty) {
      return (0, 0, 0);
    }

    var bestPoint = points.first;
    var bestScore = double.infinity;

    for (final p in points) {
      final point = vmath.Vector3(
        p.$1.toDouble(),
        p.$2.toDouble(),
        p.$3.toDouble(),
      );
      final toPoint = point - cameraPos;
      final t = toPoint.dot(rayDirection);
      if (t <= 0) continue;
      final closestOnRay = cameraPos + (rayDirection * t);
      final distance = (point - closestOnRay).length2;

      if (distance < bestScore) {
        bestScore = distance;
        bestPoint = p;
      }
    }

    return bestPoint;
  }

  (int, int, int) _fallbackSurfaceSnap(BeadEditorState editor) {
    final points = editor.surfacePoints;
    if (points.isEmpty) return (0, 0, 0);
    return points.first;
  }
}

class _InCanvasBeadPalette extends StatelessWidget {
  const _InCanvasBeadPalette({
    required this.editor,
    required this.onOpenAddOns,
  });

  final BeadEditorState editor;
  final VoidCallback onOpenAddOns;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text('Beads', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 10),
            ...List.generate(editor.paletteSlots.length, (index) {
              final color = editor.paletteSlots[index];
              final selected = index == editor.selectedSlotIndex;
              final type = BeadType(
                name: 'Quick ${editor.sizeLabelMm(editor.selectedSizeMm)}',
                color: color,
                size: editor.radiusForMm(editor.selectedSizeMm),
              );

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Draggable<BeadType>(
                  data: type,
                  onDragStarted: () => editor.setSelectedSlot(index),
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: _beadDot(color, size: 30, selected: true),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _beadDot(color, selected: selected),
                  ),
                  child: GestureDetector(
                    onTap: () => editor.setSelectedSlot(index),
                    child: _beadDot(color, selected: selected),
                  ),
                ),
              );
            }),
            const Spacer(),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: editor.sizeOptionsMm.map((mm) {
                return ChoiceChip(
                  label: Text('$mm'),
                  selected: editor.selectedSizeMm == mm,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => editor.setSelectedSizeMm(mm),
                );
              }).toList(),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Add-ons',
              onPressed: onOpenAddOns,
              icon: const Icon(Icons.extension_outlined),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _beadDot(Color color, {double size = 24, bool selected = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.black : Colors.black.withValues(alpha: 0.2),
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _EditToolsOverlay extends StatelessWidget {
  const _EditToolsOverlay({required this.editor});

  final BeadEditorState editor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Edit Tools', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Undo',
                onPressed: editor.canUndo ? editor.undo : null,
                icon: const Icon(Icons.undo_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: editor.canRedo ? editor.redo : null,
                icon: const Icon(Icons.redo_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Clear all beads',
                onPressed: editor.clearAll,
                icon: const Icon(Icons.delete_sweep_rounded),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Erase Mode'),
                selected: editor.eraseMode,
                onSelected: editor.setEraseMode,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Shadow'),
                selected: editor.shadowEnabled,
                onSelected: editor.setShadowEnabled,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 12),
              Text(
                'Shape: ${editor.meshShapeLabel(editor.selectedMeshShape)} | Facing: ${editor.facingDirection} | Upright: ${editor.isUprightView ? 'Yes' : 'No'}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraIconDock extends StatelessWidget {
  const _CameraIconDock({required this.editor});

  final BeadEditorState editor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Rotate left',
              onPressed: () => editor.setCameraYaw(editor.yaw - 8),
              icon: const Icon(Icons.rotate_left_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Rotate right',
              onPressed: () => editor.setCameraYaw(editor.yaw + 8),
              icon: const Icon(Icons.rotate_right_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Zoom in',
              onPressed: () => editor.setCameraZoom(editor.zoom - 1),
              icon: const Icon(Icons.zoom_in_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Zoom out',
              onPressed: () => editor.setCameraZoom(editor.zoom + 1),
              icon: const Icon(Icons.zoom_out_rounded),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'Reset Camera',
              onPressed: editor.resetCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
