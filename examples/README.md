# Examples

This directory is reserved for public, redistributable examples.

No proprietary schematic library or customer design files are included in the repository.

## Example Pin Parsing

### AVR-style multifunction pin

Input:

```text
(PCINT6/XTAL1/TOSC1)_PB6
```

Expected options:

```text
PCINT6
XTAL1
TOSC1
PB6
```

### SPI-capable pin

Input:

```text
(PCINT4/MISO)_PB4
```

Expected options:

```text
PCINT4
MISO
PB4
```

Selecting `MISO` with prefix `U1` should preview:

```text
U1_SPI1_MISO
```

### Custom function

Select or type:

```text
MOTOR_PWM
```

with prefix `MAIN_MCU`:

```text
MAIN_MCU_MOTOR_PWM
```

Future releases may include complete example `.PrjScr` and schematic projects when redistribution-safe sample assets are available.
