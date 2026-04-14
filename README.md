# holodeck-zig

A Zig implementation of the **FLUX-LCAR holodeck protocol** — a compile-time room generation system where spatial structures are defined, validated, and woven into the binary before it ships.

```
Zig 0.14.0  ·  0 dependencies  ·  5/5 tests passing
```

---

## Overview

The holodeck protocol models virtual spaces as **rooms** connected by **exits**, inhabited by **agents** governed by a **permission hierarchy**. Think of it as the runtime substrate for a fleet simulation — a room graph where every chamber has an identity, a state, and an access control model.

`holodeck-zig` explores what happens when you push room generation into Zig's `comptime`. Room definitions become compile-time constants. Graph connectivity can be verified at build time, not runtime. The binary that ships is already fully aware of its topology — no config parsing, no schema validation at startup, no "oops, room ID not found" in production.

On boot, the system seeds three rooms (The Harbor, The Tavern, The Workshop), activates the Harbor for a test agent (`oracle1`), then shuts down cleanly — demonstrating the full lifecycle in under 25 lines of `main`.

---

## Comptime Architecture

Zig's `comptime` is not a macro system or a code generator — it's the same language executing at compile time with full type safety. This is what makes holodeck-zig possible:

### What runs at compile time

| Concern | How |
|---|---|
| **Room definitions** | Room structs with `[]const u8` fields can be initialized as comptime constants — names, descriptions, and exit tables baked into the binary's rodata segment. |
| **Enum derivation** | `PermissionLevel` is a `u8`-backed enum; its ordinal values exist at comptime, enabling `@intFromEnum` checks that fold into constant comparisons. |
| **Type-level capacity** | `MAX_ROOMS = 64` is a comptime constant that sizes the `RoomGraph` array — changing it ripples through the type system automatically. |
| **Struct layout** | Every field, every method signature, every optional (`?`) is resolved at comptime. There is no vtable, no hidden indirection. |

### What runs at runtime

| Concern | How |
|---|---|
| **Room lifecycle** | `boot()` / `shutdown()` mutate `bool booted` and `?[]const u8 active_agent` — stateful transitions happen at runtime. |
| **Graph mutations** | `create_room()` checks capacity and duplicates, `find_room()` walks the array — both are runtime operations on the `RoomGraph`. |
| **Permission checks** | `Agent.can()` compares enum ordinals at runtime to gate actions like `"build"`. |

### The boundary

The key insight: **structure is comptime, state is runtime**. The shape of every room, the permission ladder, the graph capacity — these are facts known at build time. Which rooms are booted, which agent occupies them, whether a greenhorn can build — these are questions answered at runtime. Zig makes this boundary explicit, unlike languages that blur it with reflection or dynamic dispatch.

---

## Core Types

### `Room`

The fundamental unit. Every room has an identity, a textual presence, connectivity, and a lifecycle state.

```zig
pub const Room = struct {
    id: []const u8,           // Unique identifier, e.g. "harbor"
    name: []const u8,         // Display name, e.g. "The Harbor"
    description: []const u8,  // Flavor text
    exits: []Exit,            // Directed exits to other rooms
    notes: []Note,            // Author-content pairs attached to the room
    booted: bool,             // Whether the room is currently active
    active_agent: ?[]const u8, // Agent currently occupying the room
};
```

**Methods:** `init(id, name, desc)` — creates an empty room; `boot(agent)` — activates the room for an agent; `shutdown()` — deactivates and clears the occupant.

### `RoomGraph`

A fixed-capacity sparse array holding all rooms in the holodeck.

```zig
pub const RoomGraph = struct {
    rooms: [MAX_ROOMS]?Room,  // 64 optional slots
    count: usize,              // Number of occupied slots
};
```

**Methods:** `init()` — zeroes all slots; `create_room(id, name, desc)` — adds a room, rejects duplicates and overflow; `find_room(id)` — returns a mutable pointer or null.

### `Agent`

An entity that occupies rooms and has a permission level.

```zig
pub const Agent = struct {
    name: []const u8,         // Agent identifier
    room_id: []const u8,      // Current room
    level: PermissionLevel,   // Position in the hierarchy
};
```

**Methods:** `init(name, start_room)` — creates a Greenhorn-level agent; `can(action)` — checks permission: `"look"`, `"go"`, `"say"` are universal; `"build"` requires Specialist or above.

### `PermissionLevel`

A six-tier hierarchy following the PLATO model:

| Level | Ordinal | Can build? |
|---|---|---|
| Greenhorn | 0 | No |
| Crew | 1 | No |
| Specialist | 2 | Yes |
| Captain | 3 | Yes |
| Cocapn | 4 | Yes |
| Architect | 5 | Yes |

### Supporting Types

- **`Note`** — `{ author: []const u8, content: []const u8 }` — a simple author-content pair for room annotations.
- **`Exit`** — `{ direction: []const u8, target_id: []const u8 }` — a directed edge from one room to another.

