// Conditional export that loads the right implementation based on platform
// For web: loads stub implementation
// For native (Windows/macOS/Linux/iOS/Android): loads FFI implementation
export 'backend_ffi_service_stub.dart' 
    if (dart.library.io) 'backend_ffi_service_io.dart';
