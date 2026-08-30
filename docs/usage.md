# Usage

## 1. Analyze a Component

Enter a component designator, for example:

```text
U1
```

Click **Analyze**.

Phoenix reads the active schematic, locates the component, and lists its visible pins.

## 2. Review Multifunction Pins

A pin such as:

```text
(PCINT6/XTAL1/TOSC1)_PB6
```

is parsed into:

```text
PCINT6
XTAL1
TOSC1
PB6
```

Select the function that matches the actual design intent.

When a recognizable GPIO function is available, Phoenix generally prefers it as the conservative default rather than assuming an alternate peripheral function.

## 3. Configure the Prefix

Default:

```text
Add Prefix = enabled
Prefix = component designator
```

Examples:

```text
U1 + MISO → U1_SPI1_MISO
MAIN_MCU + MISO → MAIN_MCU_SPI1_MISO
No prefix + MISO → SPI1_MISO
```

## 4. Enable or Disable Pins

Click the `Use` column:

```text
YES ↔ NO
```

`NO` means the pin is excluded from generation.

The selected-row checkbox provides the same state for the active row.

## 5. Enter a Custom Function

The Function field is editable.

Example:

```text
MOTOR_PWM
```

with prefix `U1` becomes:

```text
U1_MOTOR_PWM
```

## 6. Configure Wire Margins

Enter non-negative integer values in mil:

```text
Before = 200
After  = 200
```

The label begins `Before` mil from the wire start.

Common wire length:

```text
Widest Generated Label + Before + After
```

## 7. Generate

Click **Generate Net Labels**.

Phoenix generates the enabled labels in columns of 15 entries.

The bank is deliberately not connected automatically to the source component. Review the generated names and move labels to the intended schematic connections manually.

## Important Electrical Note

Net Labels create electrical connectivity by name.

For example:

```text
U1_GND
```

and:

```text
GND
```

are different net names.

Use project naming conventions carefully, especially for global power rails. Prefixing every signal is not automatically correct for every schematic architecture.
