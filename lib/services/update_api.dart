// Conditional import: native (dart:io) vs web
import 'update_api_stub.dart'
    if (dart.library.io) 'update_api_native.dart';

export 'update_api_stub.dart'
    if (dart.library.io) 'update_api_native.dart';
