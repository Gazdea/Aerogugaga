# Network Protocol

P2P communication uses the raw CC:T modem API (`modem.transmit` /
`modem_message` events). All nodes communicate on a shared channel.

## Configuration

Each node config specifies:

```json
{
  "network": {
    "modem_side": "back",
    "channel": 42
  }
}
```

## Ports / Channels

| Channel | Usage |
|---|---|
| `channel` | Data messages: state, announce, peripherals |
| `channel + 1` | Reply / exec messages |

Both channels are opened (`modem.open()`) by `network.init()`.

## Message Format

All messages are Lua tables sent via `modem.transmit(channel, channel+1, msg)`.

### `state`

Broadcast regularly (every tick) by nodes that have sensors or controls.

```lua
{
  type = "state",
  node_id = "airship-1",       -- sender identifier
  readings = { ... },          -- optional: sensor data table
  controls = { ... },          -- optional: { throttle, altitude_hold, yaw_target }
}
```

### `announce`

Sent once at startup to declare capabilities.

```lua
{
  type = "announce",
  node_id = "airship-1",
  caps = {
    sensors = true,
    outputs = true,
    display = true,
  },
}
```

### `peripherals`

Broadcast periodically (every 20 ticks) to advertise attached peripherals.

```lua
{
  type = "peripherals",
  node_id = "airship-1",
  list = {
    { name = "top",      type = "gyroscope",   methods = { "getAngles", ... } },
    { name = "back",     type = "modem",        methods = { "open", ... } },
    { name = "bottom",   type = "playerDetector", methods = { "getPlayersInRange", ... } },
  },
}
```

### `exec`

Sent when a trigger's `target_node` doesn't match the local node.

```lua
{
  type = "exec",
  target = "ground-station",   -- intended receiver
  source = "airship-1",        -- sender
  action = {
    type = "redstone",         -- "redstone" or "peripheral"
    side = "front",
    value = true,
  },
}
```

The target node checks `msg.target == node_id` and executes the action
via `output.applyAction()`.

## Data flow diagram

```
Sender node                          Receiver node
───────────                          ─────────────
discovery.scan() → peripherals ───→  state.updateNetwork(id, list)
scanner.scan()   → readings    ───→  state.mergeRemote(id, { readings })
control.tick()   → controls    ───→  state.mergeRemote(id, { controls })
                                     
trigger fires    → exec        ───→  output.applyAction(action)
```

## State shape on receiver

```lua
state.readings         -- combined from all remote + local
state.controls         -- combined from all remote + local
state.remote[id]       -- { readings, controls }
state.network[id]      -- { peripherals = { name, type }, last_seen = os.clock() }
```

## Sequence numbers and dedup

The current protocol does not use sequence numbers. If two state messages
arrive in the same tick, the later one overwrites the earlier (by design —
readings are sampled fresh each tick on the sender).

## Node discovery

There is no active node discovery beyond `announce` and `peripherals`
messages. A node is considered "present" if `state.network[id].last_seen`
is recent. Stale entries (not updated for >30s) can be pruned by the
custom display or a code trigger.
