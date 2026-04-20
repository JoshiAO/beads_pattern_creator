import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bead_placement.dart';
import '../models/bead_type.dart';
import '../services/instruction_service.dart';

enum MeshShape { sphere, cube, cylinder, diamond }

enum AddOnStyle { cute, humanoid, animal }

class BeadEditorState extends ChangeNotifier {
  static const _storageKey = 'bead_placements_v1';
  static const _paletteStorageKey = 'bead_palette_slots_v1';
  static const _paletteSlotIndexKey = 'bead_palette_slot_index_v1';
  static const _sizeStorageKey = 'bead_size_selection_v1';
  static const _meshShapeStorageKey = 'mesh_shape_selection_v1';
  static const _meshVerticesStorageKey = 'mesh_vertices_v1';
  static const _shadowStorageKey = 'shadow_enabled_v1';

  // Add-ons storage keys
  static const _earEnabledKey = 'ear_enabled_v1';
  static const _earPointsKey = 'ear_points_v1';
  static const _armsEnabledKey = 'arms_enabled_v1';
  static const _armsPointsKey = 'arms_points_v1';
  static const _tailEnabledKey = 'tail_enabled_v1';
  static const _tailPointsKey = 'tail_points_v1';
  static const _footEnabledKey = 'foot_enabled_v1';
  static const _footPointsKey = 'foot_points_v1';
  static const _footCountKey = 'foot_count_v1';
  static const _addOnStyleKey = 'add_on_style_v1';
  static const _earTightnessKey = 'ear_tightness_v1';
  static const _armsTightnessKey = 'arms_tightness_v1';
  static const _tailTightnessKey = 'tail_tightness_v1';
  static const _footTightnessKey = 'foot_tightness_v1';

  static const List<Color> _defaultPaletteSlots = [
    Color(0xFFD94343),
    Color(0xFF3F8EE8),
    Color(0xFF2CA45D),
    Color(0xFFF0B429),
    Color(0xFF1D1D1F),
    Color(0xFFFF7B54),
  ];

  int get gridX => _meshVertices;
  int get gridY => _meshVertices;
  int get gridZ => (_meshVertices * 0.6).round().clamp(6, 24);

  final Map<String, BeadPlacement> _placements = {};
  final List<Map<String, BeadPlacement>> _undoStack = [];
  final List<Map<String, BeadPlacement>> _redoStack = [];

  final List<Color> _paletteSlots = List<Color>.from(_defaultPaletteSlots);
  int _selectedSlotIndex = 0;
  final List<int> sizeOptionsMm = [3, 4, 5, 6];
  int _selectedSizeMm = 3;
  final List<MeshShape> meshShapeOptions = MeshShape.values;
  MeshShape _selectedMeshShape = MeshShape.sphere;
  int _meshVertices = 12;
  bool _shadowEnabled = true;

  // Add-ons (Limbs) state
  bool _earEnabled = false;
  int _earPoints = 3;
  bool _armsEnabled = false;
  int _armsPoints = 3;
  bool _tailEnabled = false;
  int _tailPoints = 3;
  bool _footEnabled = false;
  int _footPoints = 1;
  int _footCount = 2;
  final List<AddOnStyle> addOnStyleOptions = AddOnStyle.values;
  AddOnStyle _addOnStyle = AddOnStyle.cute;
  double _earTightness = 0.82;
  double _armsTightness = 0.82;
  double _tailTightness = 0.82;
  double _footTightness = 0.82;

  int _activeLayer = 0;
  int get activeLayer => _activeLayer;
  bool _eraseMode = false;
  bool get eraseMode => _eraseMode;

  double _yaw = 35;
  double _pitch = 20;
  double _zoom = 18;
  double _panX = 0;
  double _panY = 0;
  double _panZ = 0;

  double get yaw => _yaw;
  double get pitch => _pitch;
  double get zoom => _zoom;
  double get panX => _panX;
  double get panY => _panY;
  double get panZ => _panZ;
  int _cameraRevision = 0;
  int get cameraRevision => _cameraRevision;