---

## Tests

Five tests covering the full domain:

| Test | Validates |
|---|---|
| `room create and boot` | Room initialization, boot lifecycle, agent tracking |
| `room graph create` | Duplicate ID rejection, count accuracy |
| `room graph find` | Lookup by ID, name field access |
| `agent permissions` | Greenhorn cannot build, Captain can |
| `room shutdown` | Boot then shutdown returns room to inactive state |

---

## Build & Test

Requires [Zig 0.14.0](https://ziglang.org/download/). No external dependencies — no git submodules, no package manager, no fetch step.

```bash
zig build test          # Run all 5 tests
zig build run           # Seed rooms, boot harbor for oracle1, shutdown
zig build               # Compile the binary (outputs zig-out/bin/holodeck-zig)
```

Cross-compile for any supported target:

```bash
zig build -Dtarget=aarch64-linux-gnu    # ARM64 Linux
zig build -Dtarget=x86_64-windows       # x86_64 Windows
zig build -Dtarget=wasm32-freestanding  # WebAssembly
zig build -Dtarget=riscv64-linux         # RISC-V 64
```

Release-optimized builds:

```bash
zig build -Doptimize=ReleaseFast        # Optimized for speed
zig build -Doptimize=ReleaseSafe        # Optimized, safety checks retained
zig build -Doptimize=ReleaseSmall       # Optimized for binary size
```

---

## Why Zig

This project was written in Zig because the holodeck protocol's requirements map directly to Zig's strengths:

### Comptime generics

Room definitions, permission levels, and graph capacity are all resolved at compile time. There are no runtime type checks, no reflection, no "deserialize and hope." The compiler knows the full shape of the system before the first instruction executes.

### No hidden control flow

Every function call, every branch, every allocation is visible in the source. There is no implicit try/catch, no destructor magic, no RAII hidden behind a constructor. When a room boots, you can see exactly what happens: two field assignments and a log line.

### Explicit allocators

Zig passes allocators as parameters — there is no global heap, no `malloc` hiding behind an import. While holodeck-zig currently uses stack allocation and fixed-size arrays, the pattern is ready for heap-backed rooms, arena-allocated graphs, or custom allocators for embedded targets.

### Cross-compilation by default

The same `zig build` invocation targets x86_64, ARM64, RISC-V, or WebAssembly with no toolchain changes. The holodeck protocol has zero external dependencies, so it cross-compiles cleanly to any platform Zig supports — including freestanding environments.

### What this teaches

Where is the real boundary between compile time and runtime? Most languages answer "it depends." Zig answers "it's in the source." holodeck-zig is a concrete demonstration: rooms are defined as data, the compiler folds constants, and the runtime only handles mutable state.

---

## Integration

`holodeck-zig` is a component of the **FLUX ecosystem** — a distributed fleet simulation where autonomous agents navigate spatial environments under a shared protocol.

### Where it fits

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│  oracle1    │───▶│ holodeck-zig │───▶│  flux-runtime   │
│  (agent)    │    │  (rooms)     │    │  (orchestrator) │
└─────────────┘    └──────────────┘    └─────────────────┘
```

- **oracle1** — The first agent in the fleet. `main.zig` boots the Harbor room specifically for oracle1, demonstrating the agent-room lifecycle. In the full ecosystem, oracle1 serves as the bootstrap agent that validates room connectivity and permissions before wider fleet activation.
- **flux-runtime** — The orchestration layer that manages multiple holodeck instances, coordinates cross-room agent movement, and handles persistence. holodeck-zig provides the room model; flux-runtime provides the event loop.
- **LCAR protocol** — The shared contract defining room schemas, exit semantics, and the permission hierarchy. holodeck-zig implements the core data structures; other FLUX components consume them over a well-defined interface.

### Protocol contracts

- Rooms are identified by string IDs (e.g. `"harbor"`, `"tavern"`).
- Exits are directed edges with a human-readable direction and a target room ID.
- Agents carry a permission level that gates destructive operations (`"build"` requires Specialist+).
- The `Note` type provides a generic annotation mechanism for room state.

### Next integration targets

- [ ] Socket layer for multi-agent room access on `:7779`
- [ ] Persistent room state serialization
- [ ] Cross-process holodeck federation via flux-runtime

---

## Project Structure

```
holodeck-zig/
├── build.zig           # Zig build configuration (exe, test, run steps)
├── README.md
├── callsign1.jpg
└── src/
    ├── holodeck.zig    # Core types: Room, Agent, RoomGraph, PermissionLevel, tests
    └── main.zig        # Entry point: seeds 3 rooms, boots harbor, shuts down
```

---

## Dependencies

**Zig 0.14.0.** No external dependencies.

---

<img src="callsign1.jpg" width="128" alt="callsign">
