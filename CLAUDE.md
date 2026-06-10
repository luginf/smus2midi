# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

`smus2midi` is a small command-line converter that reads IFF-based `.smus` files (the "SMUS" / SoundTracker-family score format, e.g. produced by Music-X / Deluxe Music) and writes standard MIDI `.mid` files with the same base name.

Known limitation: handling of some rests is still incorrect (see README.md).

## Build

No build system (no Makefile/CMake) — compile directly.

### Linux / macOS
```bash
g++ -std=c++17 -O2 -Iinclude main.cpp -o smus2midi
```

### Windows
Open `winsmus2midi.sln` in Visual Studio and build.

## Run
```bash
./smus2midi smus_file1 [smus_file2 [smus_file3 [...]]]
```
Each input `.smus` file is converted to `<basename>.mid` next to the input file. Running with no arguments prints usage.

## Testing
There is no automated test suite. To sanity-check changes, build and run the binary against the sample `.smus` files in the repo root (e.g. `Sonate2.1A.smus`, which has a corresponding `Sonate2.1A.smus.mid` reference output) and inspect the console output and resulting `.mid` file.

## Architecture

Everything lives in a single file, `main.cpp`. MIDI file writing is delegated to the bundled header-only library `include/cxxmidi/` (vendored third-party code — keep changes there minimal and only for compatibility fixes).

Conversion pipeline in `main.cpp`:
1. **Load**: the whole `.smus` file is read into a single in-memory buffer.
2. **IFF header validation**: checks for the `FORM` / `SMUS` / `SHDR` chunk sequence at fixed offsets. Any mismatch aborts that file with an error message (processing continues with the next file in `argv`).
3. **SHDR parsing**: extracts tempo, default velocity/volume, and track count from fixed offsets, then derives the MIDI tick delta-time (`dt`) for a quarter note via `CxxMidi::Converters::us2dt`.
4. **Variable chunk loop** (`parseNextChunk`): walks IFF chunks (2-byte aligned) starting at offset 24 until `formLength` is reached.
   - `TRAK` chunks contain the actual note/event data and are converted (see step 5).
   - `INS1`, `NAME`, and other chunks are only logged for information and otherwise ignored.
5. **Track/event decoding** (`parseSEvent`):
   - Each track is a sequence of 2-byte "SEvents" encoding note pitch + duration/dot/tuplet/chord/tie flags, or control codes (program change `129`/`134`, volume `132`).
   - Notes/rests/program changes are expanded into absolute-time `MidiEvent` structs (note-on/off pairs, program changes), tracking a running absolute `time` and `velocity`.
   - Events are stable-sorted by absolute time (`MidiEventCompare`), then converted to delta-time `CxxMidi::Event`s pushed onto a `CxxMidi::Track`. Tied notes are merged with the following note-on of the same pitch at the same time instead of emitting a separate note-off.
6. **Save**: the populated `CxxMidi::File` is written via `saveAs()` to `<basename>.mid`.

### cxxmidi compatibility notes
`include/cxxmidi/` is a vendored MIDI library originally written for MSVC. Two fixes were applied to make it build with modern GCC/C++17 (do not reintroduce these patterns when updating the library):
- `time/point.hpp`: `sscanf_s` → `sscanf` (with `<cstdio>` included).
- `file.hpp`: `std::fstream::streampos` → `std::fstream::pos_type` (used for `tellg()`/length-difference arithmetic).
