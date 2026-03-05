import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlurEditorScreen extends StatefulWidget {
  final File imageFile;
  const BlurEditorScreen({super.key, required this.imageFile});

  @override
  State<BlurEditorScreen> createState() => _BlurEditorScreenState();
}

class _BlurEditorScreenState extends State<BlurEditorScreen> {
  ui.Image? _decodedImage;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isProcessing = false;
  final double _strokeWidth = 30.0;
  Size? _imageDisplaySize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _decodedImage = frame.image);
    }
  }

  void _onPanStart(DragStartDetails details) {
    _currentStroke = [details.localPosition];
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _currentStroke.add(details.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke.isNotEmpty) {
      _strokes.add(List.from(_currentStroke));
    }
    _currentStroke = [];
    setState(() {});
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _strokes.removeLast());
    }
  }

  Future<void> _done() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context, widget.imageFile);
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      final processedFile = await _processImage();
      if (mounted) Navigator.pop(context, processedFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to process image: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<File> _processImage() async {
    final img = _decodedImage!;
    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();
    final displayW = _imageDisplaySize!.width;
    final displayH = _imageDisplaySize!.height;
    final scaleX = imgW / displayW;
    final scaleY = imgH / displayH;

    // Create pixelated version: downscale then upscale
    const pixelSize = 12;
    final smallW = (imgW / pixelSize).ceil();
    final smallH = (imgH / pixelSize).ceil();

    final smallRecorder = ui.PictureRecorder();
    final smallCanvas = Canvas(smallRecorder);
    smallCanvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(0, 0, smallW.toDouble(), smallH.toDouble()),
      Paint()..filterQuality = FilterQuality.none,
    );
    final smallPicture = smallRecorder.endRecording();
    final smallImage = await smallPicture.toImage(smallW, smallH);

    final bigRecorder = ui.PictureRecorder();
    final bigCanvas = Canvas(bigRecorder);
    bigCanvas.drawImageRect(
      smallImage,
      Rect.fromLTWH(0, 0, smallW.toDouble(), smallH.toDouble()),
      Rect.fromLTWH(0, 0, imgW, imgH),
      Paint()..filterQuality = FilterQuality.none,
    );
    final bigPicture = bigRecorder.endRecording();
    final pixelatedImage = await bigPicture.toImage(img.width, img.height);

    // Composite: original base + pixelated clipped to stroke paths
    final finalRecorder = ui.PictureRecorder();
    final finalCanvas = Canvas(finalRecorder);

    finalCanvas.drawImage(img, Offset.zero, Paint());

    // Build stroke path in image coordinates
    final strokePath = Path();
    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      strokePath.moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
      for (int i = 1; i < stroke.length; i++) {
        strokePath.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
      }
    }

    // Use saveLayer + BlendMode.srcIn to mask pixelated image to stroked areas
    final maskPaint = Paint()
      ..strokeWidth = _strokeWidth * scaleX
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = Colors.white;

    finalCanvas.saveLayer(Rect.fromLTWH(0, 0, imgW, imgH), Paint());
    finalCanvas.drawPath(strokePath, maskPaint);
    finalCanvas.drawImage(
      pixelatedImage,
      Offset.zero,
      Paint()..blendMode = BlendMode.srcIn,
    );
    finalCanvas.restore();

    final finalPicture = finalRecorder.endRecording();
    final finalImage = await finalPicture.toImage(img.width, img.height);
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = widget.imageFile.parent.path;
    final outPath = '$dir/blurred_${DateTime.now().millisecondsSinceEpoch}.png';
    final outFile = File(outPath);
    await outFile.writeAsBytes(pngBytes);

    smallImage.dispose();
    pixelatedImage.dispose();
    finalImage.dispose();

    return outFile;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Use cropped photo',
          onPressed: () => Navigator.pop(context, widget.imageFile),
        ),
        title: Text(
          'Blur Sensitive Info',
          style: tt.headlineSmall?.copyWith(fontSize: 20, color: cs.onSurface),
        ),
        centerTitle: true,
        actions: [
          if (_strokes.isNotEmpty)
            IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: isLight ? 0.85 : 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(
                            alpha: isLight ? 0.15 : 0.3,
                          ),
                          blurRadius: isLight ? 8 : 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _done,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _decodedImage == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Draw over areas you want to blur',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imgW = _decodedImage!.width.toDouble();
                      final imgH = _decodedImage!.height.toDouble();
                      final scale = constraints.maxWidth / imgW;
                      final displayH = (imgH * scale).clamp(
                        0.0,
                        constraints.maxHeight,
                      );
                      final displayW = displayH == constraints.maxHeight
                          ? imgW * (constraints.maxHeight / imgH)
                          : constraints.maxWidth;
                      _imageDisplaySize = Size(displayW, displayH);

                      return Center(
                        child: SizedBox(
                          width: displayW,
                          height: displayH,
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: CustomPaint(
                              painter: _BlurPreviewPainter(
                                image: _decodedImage!,
                                strokes: _strokes,
                                currentStroke: _currentStroke,
                                strokeWidth: _strokeWidth,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _BlurPreviewPainter extends CustomPainter {
  final ui.Image image;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double strokeWidth;

  _BlurPreviewPainter({
    required this.image,
    required this.strokes,
    required this.currentStroke,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
    );

    final overlayPaint = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final allStrokes = [
      ...strokes,
      if (currentStroke.isNotEmpty) currentStroke,
    ];
    for (final stroke in allStrokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlurPreviewPainter old) => true;
}
