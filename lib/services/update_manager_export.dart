// Conditional export: native (dart:io) vs web
export 'update_manager_stub.dart'
    if (dart.library.io) 'update_checker_native.dart';
