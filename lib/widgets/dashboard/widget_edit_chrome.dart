import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Action emitted by the per-widget overflow menu.
enum WidgetEditAction { rename, duplicate, lock, resetSize, remove }

/// Overlay rendered on top of every dashboard widget while edit mode is
/// active.
///
/// Visual elements:
/// - dashed gold-tinted outline around the widget
/// - top-left "drag" handle pill (icon + tooltip)
/// - top-right overflow menu pill
/// - 8 resize handles (4 corners + 4 edge midpoints)
///
/// All hit areas are >= 44x44 for accessibility. The chrome is meant to be
/// stacked on top of the widget content; the underlying drag/resize
/// gestures are still owned by the dashboard grid library — this overlay
/// purely communicates affordance.
class WidgetEditChrome extends StatelessWidget {
  final ValueChanged<WidgetEditAction> onAction;
  final bool isLocked;
  final bool isActiveDrag;
  final String? semanticsLabel;

  const WidgetEditChrome({
    super.key,
    required this.onAction,
    this.isLocked = false,
    this.isActiveDrag = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final outlineColor = t.gold.withValues(alpha: 0.45);

    return IgnorePointer(
      ignoring: false,
      child: Semantics(
        container: true,
        label: semanticsLabel ?? l10n.editModeWidgetSemantics,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            // Dashed gold outline.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DashedOutlinePainter(
                    color: outlineColor,
                    strokeWidth: isActiveDrag ? 2 : 1.5,
                    radius: AppRadius.lg,
                    dashLength: 6,
                    gapLength: 4,
                  ),
                ),
              ),
            ),

            // Top action cluster: drag handle (left) + menu (right).
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Row(
                children: <Widget>[
                  _ChromePill(
                    icon: Icons.drag_indicator_rounded,
                    tooltip: l10n.editModeWidgetDragHandleLabel,
                    fill: t.gold,
                    glyphColor: t.onGold,
                  ),
                  const Spacer(),
                  _OverflowMenuButton(
                    fill: t.gold,
                    glyphColor: t.onGold,
                    isLocked: isLocked,
                    tooltip: l10n.editModeWidgetOptionsLabel,
                    onAction: onAction,
                  ),
                ],
              ),
            ),

            // 8 resize handles.
            ..._buildResizeHandles(fill: t.gold, borderColor: t.onGold),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles({
    required Color fill,
    required Color borderColor,
  }) {
    const positions = <_HandlePosition>[
      _HandlePosition(top: -6, left: -6, kind: _HandleKind.corner),
      _HandlePosition(top: -6, right: -6, kind: _HandleKind.corner),
      _HandlePosition(bottom: -6, left: -6, kind: _HandleKind.corner),
      _HandlePosition(bottom: -6, right: -6, kind: _HandleKind.corner),
      _HandlePosition(top: -6, kind: _HandleKind.edgeHorizontal),
      _HandlePosition(bottom: -6, kind: _HandleKind.edgeHorizontal),
      _HandlePosition(left: -6, kind: _HandleKind.edgeVertical),
      _HandlePosition(right: -6, kind: _HandleKind.edgeVertical),
    ];
    return positions
        .map((p) => _ResizeHandle(
              position: p,
              fill: fill,
              borderColor: borderColor,
            ))
        .toList(growable: false);
  }
}

/// Small rounded pill used for the drag handle (and a base for the menu
/// button). Sized so that the surrounding hit-target reaches 44x44.
class _ChromePill extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color fill;
  final Color glyphColor;

  const _ChromePill({
    required this.icon,
    required this.tooltip,
    required this.fill,
    required this.glyphColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.iconButton),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: fill.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: glyphColor),
          ),
        ),
      ),
    );
  }
}

class _OverflowMenuButton extends StatelessWidget {
  final Color fill;
  final Color glyphColor;
  final bool isLocked;
  final String tooltip;
  final ValueChanged<WidgetEditAction> onAction;

