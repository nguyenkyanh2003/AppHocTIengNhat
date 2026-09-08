export 'audio_source_resolver_stub.dart'
    if (dart.library.io) 'audio_source_resolver_io.dart'
    if (dart.library.js_interop) 'audio_source_resolver_web.dart';
