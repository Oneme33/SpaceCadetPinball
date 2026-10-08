// Whether the game's sound mixes with other apps' audio. Only browsers on
// iOS need it (see web/index.html); elsewhere it does nothing.
export 'audio_session_stub.dart'
    if (dart.library.js_interop) 'audio_session_web.dart';
