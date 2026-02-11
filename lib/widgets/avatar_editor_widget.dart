import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Callback for avatar selection
typedef AvatarCallback = void Function(File imageFile);

/// Avatar Editor Widget with zoom and rotation
class AvatarEditorWidget extends StatefulWidget {
  final File imageFile;
  final VoidCallback onCancel;
  final AvatarCallback onConfirm;

  const AvatarEditorWidget({
    Key? key,
    required this.imageFile,
    required this.onCancel,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<AvatarEditorWidget> createState() => _AvatarEditorWidgetState();
}

class _AvatarEditorWidgetState extends State<AvatarEditorWidget> {
  late TransformationController _controller;
  double _rotation = 0.0;
  double _scale = 1.0;

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
      _scale = 1.0;
      _controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Avatar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Image preview area
            Container(
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
                  angle: _rotation * (3.14159265 / 180),
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
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  onPressed: _rotateClockwise,
                ),
                _buildControlButton(
                  icon: Icons.zoom_in,
                  label: 'Zoom In',
                  onPressed: () {
                    _controller.value.scale(1.2);
                  },
                ),
                _buildControlButton(
                  icon: Icons.zoom_out,
                  label: 'Zoom Out',
                  onPressed: () {
                    _controller.value.scale(0.8);
                  },
                ),
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Reset',
                  onPressed: _resetTransform,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
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
                  onPressed: () {
                    widget.onConfirm(widget.imageFile);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
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
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
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
    Key? key,
    this.currentAvatarPath,
    required this.defaultAvatarAsset,
    required this.onAvatarSelected,
  }) : super(key: key);

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  void _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AvatarEditorWidget(
              imageFile: _selectedImage!,
              onCancel: () {
                Navigator.pop(context);
              },
              onConfirm: (file) {
                widget.onAvatarSelected(file);
                Navigator.pop(context); // Close editor
                Navigator.pop(context); // Close picker dialog
              },
            ),
          );
        }
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
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Avatar Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceButton(
                  icon: Icons.image,
                  label: 'Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
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
          Text(label),
        ],
      ),
    );
  }
}
