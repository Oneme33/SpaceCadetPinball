import 'dart:js_interop';

@JS('spaceCadetAudioSession')
external JSFunction? get _setSession;

/// iOS Safari (Audio Session API): "playback" plays on the silent switch
/// but stops other apps' audio; "ambient" plays along with it. The game
/// only takes over the audio while its music is on, so with the music off
/// your own music keeps playing next to the effects.
void setAudioMixing(bool mix) =>
    _setSession?.callAsFunction(null, (mix ? 'ambient' : 'playback').toJS);
