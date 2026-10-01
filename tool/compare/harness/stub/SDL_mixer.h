// Silent stand-in for SDL_mixer: the measurement harness needs no audio.
#pragma once
#include "SDL.h"
#define SDL_MIXER_MAJOR_VERSION 2
#define SDL_MIXER_MINOR_VERSION 6
#define SDL_MIXER_PATCHLEVEL 0
#define MIX_INIT_FLUIDSYNTH 0x20
#define MIX_INIT_MID 0x20
#define MIX_MAX_VOLUME 128
#define MIX_DEFAULT_FREQUENCY 44100
#define MIX_DEFAULT_FORMAT AUDIO_S16SYS
struct Mix_Chunk { int dummy; };
struct Mix_Music;
inline int Mix_Init(int) { return 0; }
inline void Mix_Quit() {}
inline int Mix_OpenAudio(int, Uint16, int, int) { return -1; }
inline void Mix_CloseAudio() {}
inline int Mix_AllocateChannels(int n) { return n; }
inline Mix_Chunk* Mix_LoadWAV(const char*) { return nullptr; }
inline void Mix_FreeChunk(Mix_Chunk*) {}
inline Mix_Music* Mix_LoadMUS_RW(SDL_RWops* rw, int freesrc) { if (freesrc && rw) SDL_RWclose(rw); return nullptr; }
inline void Mix_FreeMusic(Mix_Music*) {}
inline int Mix_PlayChannel(int, Mix_Chunk*, int) { return -1; }
inline int Mix_PlayMusic(Mix_Music*, int) { return -1; }
inline int Mix_HaltChannel(int) { return 0; }
inline int Mix_HaltMusic() { return 0; }
inline void Mix_Pause(int) {}
inline void Mix_Resume(int) {}
inline int Mix_Playing(int) { return 0; }
inline int Mix_SetPosition(int, Sint16, Uint8) { return 0; }
inline int Mix_Volume(int, int v) { return v; }
inline int Mix_VolumeMusic(int v) { return v; }
