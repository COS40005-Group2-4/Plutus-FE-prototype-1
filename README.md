# plutus_fe_prototype

A new Flutter project.

## Checklist
###Initiate project
flutter run --dart-define-from-file=.env

###Build libc
go build -o libplutus.dll -buildmode=c-shared ./main.go

###Build APK on emulator
flutter install -d emulator-5554

## Sample Resoureces

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

sudo xcode-select -s /Application/Xcode.app/Contents/Developer
