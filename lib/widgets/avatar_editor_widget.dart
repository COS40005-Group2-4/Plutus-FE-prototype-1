import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';

/// Callback for avatar selection
typedef AvatarCallback = void Function(File imageFile);

/// Avatar Editor Widget with zoom and rotation
class AvatarEditorWidget extends StatefulWidget {
  final File imageFile;
  final VoidCallback onCancel;
  final AvatarCallback onConfirm;

  const AvatarEditorWidget({
    super.key,
    required this.imageFile,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<AvatarEditorWidget> createState() => _AvatarEditorWidgetState();
}

class _AvatarEditorWidgetState extends State<AvatarEditorWidget> {
  late TransformationController _controller;
  double _rotation = 0.0;
  final GlobalKey _previewKey = GlobalKey();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _rotation = (_rotation + 15) % 360;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotation = 0.0;
      _controller.value = Matrix4.identity();
    });
  }

  Future<File> _captureAndSave() async {
    final RenderRepaintBoundary boundary =
        _previewKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Failed to encode avatar preview to PNG');
    }
    final List<int> pngBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(pngBytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.avatarEdit,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Image preview area with circle guide
            Stack(
              alignment: Alignment.center,
              children: [
                RepaintBoundary(
                  key: _previewKey,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Transform.rotate(
                        angle: _rotation * (math.pi / 180),
                        child: InteractiveViewer(
                          transformationController: _controller,
                          boundaryMargin: const EdgeInsets.all(100),
                          minScale: 0.5,
                          maxScale: 4,
                          child: Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: const _CircleGuidePainter(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Controls
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildControlButton(
                  icon: Icons.rotate_right,
                  label: l10n.avatarRotate,
                  onPressed: _rotateClockwise,
                ),
                _buildControlButton(
                  icon: Icons.zoom_in,
                  label: l10n.avatarZoomIn,
                  onPressed: () {
                    final Matrix4 m = _controller.value.clone();
                    // ignore: deprecated_member_use
                    m.scale(1.2);
                    _controller.value = m;
                  },
                ),
                _buildControlButton(
                  icon: Icons.zoom_out,
                  label: l10n.avatarZoomOut,
                  onPressed: () {
                    final Matrix4 m = _controller.value.clone();
                    // ignore: deprecated_member_use
                    m.scale(1 / 1.2);
                    _controller.value = m;
                  },
                ),
                _buildControlButton(
                  icon: Icons.refresh,
                  label: l10n.avatarReset,
                  onPressed: _resetTransform,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.cancel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          try {
                            final File captured = await _captureAndSave();
                            widget.onConfirm(captured);
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to save avatar: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
                        },
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.confirm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.blue),
          onPressed: onPressed,
          tooltip: label,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Avatar picker and editor dialog
class AvatarPickerDialog extends StatefulWidget {
  final String? currentAvatarPath;
  final String defaultAvatarAsset;
  final AvatarCallback onAvatarSelected;

  const AvatarPickerDialog({
    super.key,
    this.currentAvatarPath,
    required this.defaultAvatarAsset,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    // Capture navigator before the async gap so we can close the picker
    // after confirming inside the editor dialog (two distinct routes to pop).
    final NavigatorState navigator = Navigator.of(context);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AvatarEditorWidget(
            imageFile: _selectedImage!,
            onCancel: () => Navigator.pop(dialogContext),
            onConfirm: (File file) {
              widget.onAvatarSelected(file);
              Navigator.pop(dialogContext); // close editor
              navigator.pop(); // close picker
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              l10n.avatarSourceTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: l10n.avatarCamera,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceButton(
                  icon: Icons.image,
                  label: l10n.avatarGallery,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 8),
          Text(label, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CircleGuidePainter extends CustomPainter {
  const _CircleGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 4;

    // Dark overlay outside the circle
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Dashed circle ring
    const double dashLength = 10.0;
    const double gapLength = 6.0;
    final double circumference = 2 * math.pi * radius;
    final int totalDashes =
        (circumference / (dashLength + gapLength)).floor();
    final double dashAngle =
        (dashLength / circumference) * 2 * math.pi;
    final double gapAngle =
        (gapLength / circumference) * 2 * math.pi;
    final Paint dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    double angle = -math.pi / 2;
    for (int i = 0; i < totalDashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle,
        false,
        dashPaint,
      );
      angle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
