# Configuration

All config files are JSON, stored in `config/`. Missing files fall back to
sensible defaults — no config is required to start.

## settings.json

```json
{
  "update_interval": 0.05,
  "monitor_side": null,
  "locale": "en",
  "debug": false
}
```

| Field | Type | Default | Description |
|---|---|---|---|
| `update_interval` | number | 0.05 | Seconds between ticks |
| `monitor_side` | string\|null | null | Monitor side (`"left"`, `"right"`, etc.) or null for term |
| `locale` | string | "en" | Language code (`"en"`, `"ru"`) |
| `debug` | boolean | false | Print startup diagnostics |

## bindings.json

Maps redstone input sides to control actions.

```json
{
  "bindings": {
    "front": { "action": "throttle", "axis": "z" },
    "left":  { "action": "throttle", "axis": "x" },
    "top":   { "action": "altitude_hold" },
    "back":  { "action": "yaw", "speed": 5 },
    "bottom": { "action": "stop" }
  }
}
```

### Action types

#### throttle
Set thrust along an axis.
```
{ "action": "throttle", "axis": "x"|"y"|"z", "invert"? : true|false }
```

#### yaw
Set yaw rotation.
```
{ "action": "yaw", "speed": 5, "invert"? : true|false }
```

#### altitude_hold
Toggle or hold altitude lock.
```
{ "action": "altitude_hold", "edge"? : "rising" }
```
Without `edge`: direct (redstone ON = hold active).
With `edge: "rising"`: toggles on each rising edge.

#### stop
Emergency stop — zeroes all thrust and yaw.
```
{ "action": "stop" }
```

### Common binding fields

| Field | Type | Description |
|---|---|---|
| `invert` | boolean | Invert redstone signal (ON → OFF, OFF → ON) |
| `edge` | string | `"rising"` for edge-triggered (toggle) instead of level-triggered |

## sensors.json

Maps velocity sensor names to axes.

```json
{
  "velocity": {
    "velocity_sensor_1": "x",
    "velocity_sensor_2": "y",
    "velocity_sensor_3": "z"
  }
}
```

The axis mapping determines which velocity component is read from each sensor.
If a sensor is misconfigured or disconnected, that axis reads 0.

## triggers.json

Rules that evaluate sensor readings and produce redstone/peripheral outputs.

```json
{
  "triggers": [
    {
      "id": "pitch_warning",
      "enabled": true,
      "condition": {
        "source": "angles.pitch",
        "operator": ">",
        "threshold": 10
      },
      "hysteresis": 2.0,
      "action": {
        "type": "redstone",
        "side": "bottom",
        "value": true
      }
    }
  ]
}
```

### Trigger fields

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier for state tracking |
| `enabled` | boolean | no | Set `false` to disable (default: true) |
| `condition` | object | yes | The trigger condition |
| `hysteresis` | number | no | Deadband to prevent rapid toggling (default: 0) |
| `debounce` | number | no | Consecutive ticks needed before firing (default: 1) |
| `action` | object | yes | What to do when trigger fires |

### condition.source

Dot-separated path into the readings table.

| Source | Data | Range |
|---|---|---|
| `angles.pitch` | Pitch angle | degrees |
| `angles.yaw` | Yaw angle | degrees |
| `angles.roll` | Roll angle | degrees |
| `altitude.height` | Height | meters |
| `altitude.pressure` | Air pressure | kPa |
| `velocity.x` | Velocity X | m/s |
| `velocity.y` | Velocity Y | m/s |
| `velocity.z` | Velocity Z | m/s |
| `velocity_magnitude` | Speed | m/s |
| `rel_angle` | Navigation angle | degrees |

### condition.operator

| Operator | Fires when |
|---|---|
| `>` | value > threshold |
| `<` | value < threshold |
| `>=` | value >= threshold |
| `<=` | value <= threshold |
| `==` | abs(value - threshold) < 0.001 |

### Hysteresis

Prevents rapid on/off toggling when a value oscillates around the threshold.

- When **inactive**: fires when `value > threshold` (normal)
- When **active**: stays active until `value <= (threshold - hysteresis)`

### Action types

#### redstone
```json
{ "type": "redstone", "side": "bottom", "value": true }
```

#### peripheral
```json
{ "type": "peripheral", "side": "top", "method": "setSpeed", "value": true }
```
