# Holodeck Zig — Charter

## Mission
Implement the Holodeck Studio in Zig, using comptime for room generation and cross-compilation.

## Architecture
```
src/
  main.zig        — event loop
  room.zig        — comptime room generation
  agent.zig       — agent session
  command.zig     — command dispatch
  comms.zig       — communication
  live.zig        — live connections
  combat.zig      — oversight
  manual.zig      — living manual
  conformance.zig — tests
```

## The Deep Question
Can rooms be generated at comptime? Can the room graph be validated at compile time?
What does "no hidden control flow" mean for a MUD server?
What does Zig teach us about the boundary between compile-time and runtime?