  const _OverflowMenuButton({
    required this.fill,
    required this.glyphColor,
    required this.isLocked,
    required this.tooltip,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<WidgetEditAction>(
        tooltip: tooltip,
        onSelected: onAction,
        offset: const Offset(0, 36),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        itemBuilder: (BuildContext _) {
          return <PopupMenuEntry<WidgetEditAction>>[
            _menuItem(
              value: WidgetEditAction.rename,
              icon: Icons.edit_rounded,
              label: l10n.editModeMenuRename,
              color: t.text,
            ),
            _menuItem(
              value: WidgetEditAction.duplicate,
              icon: Icons.copy_rounded,
              label: l10n.editModeMenuDuplicate,
              color: t.text,
            ),
            _menuItem(
              value: WidgetEditAction.lock,
              icon:
                  isLocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              label: isLocked ? l10n.editModeMenuUnlock : l10n.editModeMenuLock,
              color: t.text,
            ),
            _menuItem(
              value: WidgetEditAction.resetSize,
              icon: Icons.aspect_ratio_rounded,
              label: l10n.editModeMenuResetSize,
              color: t.text,
            ),
            const PopupMenuDivider(),
            _menuItem(
              value: WidgetEditAction.remove,
              icon: Icons.delete_outline_rounded,
              label: l10n.editModeMenuRemove,
              color: t.error.text,
            ),
          ];
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.iconButton),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: fill.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.more_horiz_rounded, size: 16, color: glyphColor),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<WidgetEditAction> _menuItem({
    required WidgetEditAction value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<WidgetEditAction>(
      value: value,
      // Min hit area >= 44 satisfied by Material's default item height.
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.bodyStyle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

enum _HandleKind { corner, edgeHorizontal, edgeVertical }

class _HandlePosition {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final _HandleKind kind;
  const _HandlePosition({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.kind,
  });
}

class _ResizeHandle extends StatelessWidget {
  final _HandlePosition position;
  final Color fill;
  final Color borderColor;
  const _ResizeHandle({
    required this.position,
    required this.fill,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCorner = position.kind == _HandleKind.corner;
    final size = isCorner ? 14.0 : 10.0;
    final shape = isCorner
        ? BoxShape.circle
        : BoxShape.rectangle;
    final BorderRadius? radius =
        isCorner ? null : BorderRadius.circular(AppRadius.xs);

    final child = IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: radius,
          color: fill,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: fill.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );

    Widget aligned = child;
    if (!isCorner) {
      // For an edge handle, stretch a thin chip along the side and center
      // the dot inside it. The grid library still owns the actual resize
      // gesture; this is purely affordance, so we keep it pointer-passive.
      if (position.kind == _HandleKind.edgeHorizontal) {
        aligned = Container(
          alignment: Alignment.center,
          width: 36,
          height: 18,
          child: child,
        );
      } else {
        aligned = Container(
          alignment: Alignment.center,
          width: 18,
          height: 36,
          child: child,
        );
      }
    }

    // Edge handles need to span the appropriate axis.
    final positioned = position.kind == _HandleKind.edgeHorizontal
        ? Positioned(
            top: position.top,
            bottom: position.bottom,
            left: 0,
            right: 0,
            child: Center(child: aligned),
          )
        : position.kind == _HandleKind.edgeVertical
            ? Positioned(
                left: position.left,
                right: position.right,
                top: 0,
                bottom: 0,
                child: Center(child: aligned),
              )
            : Positioned(
                top: position.top,
                bottom: position.bottom,
                left: position.left,
                right: position.right,
                child: aligned,
              );

    return positioned;
  }
}

/// Paints a dashed rounded rectangle. Kept simple and dependency-free —
/// uses [Path.computeMetrics] to walk the perimeter and emit dash segments.
class _DashedOutlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  _DashedOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(
            distance,
            next.clamp(0, metric.length).toDouble(),
          ),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