  int _sceneRevision = 0;
  int get sceneRevision => _sceneRevision;

  Iterable<BeadPlacement> get placements => _placements.values;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<Color> get paletteSlots => List<Color>.unmodifiable(_paletteSlots);
  int get selectedSlotIndex => _selectedSlotIndex;
  int get selectedSizeMm => _selectedSizeMm;
  Color get selectedColor => _paletteSlots[_selectedSlotIndex];
  MeshShape get selectedMeshShape => _selectedMeshShape;
  int get meshVertices => _meshVertices;
  bool get shadowEnabled => _shadowEnabled;

  // Add-ons getters
  bool get earEnabled => _earEnabled;
  int get earPoints => _earPoints;
  bool get armsEnabled => _armsEnabled;
  int get armsPoints => _armsPoints;
  bool get tailEnabled => _tailEnabled;
  int get tailPoints => _tailPoints;
  bool get footEnabled => _footEnabled;
  int get footPoints => _footPoints;
  int get footCount => _footCount;
  AddOnStyle get addOnStyle => _addOnStyle;
  double get earTightness => _earTightness;
  double get armsTightness => _armsTightness;
  double get tailTightness => _tailTightness;
  double get footTightness => _footTightness;

  bool get isUprightView => _pitch.abs() <= 80;
  String get facingDirection {
    final normalized = ((_yaw % 360) + 360) % 360;
    if (normalized >= 45 && normalized < 135) return 'East';
    if (normalized >= 135 && normalized < 225) return 'South';
    if (normalized >= 225 && normalized < 315) return 'West';
    return 'North';
  }

  List<BeadType> get beadTypes {
    return _paletteSlots
        .map(
          (color) => BeadType(
            name: 'Custom ${sizeLabelMm(_selectedSizeMm)}',
            color: color,
            size: radiusForMm(_selectedSizeMm),
          ),
        )
        .toList(growable: false);
  }

  BeadType get selectedType => BeadType(
    name: 'Custom ${sizeLabelMm(_selectedSizeMm)}',
    color: selectedColor,
    size: radiusForMm(_selectedSizeMm),
  );

  String get instructions =>
      InstructionService.generateInstructions(_placements.values);

  Future<void> initialize() async {
    await _load();
    if (_placements.isEmpty) {
      _seedDemoPattern();
      await _persist();
    }
    _sceneRevision++;
    notifyListeners();
  }

  void selectBeadType(BeadType type) {
    _selectedSizeMm = mmFromRadius(type.size);
    final index = _paletteSlots.indexWhere(
      (c) => c.toARGB32() == type.color.toARGB32(),
    );
    if (index >= 0) {
      _selectedSlotIndex = index;
    }
    notifyListeners();
  }

  void setSelectedSlot(int index) {
    _selectedSlotIndex = index.clamp(0, _paletteSlots.length - 1);
    notifyListeners();
  }

  void setSelectedSizeMm(int mm) {
    if (!sizeOptionsMm.contains(mm)) return;
    _selectedSizeMm = mm;
    notifyListeners();
  }

  void setSelectedMeshShape(MeshShape shape) {
    if (_selectedMeshShape == shape) return;
    _selectedMeshShape = shape;
    _normalizeForCurrentGrid();
    _sceneRevision++;
    notifyListeners();
    _persist();
    savePaletteSettings();
  }

  void setMeshVertices(int value) {
    final next = value.clamp(6, 36);
    if (_meshVertices == next) return;
    _meshVertices = next;
    _normalizeForCurrentGrid();
    _sceneRevision++;
    notifyListeners();
    savePaletteSettings();
  }

  void increaseMeshVertices() => setMeshVertices(_meshVertices + 1);
  void decreaseMeshVertices() => setMeshVertices(_meshVertices - 1);

  void setShadowEnabled(bool value) {
    _shadowEnabled = value;
    _sceneRevision++;
    notifyListeners();
    savePaletteSettings();
  }

