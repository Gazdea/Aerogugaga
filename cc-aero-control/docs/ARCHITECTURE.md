# Architecture

## Overview

A modular ComputerCraft: Tweaked dashboard, control, and trigger system for
Minecraft airships. Reads peripherals (gimbal, altitude, velocity, navigation),
processes redstone inputs, evaluates trigger rules, and renders to a terminal
or monitor.

## Directory Layout

```
Aerogugaga/
├── dashboard.lua              Entry point — orchestrates modules
├── peripheral_interfaces.lua  Auto-generated peripheral proxy wrappers
│
├── lib/                       Standalone libraries (copy to any project)
│   ├── proxy.lua              pcall-wrapped peripheral.call / wrap
│   ├── i18n.lua               Dot-path translation engine
│   └── font.lua               Cyrillic textpack encoder
│
├── src/                       Project-specific modules
│   ├── config.lua             JSON config loader with defaults
│   ├── state.lua              Central state container
│   ├── scanner.lua            Peripheral data reader
│   ├── control.lua            Redstone input → action processor
│   ├── trigger.lua            Condition evaluator with hysteresis
│   ├── output.lua             Trigger action executor
│   └── display.lua            Terminal/monitor renderer
│
├── config/                    JSON configuration files
│   ├── settings.json
│   ├── bindings.json
│   ├── sensors.json
│   └── triggers.json
│
├── i18n/                      Translation data files
│   ├── en.lua
│   └── ru.lua
│
└── docs/                      Documentation
    ├── ARCHITECTURE.md
    ├── MODULES.md
    ├── CONFIG.md
    └── I18N.md
```

## Data Flow

```
                    ┌──────────────────┐
                    │  hardware        │
                    │  peripherals     │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  scanner.scan()  │
                    │  ─────────────── │
                    │  gimbal → angles │
                    │  altitude → h,pr │
                    │  velocity → xyz  │
                    │  nav → rel_angle │
                    └────────┬─────────┘
                             │ readings{}
                             ▼
           ┌─────────────────┬─────────────────┐
           │                 │                 │
           ▼                 ▼                 ▼
   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
   │ control.tick │  │ trigger.tick │  │ display.rend │
   │              │  │              │  │              │
   │ redstone.in  │  │ eval rules   │  │ format + out │
   │ → controls{} │  │ → triggers{} │  │ term/monitor │
   └──────┬───────┘  └──────┬───────┘  └──────────────┘
          │                 │
          ▼                 ▼
   ┌──────────────┐  ┌──────────────┐
   │ state.ctrl   │  │ output.tick  │
   │ (in-place)   │  │              │
   │              │  │ redstone.out │
   └──────────────┘  │ peripheral   │
                     └──────────────┘
```

**Tick cycle** (every `update_interval` seconds):
1. `scanner.scan()` → readings table
2. `state.updateReadings(readings)`
3. `control.tick(state)` — reads redstone inputs, updates controls
4. `trigger.tick(readings, state)` — evaluates conditions, updates trigger state
5. `output.tick(state)` — applies trigger actions to outputs
6. `display.render(readings, state)` — draws dashboard

## SOLID Principles

| Principle | Implementation |
|---|---|
| **Single Responsibility** | Each module has exactly one concern: scan, control, trigger, output, display |
| **Open/Closed** | Add new control actions (bindings.json action field) or new trigger conditions (triggers.json condition.source) without modifying module code |
| **Liskov Substitution** | Render output works identically for `term` and `monitor` objects |
| **Interface Segregation** | Modules only depend on the functions they need (`trigger` doesn't know about `display`) |
| **Dependency Inversion** | All modules depend on `state` as an abstraction, not on concrete peripheral APIs |

## Module Dependencies

```
dashboard.lua
  ├── lib/i18n.lua          (standalone)
  ├── lib/font.lua          (standalone, loaded on demand)
  ├── src/config.lua
  │     └── fs, textutils   (CC:T built-in)
  ├── src/state.lua         (no dependencies — pure data)
  ├── src/scanner.lua
  │     ├── peripheral_interfaces.lua
  │     │     └── lib/proxy.lua  (standalone)
  │     └── src/config.lua
  ├── src/control.lua
  │     ├── redstone        (CC:T built-in)
  │     └── src/config.lua
  ├── src/trigger.lua
  │     └── src/config.lua
  ├── src/output.lua
  │     ├── redstone        (CC:T built-in)
  │     └── src/config.lua
  └── src/display.lua
        ├── lib/i18n.lua
        └── lib/font.lua    (conditionally loaded for ru locale)

All dotted ──> are `require()` relationships.
CC:T built-in globals: fs, textutils, redstone, peripheral, term, colors
```

## Extension Points

| What to add | Files to touch |
|---|---|
| New control action type | `src/control.lua` (new `elseif` in action dispatcher) + docs |
| New trigger condition source | `triggers.json` (any dot-path into readings) — no code change |
| New trigger action type | `src/output.lua` (new action handler) |
| New display locale | `i18n/<lang>.lua` + textpack encoding in `lib/font.lua` |
| New peripheral type | `perepherials.lua` generator handles this automatically |
| New sensor data source | `src/scanner.lua` (add sensor read logic) + `src/state.lua` (add field) |
