// Renders a MIDI file to a 16-bit stereo WAV with a SoundFont, using
// TinySoundFont (schellingb/TinySoundFont, MIT). The original game plays
// PINBALL.MID through the Windows MIDI synthesizer; this makes a recording
// of it the app can play.
//
//   render_midi <soundfont.sf2> <in.mid> <out.wav> [sample rate]
//
// The recording is exactly as long as the MIDI file, so it loops as the
// original's music does (Mix_PlayMusic(track, -1)): notes still sounding
// at the end are cut, as a MIDI restart cuts them.
#define TSF_IMPLEMENTATION
#include "tsf.h"
#define TML_IMPLEMENTATION
#include "tml.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void put32(FILE *f, unsigned v) { fwrite(&v, 4, 1, f); }
static void put16(FILE *f, unsigned short v) { fwrite(&v, 2, 1, f); }

int main(int argc, char **argv) {
  if (argc < 4) {
    fprintf(stderr, "usage: render_midi <sf2> <mid> <wav> [rate]\n");
    return 1;
  }
  int rate = argc > 4 ? atoi(argv[4]) : 44100;
  tsf *sf = tsf_load_filename(argv[1]);
  if (!sf) { fprintf(stderr, "cannot load %s\n", argv[1]); return 1; }
  tml_message *midi = tml_load_filename(argv[2]);
  if (!midi) { fprintf(stderr, "cannot load %s\n", argv[2]); return 1; }
  unsigned length_ms = 0;
  tml_get_info(midi, NULL, NULL, NULL, NULL, &length_ms);

  // -6 dB: at full gain the busiest passages clip.
  tsf_set_output(sf, TSF_STEREO_INTERLEAVED, rate, -6.0f);
  // GM drums on channel 10.
  tsf_channel_set_bank_preset(sf, 9, 128, 0);

  FILE *out = fopen(argv[3], "wb");
  if (!out) { fprintf(stderr, "cannot write %s\n", argv[3]); return 1; }
  unsigned frames = (unsigned)((double)length_ms * rate / 1000.0);
  unsigned bytes = frames * 4;
  fwrite("RIFF", 1, 4, out); put32(out, 36 + bytes);
  fwrite("WAVEfmt ", 1, 8, out); put32(out, 16);
  put16(out, 1); put16(out, 2); put32(out, rate); put32(out, rate * 4);
  put16(out, 4); put16(out, 16);
  fwrite("data", 1, 4, out); put32(out, bytes);

  enum { BLOCK = 64 };
  short buf[BLOCK * 2];
  double ms = 0;
  tml_message *m = midi;
  for (unsigned done = 0; done < frames;) {
    unsigned n = frames - done < BLOCK ? frames - done : BLOCK;
    for (ms += n * 1000.0 / rate; m && m->time <= ms; m = m->next) {
      switch (m->type) {
        case TML_PROGRAM_CHANGE:
          tsf_channel_set_presetnumber(sf, m->channel, m->program,
                                       m->channel == 9);
          break;
        case TML_NOTE_ON:
          tsf_channel_note_on(sf, m->channel, m->key, m->velocity / 127.0f);
          break;
        case TML_NOTE_OFF:
          tsf_channel_note_off(sf, m->channel, m->key);
          break;
        case TML_PITCH_BEND:
          tsf_channel_set_pitchwheel(sf, m->channel, m->pitch_bend);
          break;
        case TML_CONTROL_CHANGE:
          tsf_channel_midi_control(sf, m->channel, m->control,
                                   m->control_value);
          break;
      }
    }
    tsf_render_short(sf, buf, n, 0);
    fwrite(buf, 4, n, out);
    done += n;
  }
  fclose(out);
  printf("%s: %.1f s\n", argv[3], length_ms / 1000.0);
  tml_free(midi);
  tsf_close(sf);
  return 0;
}
