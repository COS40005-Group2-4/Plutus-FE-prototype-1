import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';

class ZoomableImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;
  final double minScale;
  final double maxScale;

  const ZoomableImageViewer({
    super.key,
    required this.imageProvider,
    this.minScale = 0.5,
    this.maxScale = 4.0,
  });

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer> {
  final TransformationController _controller = TransformationController();

  void _zoomIn() {
    final double currentScale = _controller.value.getMaxScaleOnAxis();
    final double newScale =
        (currentScale * 1.3).clamp(widget.minScale, widget.maxScale);
    _controller.value = Matrix4.identity()
      ..scaleByDouble(newScale, newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final double currentScale = _controller.value.getMaxScaleOnAxis();
    final double newScale =
        (currentScale / 1.3).clamp(widget.minScale, widget.maxScale);
    _controller.value = Matrix4.identity()
      ..scaleByDouble(newScale, newScale, newScale, 1.0);
  }

  void _resetZoom() {
    _controller.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Receipt Preview',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolbarButton(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(width: 4),
                _ToolbarButton(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(width: 4),
                _ToolbarButton(icon: Icons.refresh, onPressed: _resetZoom),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Image viewer
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onDoubleTap: _resetZoom,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: widget.minScale,
                  maxScale: widget.maxScale,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: Image(
                    image: widget.imageProvider,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stack,
                        ) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(height: 8),
                              const Text('Could not load image'),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolbarButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderSm,
          ),
        ),
      ),
    );
  }
}
