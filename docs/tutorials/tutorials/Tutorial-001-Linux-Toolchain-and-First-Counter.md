# Tutorial 001 — Linux Toolchain and First Counter

**Project:** [RetroFPGA-Basys3](https://github.com/johntsaiainow/RetroFPGA-Basys3)  
**Platform:** Digilent Basys 3 / Artix-7 `xc7a35tcpg236-1`  
**Workflow:** Ubuntu Linux, Vim, Verilator, SystemVerilog  
**Series:** Tutorials 001–009 (the final Tutorial 009 VGA menu has been verified on physical hardware).

## Objective

Set up a Linux-first SystemVerilog workflow and build the first counter module.

## Place in the series

The first counter and environment were reported as passing in the earlier tutorial sequence; its original source and exact test commands are not included in the available Tutorial 008 archive.

## Source files

Primary module: `rtl/boot/counter.sv`.

## Inspect the implementation

```bash
cd ~/Projects/RetroFPGA-Basys3 || exit 1
vim rtl/boot/counter.sv
```

> The original Tutorial 001 counter source is not present in the available Tutorial 008 archive. No replacement implementation is fabricated here.

## Validation

Use the Verilator simulation/testbench associated with this tutorial in your repository. The exact original per-tutorial command is not established by the available archive; do not assume the Tutorial 009 full-build script reproduces the historical tutorial unchanged.

## Completion criteria

- RTL module is present and understandable.
- Relevant Verilator testbench passes (when available).
- No unsupported claim of hardware verification is made for this individual stage.

## Next

Continue with Tutorial 002.


---

## Reproducible lab supplement — Counter exercise (reconstructed)

### Working directory and prerequisites

The supplemental examples are in the companion ZIP. Extract it, then work from the extracted root (the folder containing `scripts/` and `reference-t008/`):

```bash
cd ~/Downloads/RetroFPGA-Tutorials-Complete
verilator --version
vim tutorials/Tutorial-001-Linux-Toolchain-and-First-Counter.md
```

The **`reference-t008/` sources are an archived Tutorial 008 snapshot**, not an assertion that the exact same code existed at each earlier tutorial. The Tutorial 009 source is in your live Git repository; the archive does not substitute for that checkout.

### Execute the automated exercises

```bash
./scripts/test_examples.sh
```

The runner uses `verilator --binary --timing --assert` for Tutorial 001–004 checks, then executes the archived Tutorial 008 integration test. It stops at the first failure. Do not interpret an integration PASS as proof that every individual module has exhaustive coverage.

### Tutorial 001 counter test

`examples/t001/counter.sv` is a **new, explicitly reconstructed educational example** because the original Tutorial 001 source was not recovered. `examples/t001/tb_counter.sv` checks counting and 4-bit rollover. It is not the historical implementation.

```bash
verilator --binary --timing --assert --top-module tb_counter \
  --Mdir build/tutorial-tests/counter \
  examples/t001/counter.sv examples/t001/tb_counter.sv
./build/tutorial-tests/counter/Vtb_counter
```

Expected: `PASS: Tutorial 001 counter (including rollover)`.

### Completion checklist

- [ ] Inspect the relevant RTL and its interface.
- [ ] Run the automated checks and capture their actual output.
- [ ] Compare expected timing, data, or state transitions with the implementation.
- [ ] Record deviations and update the testbench before calling the lab complete.
