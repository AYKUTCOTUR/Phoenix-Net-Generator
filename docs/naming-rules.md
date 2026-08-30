# Semantic Naming Rules

This document describes current built-in naming behavior. These mappings are not intended to replace project-specific engineering conventions.

## Common Functions

| Selected Function | Semantic Core |
| --- | --- |
| `SCK` / `SCLK` | `SPI1_SCK` |
| `MISO` | `SPI1_MISO` |
| `MOSI` | `SPI1_MOSI` |
| `CS` / `SS` / `NSS` | `SPI1_CS` |
| `SDA` | `I2C1_SDA` |
| `SCL` | `I2C1_SCL` |
| `TXD` / `TX` | `UART1_TX` |
| `RXD` / `RX` | `UART1_RX` |
| `XTAL1` | `CLK_XTAL1` |
| `XTAL2` | `CLK_XTAL2` |
| `OSC_IN` | `CLK_OSC_IN` |
| `OSC_OUT` | `CLK_OSC_OUT` |
| `RESET` / `NRST` | `RESET` |
| `EN` / `ENABLE` | `EN` |

## Power

| Pin Function | Semantic Core |
| --- | --- |
| `GND`, `VSS`, `AGND`, `PGND`, `DGND` | `GND` |
| `VCC` | `PWR_VCC` |
| `VDD` | `PWR_VDD` |
| `AVCC` | `PWR_AVCC` |
| `VDDA` / `AVDD` | `PWR_ANALOG` |
| `DVDD` | `PWR_DIGITAL` |
| `VBAT` | `PWR_VBAT` |
| `AREF` | `ADC_AREF` |

## Device Families

The current source contains selected rules for:

- RS-232 transceivers
- CAN transceivers
- RS-485 transceivers
- MCU-family detection

Support is heuristic and based primarily on library reference strings and pin names.

## Prefix

When enabled:

```text
Final Name = Prefix + "_" + Semantic Core
```

Examples:

```text
U1 + SPI1_MISO = U1_SPI1_MISO
MAIN_MCU + CLK_XTAL1 = MAIN_MCU_CLK_XTAL1
```

## Custom Names

If a selected function does not match a built-in rule, Phoenix preserves the normalized user choice.

This allows project-specific functions such as:

```text
MOTOR_PWM
SENSOR_INT
BOOT_MODE
```

## Important Limitation

Interface numbers such as `SPI1`, `UART1`, and `I2C1` are currently rule-driven defaults. They do not yet infer the complete peripheral configuration from firmware, an MCU configuration file, or project connectivity.

Always review generated names before use.
