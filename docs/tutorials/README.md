# RetroFPGA Basys 3 — Tutorials 001–009 (expanded lab edition)

English, Linux terminal/Vim-first educational series.

## Contents

- `tutorials/` — nine Markdown tutorials; 001–008 include added reproducible lab sections
- `reference-t008/` — preserved source and top-level testbench from the supplied Tutorial 008 Fixed archive
- `examples/t001/` — reconstructed teaching counter and testbench (NOT historical source)
- `examples/t002/` — pixel-enable testbench
- `examples/t003/` — complete VGA timing frame testbench
- `examples/t004/` — color-bar testbench
- `scripts/test_examples.sh` — run standalone checks and the archived top-level integration test

## Quick start

```bash
sudo apt update
sudo apt install -y verilator make g++
./scripts/test_examples.sh
```

## Evidence and limitations

Tutorial 009 hardware evidence: photo of VGA six-architecture menu and user-confirmed Up/Down navigation. The CPU architectures remain placeholders. Select/Back and permanent SPI Flash programming have not been verified. The archived Tutorial 008 RTL uses four menu entries, unlike Tutorial 009's six. The source of Tutorial 001 was unavailable and its example is explicitly reconstructed. New standalone testbenches in this bundle are supplemental exercises, not historical artifacts.

Do not merge the archived `reference-t008/rtl` over your current repository without comparing versions.
