import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zoom scale logic', () {
    test('zoom in increases scale by 1.2x', () {
      final controller = TransformationController();
      final Matrix4 m = controller.value.clone()
        ..scaleByDouble(1.2, 1.2, 1.2, 1.0);
      controller.value = m;
      final double scale = controller.value.getMaxScaleOnAxis();
      expect(scale, closeTo(1.2, 0.001));
    });

    test('zoom out decreases scale by 1/1.2', () {
      final controller = TransformationController();
      // Start at 1.2x then zoom out
      final Matrix4 zoomedIn = controller.value.clone()
        ..scaleByDouble(1.2, 1.2, 1.2, 1.0);
      controller.value = zoomedIn;
      final Matrix4 zoomedOut = controller.value.clone()
        ..scaleByDouble(1 / 1.2, 1 / 1.2, 1 / 1.2, 1.0);
      controller.value = zoomedOut;
      final double scale = controller.value.getMaxScaleOnAxis();
      expect(scale, closeTo(1.0, 0.001));
    });

    test('reset returns to identity', () {
      final controller = TransformationController();
      final Matrix4 m = controller.value.clone()
        ..scaleByDouble(2.5, 2.5, 2.5, 1.0);
      controller.value = m;
      controller.value = Matrix4.identity();
      expect(controller.value, equals(Matrix4.identity()));
    });
  });
}
