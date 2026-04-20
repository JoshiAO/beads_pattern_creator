import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key, required this.initialColor});

  final Color initialColor;

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  static const List<Color> _presetSwatches = [
    Color(0xFFD94343),
    Color(0xFF3F8EE8),
    Color(0xFF2CA45D),
    Color(0xFFF0B429),
    Color(0xFF1D1D1F),
    Color(0xFFFF7B54),
    Color(0xFF7E57C2),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
    Color(0xFFEC407A),
    Color(0xFFFFEE58),
    Color(0xFF546E7A),
  ];

  late int _red;
  late int _green;
  late int _blue;
  late int _alpha;
  bool _argbMode = false;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _red = (widget.initialColor.r * 255).round();
    _green = (widget.initialColor.g * 255).round();
    _blue = (widget.initialColor.b * 255).round();
    _alpha = (widget.initialColor.a * 255).round();
    _hexController = TextEditingController(text: _currentHex);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = Color.fromARGB(_alpha, _red, _green, _blue);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a Color')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adjust channels to build a custom bead color.'),
              const SizedBox(height: 16),
              const Text(
                'Preset swatches',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetSwatches.map((color) {
                  final isSelected = color.toARGB32() == current.toARGB32();
                  return GestureDetector(
                    onTap: () => _setColor(color),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black.withValues(alpha: 0.15),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hex color',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('RGB (6)')),
                  ButtonSegment<bool>(value: true, label: Text('ARGB (8)')),
                ],
                selected: {_argbMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _argbMode = selection.first;
                    _hexController.text = _currentHex;
                  });
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('#'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      maxLength: _argbMode ? 8 : 6,
                      decoration: InputDecoration(
                        hintText: _argbMode ? 'AARRGGBB' : 'RRGGBB',
                        counterText: '',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9a-fA-F]'),
                        ),
                      ],
                      onSubmitted: (_) => _applyHex(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _applyHex,
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyHex,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pasteHex,
                    icon: const Icon(Icons.content_paste),
                    label: const Text('Paste'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: current,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _channelSlider(
                label: 'R',
                value: _red.toDouble(),
                activeColor: Colors.red,
                onChanged: (v) => _setChannel(r: v.round()),
              ),
              _channelSlider(
                label: 'G',
                value: _green.toDouble(),
                activeColor: Colors.green,
                onChanged: (v) => _setChannel(g: v.round()),
              ),
              _channelSlider(
                label: 'B',
                value: _blue.toDouble(),
                activeColor: Colors.blue,
                onChanged: (v) => _setChannel(b: v.round()),
              ),
              if (_argbMode)
                _channelSlider(
                  label: 'A',
                  value: _alpha.toDouble(),
                  activeColor: Colors.black,
                  onChanged: (v) => _setChannel(a: v.round()),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, current),
                      child: const Text('Use Color'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _currentHex {
    if (_argbMode) {
      final a = _alpha.toRadixString(16).padLeft(2, '0').toUpperCase();
      final r = _red.toRadixString(16).padLeft(2, '0').toUpperCase();
      final g = _green.toRadixString(16).padLeft(2, '0').toUpperCase();
      final b = _blue.toRadixString(16).padLeft(2, '0').toUpperCase();
      return '$a$r$g$b';
    }

    final r = _red.toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = _green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = _blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '$r$g$b';
  }

  void _setColor(Color color) {
    setState(() {
      _red = (color.r * 255).round();
      _green = (color.g * 255).round();
      _blue = (color.b * 255).round();
      _alpha = (color.a * 255).round();
      _hexController.text = _currentHex;
    });
  }

  void _setChannel({int? a, int? r, int? g, int? b}) {
    setState(() {
      if (a != null) _alpha = a;
      if (r != null) _red = r;
      if (g != null) _green = g;
      if (b != null) _blue = b;
      _hexController.text = _currentHex;
    });
  }

  void _applyHex() {
    final raw = _normalizeHex(_hexController.text);
    final expectedLength = _argbMode ? 8 : 6;
    if (raw.length != expectedLength) {
      _showHexError();
      return;
    }

    final parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) {
      _showHexError();
      return;
    }

    if (_argbMode) {
      _setColor(Color(parsed));
    } else {
      _setColor(Color(0xFF000000 | parsed));
    }
  }

  Future<void> _copyHex() async {
    await Clipboard.setData(ClipboardData(text: _currentHex));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hex copied to clipboard.')));
  }

  Future<void> _pasteHex() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      _showHexError(message: 'Clipboard is empty or does not contain text.');
      return;
    }

    final normalized = _normalizeHex(text);
    if (normalized.length != 6 && normalized.length != 8) {
      _showHexError(message: 'Clipboard must contain RRGGBB or AARRGGBB.');
      return;
    }

    setState(() {
      _argbMode = normalized.length == 8;
      _hexController.text = normalized.toUpperCase();
    });
    _applyHex();
  }

  String _normalizeHex(String value) {
    var raw = value.trim();
    if (raw.startsWith('#')) {
      raw = raw.substring(1);
    }
    if (raw.startsWith('0x') || raw.startsWith('0X')) {
      raw = raw.substring(2);
    }
    return raw.toUpperCase();
  }

  void _showHexError({String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Enter a valid hex color.')),
    );
  }

  Widget _channelSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 36, child: Text(value.round().toString())),
      ],
    );
  }
}
