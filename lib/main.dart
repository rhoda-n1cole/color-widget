import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Color Lab: a tiny interactive app that explains Flutter's Color class.
// Requires Flutter 3.27+ (uses Color.r / .g / .b). No extra packages needed.

void main() => runApp(const ColorLabApp());

class ColorLabApp extends StatelessWidget {
  const ColorLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color Lab',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7C5CFF),
        scaffoldBackgroundColor: const Color(0xFF0E0F13),
      ),
      home: const ColorLab(),
    );
  }
}

class ColorLab extends StatefulWidget {
  const ColorLab({super.key});

  @override
  State<ColorLab> createState() => _ColorLabState();
}

class _ColorLabState extends State<ColorLab> {
  int r = 124, g = 92, b = 255; // Red, Green, Blue: 0..255
  double a = 1.0; // Opacity: 0.0..1.0
  double blend = 0.5; // Color.lerp position: 0.0..1.0

  // 1) Build a Color from RGB + opacity
  Color get color => Color.fromRGBO(r, g, b, a);

  // 2) HSL view of the same color (used for harmony)
  HSLColor get hsl => HSLColor.fromColor(color.withAlpha(255));

  Color _shift(double degrees) =>
      hsl.withHue((hsl.hue + degrees) % 360).toColor();

  String get hex =>
      '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  String get argbHex =>
      '0x${(a * 255).round().toRadixString(16).padLeft(2, '0')}${hex.substring(1)}'
          .toUpperCase();

  void _setColor(Color c) => setState(() {
    r = (c.r * 255).round();
    g = (c.g * 255).round();
    b = (c.b * 255).round();
  });

  // Pick readable text color using luminance
  Color _textOn(Color c) =>
      Color.alphaBlend(c, const Color(0xFF33353D)).computeLuminance() > 0.5
      ? Colors.black87
      : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Color Lab',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learn Flutter\'s Color class by playing with it',
                  style: TextStyle(color: Colors.white.withValues(alpha: .6)),
                ),
                const SizedBox(height: 20),
                _preview(),
                const SizedBox(height: 16),
                _mixerCard(),
                const SizedBox(height: 16),
                _harmonyCard(),
                const SizedBox(height: 16),
                _blendCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Live preview ----------
  Widget _preview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _Checker())),
            Positioned.fill(child: ColoredBox(color: color)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    hex,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: _textOn(color),
                    ),
                  ),
                  Text(
                    'opacity ${(a * 100).round()}%  ·  '
                    'H ${hsl.hue.round()}°  S ${(hsl.saturation * 100).round()}%  L ${(hsl.lightness * 100).round()}%',
                    style: TextStyle(color: _textOn(color)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Card 1: Mixer ----------
  Widget _mixerCard() {
    return _Card(
      title: '1 · Mix a Color',
      subtitle: 'A Color is 4 numbers: Alpha, Red, Green, Blue',
      child: Column(
        children: [
          _slider(
            'R',
            r.toDouble(),
            255,
            Colors.redAccent,
            (v) => setState(() => r = v.round()),
          ),
          _slider(
            'G',
            g.toDouble(),
            255,
            Colors.greenAccent,
            (v) => setState(() => g = v.round()),
          ),
          _slider(
            'B',
            b.toDouble(),
            255,
            Colors.blueAccent,
            (v) => setState(() => b = v.round()),
          ),
          _slider('A', a, 1, Colors.white, (v) => setState(() => a = v)),
          const SizedBox(height: 8),
          _CodeLine(
            code:
                'Color.fromRGBO($r, $g, $b, ${a.toStringAsFixed(2)})\n'
                'Color($argbHex)',
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double max,
    Color tint,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context)
                .copyWith(activeTrackColor: tint, thumbColor: tint),
            child: Slider(value: value, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            max == 1 ? value.toStringAsFixed(2) : '${value.round()}',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ---------- Card 2: Harmony ----------
  Widget _harmonyCard() {
    final swatches = <String, Color>{
      'Base': color.withAlpha(255),
      'Analog −30°': _shift(-30),
      'Analog +30°': _shift(30),
      'Triad +120°': _shift(120),
      'Complement': _shift(180),
    };
    return _Card(
      title: '2 · Color Harmony',
      subtitle: 'Rotate the hue on the color wheel (tap a swatch to use it)',
      child: Row(
        children: swatches.entries.map((e) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _setColor(e.value),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: e.value,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.key,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: .7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Card 3: Blend (Color.lerp) ----------
  Widget _blendCard() {
    final from = color.withAlpha(255);
    final to = Colors.orange;
    final mixed = Color.lerp(from, to, blend)!;
    return _Card(
      title: '3 · Blend with Color.lerp',
      subtitle: 'Smoothly move between two colors',
      child: Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [from, to]),
            ),
          ),
          Slider(value: blend, onChanged: (v) => setState(() => blend = v)),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: mixed, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CodeLine(
                  code: 'Color.lerp(from, to, ${blend.toStringAsFixed(2)})',
                ),
              ),
              IconButton(
                tooltip: 'Copy this color',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () {
                  _setColor(mixed);
                  Clipboard.setData(ClipboardData(text: hex));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Applied & HEX copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Small reusable pieces ----------
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171920),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Color(0xFFB7F7C5),
        ),
      ),
    );
  }
}

class _Checker extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 12.0;
    final p = Paint();
    for (var y = 0; y * s < size.height; y++) {
      for (var x = 0; x * s < size.width; x++) {
        p.color = (x + y).isEven
            ? const Color(0xFF2A2C33)
            : const Color(0xFF3A3D46);
        canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
