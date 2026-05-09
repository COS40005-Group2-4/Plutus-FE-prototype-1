import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_elevation.dart';

/// Tweens the active [ThemeData] over time when the resolved [Brightness]
/// changes, instead of letting Material snap to the new theme in a single
/// frame.
///
/// Reads its target theme from the nearest enclosing [Theme] (i.e. whatever
/// `MaterialApp` is currently exposing). When that theme's brightness flips,
/// it captures the previously-rendered theme as the start of the tween and
/// `ThemeData.lerp`s to the new one over [duration] using [curve]. Theme
/// changes that don't cross brightness (e.g. a font-scale tweak) are adopted
/// instantly to avoid wasteful rebuilds.
///
/// Also republishes a [SystemUiOverlayStyle] that follows the lerped theme so
/// the status bar / system nav don't snap mid-tween, and exposes a
/// [BrightnessBlend] inherited so that descendants painting brightness-keyed
/// colors (such as `GlassBackground`) can lerp their own palette in lockstep.
class AnimatedThemeScope extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedThemeScope({
    super.key,
    required this.child,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.standard,
  });

  @override
  State<AnimatedThemeScope> createState() => _AnimatedThemeScopeState();
}

class _AnimatedThemeScopeState extends State<AnimatedThemeScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ThemeData? _from;
  ThemeData? _to;
  Brightness? _fromBrightness;
  Brightness? _toBrightness;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData incoming = Theme.of(context);

    if (_to == null) {
      _from = incoming;
      _to = incoming;
      _fromBrightness = incoming.brightness;
      _toBrightness = incoming.brightness;
      _controller.value = 1.0;
      return;
    }

    if (incoming == _to) return;

    if (incoming.brightness != _to!.brightness) {
      // Snapshot whatever we're currently rendering so the tween starts from
      // the visible state instead of the previous target.
      _from = ThemeData.lerp(_from!, _to!, _controller.value);
      _fromBrightness = _toBrightness;
      _to = incoming;
      _toBrightness = incoming.brightness;
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    } else {
      // Same brightness, only secondary theme fields changed: adopt instantly.
      _from = incoming;
      _to = incoming;
      _fromBrightness = incoming.brightness;
      _toBrightness = incoming.brightness;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SystemUiOverlayStyle _overlayFor(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      final ThemeData target = _to ?? Theme.of(context);
      return BrightnessBlend(
        from: target.brightness,
        to: target.brightness,
        progress: 1.0,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayFor(target),
          child: widget.child,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = widget.curve.transform(_controller.value);
        final ThemeData lerped = ThemeData.lerp(_from!, _to!, t);
        return BrightnessBlend(
          from: _fromBrightness!,
          to: _toBrightness!,
          progress: t,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _overlayFor(lerped),
            child: Theme(data: lerped, child: child!),
          ),
        );
      },
    );
  }
}

/// Inherited descriptor of the in-flight brightness crossfade.
///
/// Widgets that paint with brightness-keyed tokens (e.g. `GlassBackground`)
/// can read this to lerp their own colors in lockstep with the theme tween,
/// instead of snapping when `Theme.of(context).brightness` flips at midpoint.
///
/// When no tween is active, [from] and [to] are equal and [progress] is 1.0.
class BrightnessBlend extends InheritedWidget {
  final Brightness from;
  final Brightness to;
  final double progress;

  const BrightnessBlend({
    super.key,
    required this.from,
    required this.to,
    required this.progress,
    required super.child,
  });

  static BrightnessBlend? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrightnessBlend>();
  }

  /// Returns `lerp(brightnessKeyed(from), brightnessKeyed(to), progress)`.
  /// When the tween is idle, this collapses to a single lookup.
  Color lerpColor(Color Function(Brightness) brightnessKeyed) {
    if (from == to || progress >= 1.0) return brightnessKeyed(to);
    if (progress <= 0.0) return brightnessKeyed(from);
    return Color.lerp(brightnessKeyed(from), brightnessKeyed(to), progress)!;
  }

  @override
  bool updateShouldNotify(BrightnessBlend oldWidget) {
    return from != oldWidget.from ||
        to != oldWidget.to ||
        progress != oldWidget.progress;
  }
}
