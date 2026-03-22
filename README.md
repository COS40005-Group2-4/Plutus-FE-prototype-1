# plutus_fe_prototype

A new Flutter project.

## Checklist
###Initiate project
flutter run --dart-define-from-file=.env

###Build libc
```bash
go build -o libplutus.dll -buildmode=c-shared ./ffi.go
```

for Linux:
```bash
go build -o libplutus.dll -buildmode=c-shared ./ffi.go
```

Copy `libplutus.so` to folder `linux` in project root dir


for Android (ARMv8):
```bash
GOARCH=arm64 go build -o libplutus.so -buildmode=c-shared ./ffi.go
```

Copy `libplutus.so` to folder `android/src/main/jniLibs/arm64-v8a/` in project root dir

###Build APK on emulator
```bash
flutter install -d emulator-5554
```

## Sample Resoureces

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

sudo xcode-select -s /Application/Xcode.app/Contents/Developer