  // Add-ons setters
  void setEarEnabled(bool value) {
    _earEnabled = value;
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setEarPoints(int value) {
    _earPoints = value.clamp(3, 6);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setArmsEnabled(bool value) {
    _armsEnabled = value;
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setArmsPoints(int value) {
    _armsPoints = value.clamp(3, 6);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setTailEnabled(bool value) {
    _tailEnabled = value;
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setTailPoints(int value) {
    _tailPoints = value.clamp(3, 6);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setFootEnabled(bool value) {
    _footEnabled = value;
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setFootPoints(int value) {
    _footPoints = value.clamp(1, 3);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setFootCount(int value) {
    _footCount = value.clamp(2, 4);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setAddOnStyle(AddOnStyle style) {
    if (_addOnStyle == style) return;
    _addOnStyle = style;
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setEarTightness(double value) {
    _earTightness = value.clamp(0.65, 1.20);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setArmsTightness(double value) {
    _armsTightness = value.clamp(0.65, 1.20);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setTailTightness(double value) {
    _tailTightness = value.clamp(0.65, 1.20);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  void setFootTightness(double value) {
    _footTightness = value.clamp(0.65, 1.20);
    _refreshMeshForAddOns();
    _saveAddOnsSettings();
  }

  String addOnStyleLabel(AddOnStyle style) {
    switch (style) {
      case AddOnStyle.cute:
        return 'Cute';
      case AddOnStyle.humanoid:
        return 'Humanoid';
      case AddOnStyle.animal:
        return 'Animal';
    }
  }

  String meshShapeLabel(MeshShape shape) {
    switch (shape) {
      case MeshShape.sphere:
        return 'Sphere';
      case MeshShape.cube:
        return 'Cube';
      case MeshShape.cylinder:
        return 'Cylinder';
      case MeshShape.diamond:
        return 'Diamond';
    }
  }

  void updatePaletteSlot(int index, Color color) {
    if (index < 0 || index >= _paletteSlots.length) return;
    _paletteSlots[index] = color;
    notifyListeners();
  }

  void applyPaletteSettings({
    required List<Color> colors,
    required int selectedSlot,
    required int sizeMm,
  }) {
    if (colors.length != _paletteSlots.length) return;
    for (var i = 0; i < colors.length; i++) {
      _paletteSlots[i] = colors[i];
    }
    _selectedSlotIndex = selectedSlot.clamp(0, _paletteSlots.length - 1);
    if (sizeOptionsMm.contains(sizeMm)) {
      _selectedSizeMm = sizeMm;
    }
    notifyListeners();
  }

  Future<void> savePaletteSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _paletteStorageKey,
      _paletteSlots.map((c) => c.toARGB32().toRadixString(16)).toList(),
    );
    await prefs.setInt(_paletteSlotIndexKey, _selectedSlotIndex);
    await prefs.setInt(_sizeStorageKey, _selectedSizeMm);
    await prefs.setString(_meshShapeStorageKey, _selectedMeshShape.name);
    await prefs.setInt(_meshVerticesStorageKey, _meshVertices);
    await prefs.setBool(_shadowStorageKey, _shadowEnabled);
  }

  String sizeLabelMm(int mm) => '${mm}mm';

  double radiusForMm(int mm) {
    switch (mm) {
      case 3:
        return 0.42;
      case 4:
        return 0.56;
      case 5:
        return 0.70;
      case 6:
        return 0.84;
      default:
        return 0.56;
    }
  }

  int mmFromRadius(double radius) {
    final entries = <(int, double)>[(3, 0.42), (4, 0.56), (5, 0.70), (6, 0.84)];
    entries.sort(
      (a, b) => (a.$2 - radius).abs().compareTo((b.$2 - radius).abs()),
    );
    return entries.first.$1;
  }

  bool isInsideMesh(int x, int y, int z) {
    final cx = (gridX - 1) / 2;
    final cy = (gridY - 1) / 2;
    final cz = (gridZ - 1) / 2;
    final rx = (gridX - 1) / 2;
    final ry = (gridY - 1) / 2;
    final rz = (gridZ - 1) / 2;

    // Use uniform radius for sphere so it remains a true sphere, not an ellipsoid.
    final sphereRadius = math.min(rx, math.min(ry, rz));
    final nxSphere = (x - cx) / sphereRadius;
    final nySphere = (y - cy) / sphereRadius;
    final nzSphere = (z - cz) / sphereRadius;

    final nx = (x - cx) / rx;
    final ny = (y - cy) / ry;
    final nz = (z - cz) / rz;

    bool insideBase;
    switch (_selectedMeshShape) {
      case MeshShape.sphere:
        insideBase =
            (nxSphere * nxSphere) +
                (nySphere * nySphere) +
                (nzSphere * nzSphere) <=
            1.0;
        break;
      case MeshShape.cube:
        insideBase = nx.abs() <= 1.0 && ny.abs() <= 1.0 && nz.abs() <= 1.0;
        break;
      case MeshShape.cylinder:
        insideBase = (nx * nx) + (ny * ny) <= 1.0 && nz.abs() <= 1.0;
        break;
      case MeshShape.diamond:
        insideBase = nx.abs() + ny.abs() + nz.abs() <= 1.0;
        break;
    }

    if (insideBase) return true;

    return _isInsideAddOns(
      x: x,
      y: y,
      z: z,
      cx: cx,
      cy: cy,
      cz: cz,
      rx: rx,
      ry: ry,
      rz: rz,
    );
  }

  bool _isInsideAddOns({
    required int x,
    required int y,
    required int z,
    required double cx,
    required double cy,
    required double cz,
    required double rx,
    required double ry,
    required double rz,
  }) {
    final dx = x - cx;
    final dy = y - cy;
    final dz = z - cz;

    bool inEllipsoid({
      required double centerX,
      required double centerY,
      required double centerZ,
      required double radiusX,
      required double radiusY,
      required double radiusZ,
    }) {
      if (radiusX <= 0 || radiusY <= 0 || radiusZ <= 0) return false;
      final nx = (dx - centerX) / radiusX;
      final ny = (dy - centerY) / radiusY;
      final nz = (dz - centerZ) / radiusZ;
      return (nx * nx) + (ny * ny) + (nz * nz) <= 1.0;
    }

    // Build smooth scale factors from slider ranges so each step is visible.
    final earT = (_earPoints - 3) / 3.0;
    final armsT = (_armsPoints - 3) / 3.0;
    final tailT = (_tailPoints - 3) / 3.0;
    final footT = (_footPoints - 1) / 2.0;

    final styleLateral = switch (_addOnStyle) {
      AddOnStyle.cute => 0.84,
      AddOnStyle.humanoid => 0.78,
      AddOnStyle.animal => 0.90,
    };
    final styleVertical = switch (_addOnStyle) {
      AddOnStyle.cute => 1.05,
      AddOnStyle.humanoid => 0.90,
      AddOnStyle.animal => 1.00,
    };
    final styleDepth = switch (_addOnStyle) {
      AddOnStyle.cute => 0.86,
      AddOnStyle.humanoid => 0.78,
      AddOnStyle.animal => 0.94,
    };
    final earTight = _earTightness;
    final armsTight = _armsTightness;
    final tailTight = _tailTightness;
    final footTight = _footTightness;

    if (_earEnabled) {
      final earCenterX = rx * 0.28 * styleLateral * earTight;
      final earCenterY =
          ((ry * 0.74) + (earT * ry * 0.12)) *
          ((0.90 + (earTight * 0.08)) * styleVertical);
      final earRadiusX = math.max(0.8, (rx * 0.16) + (earT * rx * 0.08));
      final earRadiusY = math.max(0.8, (ry * 0.18) + (earT * ry * 0.14));
      final earRadiusZ = math.max(0.8, (rz * 0.14) + (earT * rz * 0.08));

      if (inEllipsoid(
            centerX: -earCenterX,
            centerY: earCenterY,
            centerZ: 0,
            radiusX: earRadiusX,
            radiusY: earRadiusY,
            radiusZ: earRadiusZ,
          ) ||
          inEllipsoid(
            centerX: earCenterX,
            centerY: earCenterY,
            centerZ: 0,
            radiusX: earRadiusX,
            radiusY: earRadiusY,
            radiusZ: earRadiusZ,
          )) {
        return true;
      }
    }

    if (_armsEnabled) {
      final armCenterX =
          ((rx * 0.78) + (armsT * rx * 0.12)) * styleLateral * armsTight;
      final armCenterY = -ry * 0.05;
      final armRadiusX = math.max(0.8, (rx * 0.18) + (armsT * rx * 0.20));
      final armRadiusY = math.max(0.8, (ry * 0.20) + (armsT * ry * 0.12));
      final armRadiusZ = math.max(0.8, (rz * 0.16) + (armsT * rz * 0.10));

      if (inEllipsoid(
            centerX: -armCenterX,
            centerY: armCenterY,
            centerZ: 0,
            radiusX: armRadiusX,
            radiusY: armRadiusY,
            radiusZ: armRadiusZ,
          ) ||
          inEllipsoid(
            centerX: armCenterX,
            centerY: armCenterY,
            centerZ: 0,
            radiusX: armRadiusX,
            radiusY: armRadiusY,
            radiusZ: armRadiusZ,
          )) {
        return true;
      }
    }

    if (_tailEnabled) {
      final tailCenterZ =
          -(((rz * 0.72) + (tailT * rz * 0.16)) * styleDepth * tailTight);
      final tailCenterY = -ry * 0.10;
      if (inEllipsoid(
        centerX: 0,
        centerY: tailCenterY,
        centerZ: tailCenterZ,
        radiusX: math.max(0.8, (rx * 0.16) + (tailT * rx * 0.08)),
        radiusY: math.max(0.8, (ry * 0.14) + (tailT * ry * 0.10)),
        radiusZ: math.max(0.8, (rz * 0.24) + (tailT * rz * 0.30)),
      )) {
        return true;
      }
    }

    if (_footEnabled) {
      final footRadiusX = math.max(0.7, (rx * 0.13) + (footT * rx * 0.08));
      final footRadiusY = math.max(0.6, (ry * 0.09) + (footT * ry * 0.10));
      final footRadiusZ = math.max(0.7, (rz * 0.13) + (footT * rz * 0.08));
      final footCenterY = -((ry * 0.80) + (footT * ry * 0.08)) * footTight;

      final footCenters = <(double, double)>[];
      if (_footCount == 2) {
        footCenters.add((-(rx * 0.18 * styleLateral * footTight), 0));
        footCenters.add(((rx * 0.18 * styleLateral * footTight), 0));
      } else if (_footCount == 3) {
        footCenters.add((-(rx * 0.20 * styleLateral * footTight), 0));
        footCenters.add((0, rz * 0.06 * styleDepth * footTight));
        footCenters.add(((rx * 0.20 * styleLateral * footTight), 0));
      } else {
        footCenters.add((
          -(rx * 0.18 * styleLateral * footTight),
          -(rz * 0.12 * styleDepth * footTight),
        ));
        footCenters.add((
          (rx * 0.18 * styleLateral * footTight),
          -(rz * 0.12 * styleDepth * footTight),
        ));
        footCenters.add((
          -(rx * 0.18 * styleLateral * footTight),
          (rz * 0.12 * styleDepth * footTight),
        ));
        footCenters.add((
          (rx * 0.18 * styleLateral * footTight),
          (rz * 0.12 * styleDepth * footTight),
        ));
      }

      for (final center in footCenters) {
        if (inEllipsoid(
          centerX: center.$1,
          centerY: footCenterY,
          centerZ: center.$2,
          radiusX: footRadiusX,
          radiusY: footRadiusY,
          radiusZ: footRadiusZ,
        )) {
          return true;
        }
      }
    }

    return false;
  }

  void _refreshMeshForAddOns() {
    _normalizeForCurrentGrid();
    _sceneRevision++;
    notifyListeners();
  }

  (int, int) snapToNearestValidOnLayer({
    required int x,
    required int y,
    required int z,
  }) {
    final clampedX = x.clamp(0, gridX - 1);
    final clampedY = y.clamp(0, gridY - 1);
    if (isInsideMesh(clampedX, clampedY, z)) {
      return (clampedX, clampedY);
    }

    var best = (clampedX, clampedY);
    var bestDistance = double.infinity;

    for (var iy = 0; iy < gridY; iy++) {
      for (var ix = 0; ix < gridX; ix++) {
        if (!isInsideMesh(ix, iy, z)) continue;
        final dx = (ix - clampedX).toDouble();
        final dy = (iy - clampedY).toDouble();
        final d2 = (dx * dx) + (dy * dy);
        if (d2 < bestDistance) {
          bestDistance = d2;
          best = (ix, iy);
        }
      }
    }

    return best;
  }

  void setActiveLayer(int value) {
    _activeLayer = value.clamp(0, gridZ - 1);
    notifyListeners();
  }

  void setEraseMode(bool value) {
    _eraseMode = value;
    notifyListeners();
  }

  void setCameraYaw(double value) {
    _yaw = value;
    _cameraRevision++;
    notifyListeners();
  }

  void setCameraPitch(double value) {
    _pitch = value.clamp(-80, 80);
    _cameraRevision++;
    notifyListeners();
  }

  void setCameraZoom(double value) {
    _zoom = value.clamp(6, 40);
    _cameraRevision++;
    notifyListeners();
  }

  void setPanX(double value) {
    _panX = value.clamp(-6, 6);
    _cameraRevision++;
    notifyListeners();
  }

  void setPanY(double value) {
    _panY = value.clamp(-6, 6);
    _cameraRevision++;
    notifyListeners();
  }

  void setPanZ(double value) {
    _panZ = value.clamp(-6, 6);
    _cameraRevision++;
    notifyListeners();
  }

  void resetCamera() {
    _yaw = 35;
    _pitch = 20;
    _zoom = 18;
    _panX = 0;
    _panY = 0;
    _panZ = 0;
    _cameraRevision++;
    notifyListeners();
  }

  void placeBead({
    required int x,
    required int y,
    required int z,
    required BeadType type,
  }) {
    if (!_isWithinGrid(x, y, z)) return;
    _pushUndo();
    final bead = BeadPlacement(
      x: x,
      y: y,
      z: z,
      colorValue: type.color.toARGB32(),
      size: type.size,
    );
    _placements[bead.key] = bead;
    _redoStack.clear();
    _afterMutation();
  }

  void removeAt({required int x, required int y, required int z}) {
    final key = '$x:$y:$z';
    if (!_placements.containsKey(key)) return;
    _pushUndo();
    _placements.remove(key);
    _redoStack.clear();
    _afterMutation();
  }

  void clearAll() {
    if (_placements.isEmpty) return;
    _pushUndo();
    _placements.clear();
    _redoStack.clear();
    _afterMutation();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(Map<String, BeadPlacement>.from(_placements));
    final previous = _undoStack.removeLast();
    _placements
      ..clear()
      ..addAll(previous);
    _afterMutation(persist: false);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(Map<String, BeadPlacement>.from(_placements));
    final next = _redoStack.removeLast();
    _placements
      ..clear()
      ..addAll(next);
    _afterMutation(persist: false);
  }

  int snapCoordinate(double value, int maxExclusive) {
    return value.round().clamp(0, maxExclusive - 1);
  }

  int snapLayer(double value) {
    return value.round().clamp(0, gridZ - 1);
  }

  Color colorFromPlacement(BeadPlacement bead) => Color(bead.colorValue);

  BeadPlacement? placementAt(int x, int y, int z) {
    return _placements['$x:$y:$z'];
  }

  bool _isWithinGrid(int x, int y, int z) {
    return x >= 0 &&
        y >= 0 &&
        z >= 0 &&
        x < gridX &&
        y < gridY &&
        z < gridZ &&
        isSurfacePoint(x, y, z);
  }

  bool isSurfacePoint(int x, int y, int z) {
    if (!isInsideMesh(x, y, z)) return false;

    final neighbors = <(int, int, int)>[
      (x - 1, y, z),
      (x + 1, y, z),
      (x, y - 1, z),
      (x, y + 1, z),
      (x, y, z - 1),
      (x, y, z + 1),
    ];

    for (final n in neighbors) {
      final nx = n.$1;
      final ny = n.$2;
      final nz = n.$3;
      final inBounds =
          nx >= 0 &&
          ny >= 0 &&
          nz >= 0 &&
          nx < gridX &&
          ny < gridY &&
          nz < gridZ;
      if (!inBounds || !isInsideMesh(nx, ny, nz)) {
        return true;
      }
    }
    return false;
  }

  List<(int, int, int)> get surfacePoints {
    final points = <(int, int, int)>[];
    for (var z = 0; z < gridZ; z++) {
      for (var y = 0; y < gridY; y++) {
        for (var x = 0; x < gridX; x++) {
          if (isSurfacePoint(x, y, z)) {
            points.add((x, y, z));
          }
        }
      }
    }
    return points;
  }

  int get surfacePointCount {
    var count = 0;
    for (var z = 0; z < gridZ; z++) {
      for (var y = 0; y < gridY; y++) {
        for (var x = 0; x < gridX; x++) {
          if (isSurfacePoint(x, y, z)) {
            count++;
          }
        }
      }
    }
    return count;
  }

  void _pushUndo() {
    _undoStack.add(Map<String, BeadPlacement>.from(_placements));
    if (_undoStack.length > 100) {
      _undoStack.removeAt(0);
    }
  }

  void _afterMutation({bool persist = true}) {
    _sceneRevision++;
    notifyListeners();
    if (persist) {
      _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _placements.values.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> _saveAddOnsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_earEnabledKey, _earEnabled);
    await prefs.setInt(_earPointsKey, _earPoints);
    await prefs.setBool(_armsEnabledKey, _armsEnabled);
    await prefs.setInt(_armsPointsKey, _armsPoints);
    await prefs.setBool(_tailEnabledKey, _tailEnabled);
    await prefs.setInt(_tailPointsKey, _tailPoints);
    await prefs.setBool(_footEnabledKey, _footEnabled);
    await prefs.setInt(_footPointsKey, _footPoints);
    await prefs.setInt(_footCountKey, _footCount);
    await prefs.setString(_addOnStyleKey, _addOnStyle.name);
    await prefs.setDouble(_earTightnessKey, _earTightness);
    await prefs.setDouble(_armsTightnessKey, _armsTightness);
    await prefs.setDouble(_tailTightnessKey, _tailTightness);
    await prefs.setDouble(_footTightnessKey, _footTightness);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final shapeName = prefs.getString(_meshShapeStorageKey);
    if (shapeName != null) {
      _selectedMeshShape = MeshShape.values.firstWhere(
        (s) => s.name == shapeName,
        orElse: () => MeshShape.sphere,
      );
    }

    final savedVertices = prefs.getInt(_meshVerticesStorageKey);
    if (savedVertices != null) {
      _meshVertices = savedVertices.clamp(6, 36);
    }

    final savedShadow = prefs.getBool(_shadowStorageKey);
    if (savedShadow != null) {
      _shadowEnabled = savedShadow;
    }

    final paletteHex = prefs.getStringList(_paletteStorageKey);
    if (paletteHex != null && paletteHex.length == _paletteSlots.length) {
      for (var i = 0; i < paletteHex.length; i++) {
        final parsed = int.tryParse(paletteHex[i], radix: 16);
        if (parsed != null) {
          _paletteSlots[i] = Color(parsed);
        }
      }
    }

    final savedSlot = prefs.getInt(_paletteSlotIndexKey);
    if (savedSlot != null) {
      _selectedSlotIndex = savedSlot.clamp(0, _paletteSlots.length - 1);
    }

    final savedSize = prefs.getInt(_sizeStorageKey);
    if (savedSize != null && sizeOptionsMm.contains(savedSize)) {
      _selectedSizeMm = savedSize;
    }

    // Load add-ons settings
    _earEnabled = prefs.getBool(_earEnabledKey) ?? false;
    _earPoints = (prefs.getInt(_earPointsKey) ?? 3).clamp(3, 6);
    _armsEnabled = prefs.getBool(_armsEnabledKey) ?? false;
    _armsPoints = (prefs.getInt(_armsPointsKey) ?? 3).clamp(3, 6);
    _tailEnabled = prefs.getBool(_tailEnabledKey) ?? false;
    _tailPoints = (prefs.getInt(_tailPointsKey) ?? 3).clamp(3, 6);
    _footEnabled = prefs.getBool(_footEnabledKey) ?? false;
    _footPoints = (prefs.getInt(_footPointsKey) ?? 1).clamp(1, 3);
    _footCount = (prefs.getInt(_footCountKey) ?? 2).clamp(2, 4);
    final addOnStyleName = prefs.getString(_addOnStyleKey);
    if (addOnStyleName != null) {
      _addOnStyle = AddOnStyle.values.firstWhere(
        (s) => s.name == addOnStyleName,
        orElse: () => AddOnStyle.cute,
      );
    }
    _earTightness = (prefs.getDouble(_earTightnessKey) ?? 0.82).clamp(
      0.65,
      1.20,
    );
    _armsTightness = (prefs.getDouble(_armsTightnessKey) ?? 0.82).clamp(
      0.65,
      1.20,
    );
    _tailTightness = (prefs.getDouble(_tailTightnessKey) ?? 0.82).clamp(
      0.65,
      1.20,
    );
    _footTightness = (prefs.getDouble(_footTightnessKey) ?? 0.82).clamp(
      0.65,
      1.20,
    );

    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as List<dynamic>;
    _placements.clear();
    for (final item in decoded) {
      final bead = BeadPlacement.fromJson(item as Map<String, dynamic>);
      if (_isWithinGrid(bead.x, bead.y, bead.z)) {
        _placements[bead.key] = bead;
      }
    }
    _normalizeForCurrentGrid();
  }

  void _normalizeForCurrentGrid() {
    if (_activeLayer >= gridZ) {
      _activeLayer = gridZ - 1;
    }

    final toRemove = <String>[];
    for (final entry in _placements.entries) {
      final bead = entry.value;
      if (!_isWithinGrid(bead.x, bead.y, bead.z)) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _placements.remove(key);
    }
  }

  void _seedDemoPattern() {
    final red = BeadType(name: 'Demo Red', color: _paletteSlots[0], size: 0.56);
    final blue = BeadType(
      name: 'Demo Blue',
      color: _paletteSlots[1],
      size: 0.56,
    );
    final green = BeadType(
      name: 'Demo Green',
      color: _paletteSlots[2],
      size: 0.70,
    );
    final yellow = BeadType(
      name: 'Demo Yellow',
      color: _paletteSlots[3],
      size: 0.70,
    );

    for (var x = 3; x <= 6; x++) {
      placeBead(x: x, y: 3, z: 2, type: red);
      placeBead(x: x, y: 6, z: 2, type: red);
    }
    for (var y = 3; y <= 6; y++) {
      placeBead(x: 3, y: y, z: 2, type: blue);
      placeBead(x: 6, y: y, z: 2, type: blue);
    }

    for (var i = 0; i < 4; i++) {
      placeBead(x: 4, y: 3 + i, z: 3, type: green);
      placeBead(x: 3 + i, y: 4, z: 3, type: yellow);
    }

    final random = math.Random(3);
    for (var i = 0; i < 8; i++) {
      final z = 1 + random.nextInt(4);
      final x = 2 + random.nextInt(6);
      final y = 2 + random.nextInt(6);
      placeBead(
        x: x,
        y: y,
        z: z,
        type: beadTypes[random.nextInt(beadTypes.length)],
      );
    }
    _undoStack.clear();
    _redoStack.clear();
  }
}
