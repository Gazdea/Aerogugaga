# Architecture

## Overview

A modular ComputerCraft: Tweaked dashboard, control, and trigger system for
Minecraft airships. Reads peripherals (gimbal, altitude, velocity, navigation),
processes redstone inputs, evaluates trigger rules, and renders to a terminal
or monitor.

## Directory Layout

```
Aerogugaga/
├── dashboard.lua              Entry point — orchestrates modules (supports P2P)
├── peripheral_interfaces.lua  Auto-generated peripheral proxy wrappers
│
├── lib/                       Standalone libraries (copy to any project)
│   ├── proxy.lua              pcall-wrapped peripheral.call / wrap
│   ├── i18n.lua               Dot-path translation engine
│   └── font.lua               Cyrillic textpack encoder
│
├── src/                       Project-specific modules
│   ├── config.lua             JSON config loader + node config support
│   ├── state.lua              Central state container + remote merge
│   ├── scanner.lua            Peripheral data reader
│   ├── control.lua            Redstone input → action processor
│   ├── trigger.lua            Condition evaluator with hysteresis
│   ├── output.lua             Trigger action executor (local + remote routing)
│   ├── network.lua            P2P modem communication module
│   └── display.lua            Terminal/monitor renderer
│
├── config/                    JSON configuration files
│   ├── settings.json
│   ├── bindings.json
│   ├── sensors.json
│   ├── triggers.json
│   └── nodes/                 Per-node P2P configurations
│       ├── airship-1.json
│       └── ground-station.json
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

**Tick cycle** — local mode (every `update_interval` seconds):
1. `scanner.scan()` → readings table
2. `state.updateReadings(readings)`
3. `control.tick(state)` — reads redstone inputs, updates controls
4. `trigger.tick(readings, state)` — evaluates conditions, updates trigger state
5. `output.tick(state)` — applies trigger actions to outputs
6. `display.render(readings, state)` — draws dashboard

## P2P Mode

When launched with a node id argument (`dashboard airship-1`), the system
loads `config/nodes/<id>.json` and enables **peer-to-peer** networking.

### P2P Data Flow

```
                        ┌─ Network Channel ─────────────────┐
                        │  modem.transmit / modem_message   │
                        │                                    │
  ┌─ Node A (ship) ─────┤   ┌─ Node B (ground) ────────────┤
  │ scanner → readings  │   │                                 │
  │              │      │   │  receive readings from A ───── |
  │ network.send(state)─┤──→│       │                        │
  │              │      │   │  state.mergeRemote("A", data)  │
  │ receive from B      │   │       │                        │
  │       │             │   │  trigger.tick(combined)        │
  │ state.mergeRemote   │   │       │                        │
  │       │             │   │  output.applyAction (local)    │
  │ display.render      │   │       │                        │
  └─────────────────────┤   │  display.render                │
                        │   └────────────────────────────────┘
                        └────────────────────────────────────
```

### Per-Node Roles

Each node defines its capabilities in `config/nodes/<id>.json`:

| Capability | What it does |
|---|---|
| `sensors` | Reads local peripherals, broadcasts `readings` |
| `bindings` | Reads redstone inputs, broadcasts `controls` |
| `triggers` | Evaluates conditions on combined state, fires actions |
| `display` | Renders dashboard to monitor/terminal |

A single node can have any combination. If a trigger's `target_node` matches
another node, an `exec` request is sent via modem instead of executing locally.

### P2P Tick Cycle

1. `network.pollAll()` — drain pending modem messages (non-blocking)
   - `state` messages → `state.mergeRemote(node_id, data)`
   - `exec` messages → `output.applyAction(action, true)`
   - `peripherals` messages → `state.updateNetwork(node_id, list)`
2. `discovery.scan()` — every 20 ticks, broadcast local peripheral list
3. Build combined readings from all remote + local sensors
4. Broadcast local sensor readings + controls
5. Evaluate triggers (JSON rules + code triggers from `triggers_custom.lua`)
6. Route actions: local → `output.applyAction()`, remote → `network.sendExec()`
7. Render display (custom `display_custom.lua` or built-in `display.render()`)

### Peripheral Discovery

Each P2P node scans its CC:T peripherals at runtime using `discovery.scan()`
(which calls `peripheral.getNames()` + `peripheral.getType()` + `peripheral.getMethods()`)
and broadcasts the list every 20 ticks as a `peripherals` message.

Received lists are stored in `state.network[node_id].peripherals`, making all
networked devices visible to every node for display or trigger logic.

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
  ├── src/network.lua       [P2P]
  │     ├── peripheral      (CC:T built-in)
  │     └── os.pullEvent    (CC:T built-in)
  ├── src/discovery.lua     [P2P]
  │     └── peripheral      (CC:T built-in)
  ├── config/display_custom.lua  [optional user script]
  ├── config/triggers_custom.lua [optional user script]
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
| New P2P node role | `src/network.lua` (new message type) + `dashboard.lua` (handler) |
| New trigger routing target | `config/nodes/<id>.json` (`target_node` field) — no code change |
| Custom display layout | `config/display_custom.lua` — user writes a Lua function |
| Custom trigger logic | `config/triggers_custom.lua` — user writes Lua check/fire/clear |
| Add runtime peripheral info | `src/discovery.lua` — user extends the scan function |
