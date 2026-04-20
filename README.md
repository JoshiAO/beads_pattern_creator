# Beads Pattern Creator

Beads Pattern Creator is a Flutter app for designing bead patterns directly on a 3D shape canvas.
You can drag bead colors onto a generated mesh surface, customize shape add-ons (ears, arms, tail, feet), move the camera around the model, and export build instructions.

Repository: https://github.com/JoshiAO/beads_pattern_creator

## Features

- 3D mesh editor with interactive bead placement
- Supported base shapes:
	- Sphere
	- Cube
	- Cylinder
	- Diamond
- Add-ons system:
	- Ears, arms, tail, feet
	- Per-add-on points control
	- Per-add-on tightness control
	- Foot count options
	- Style presets
- Fluid Add-ons modal (draggable/resizable bottom sheet)
- Camera tools:
	- Rotate
	- Zoom
	- Reset to default view
	- Gesture-based camera interaction (single-finger rotate, pinch zoom, two-finger pan)
- Edit tools:
	- Undo/redo
	- Erase mode
	- Clear all beads
- Export support for instruction generation
- Settings persistence using SharedPreferences

## Tech Stack

- Flutter
- Provider (state management)
- flutter_cube (3D rendering)
- SharedPreferences (local persistence)

## Getting Started

### Prerequisites

- Flutter SDK installed
- A configured device or emulator (Android, iOS, Windows, macOS, Linux, or Web)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

## Project Structure

```text
lib/
	main.dart
	models/
	services/
	state/
	widgets/
```

- `state/`: app and editor state logic
- `services/`: mesh creation and export-related services
- `widgets/`: 3D canvas, panels, controls, and editor UI

## Typical Workflow

1. Choose a base shape and bead size.
2. Drag bead colors from the palette onto the 3D surface.
3. Open Add-ons and tune points/tightness for each part.
4. Rotate/zoom/pan to inspect your model.
5. Export instructions when your design is ready.

## Build and Analyze

```bash
flutter analyze
flutter test
```

## Contributing

Issues and pull requests are welcome.

## License

No license file is currently included.
If you plan to share or reuse this project publicly, add a license (for example MIT) to clarify usage rights.
