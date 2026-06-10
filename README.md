# smus2midi
A converter for music ".smus" files into MIDI ".mid" files.
Should compile transparently on Win, Nux and OsX.
Almost perfect, still a problem with some rests that need to be fixed.

## Building

### Linux / macOS

Requires a C++17 compiler. The header-only [cxxmidi](include/cxxmidi) library is bundled in `include/`.

```bash
g++ -std=c++17 -O2 -Iinclude main.cpp -o smus2midi
```

### Windows

Open `winsmus2midi.sln` in Visual Studio and build the solution.

## Usage

```bash
./smus2midi smus_file1 [smus_file2 [smus_file3 [...]]]
```

Each input `.smus` file is converted to a `.mid` file with the same base name.
