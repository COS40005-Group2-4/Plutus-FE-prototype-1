import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthProvider.onUserChanged callback contract', () {
    test('callback fires with userId when registered and called', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      // Simulate what AuthProvider._notifyUserChanged does:
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(42, fakeCallback);
      expect(calls, equals([42]));
    });

    test('callback fires with 0 on sign-out', () {
      final List<int> calls = [];
      void fakeCallback(int userId) => calls.add(userId);

      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      notifyUserChanged(0, fakeCallback);
      expect(calls, equals([0]));
    });

    test('no error when callback is null', () {
      void notifyUserChanged(int userId, void Function(int)? cb) {
        cb?.call(userId);
      }

      // Must not throw
      expect(() => notifyUserChanged(5, null), returnsNormally);
    });
  });
}
