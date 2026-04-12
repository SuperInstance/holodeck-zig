# Holodeck Zig

Zig implementation of the FLUX-LCAR holodeck protocol.

## What It Teaches

What IS comptime room generation? Can rooms be validated at compile time? No hidden control flow. Explicit allocators. Cross-compilation for embedded targets. Zig shows where the boundary between compile-time and runtime really is.

## Build

```bash
zig build test   # Run tests (5 passing)
zig build run    # Run the server
```

## Status

**5/5 tests passing** ✅

## Architecture

```
src/
  holodeck.zig  — Room, Agent, RoomGraph, tests
  main.zig      — Entry point, seeds 3 rooms
build.zig       — Build configuration
```

## Run

```bash
zig build run  # Seeds 3 rooms, boots harbor for oracle1, shuts down
```

## The Comptime Question

Can we generate rooms at compile time from configuration files? Can the room graph be validated before the binary ships? Zig's comptime makes this possible — room definitions as compile-time constants, graph connectivity verified at build.

## Dependencies

Zig 0.14.0. No external dependencies.
