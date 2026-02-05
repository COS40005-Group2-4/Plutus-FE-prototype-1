// Conditional export for file handling
export 'file_handler_stub.dart' 
    if (dart.library.io) 'file_handler_io.dart';
