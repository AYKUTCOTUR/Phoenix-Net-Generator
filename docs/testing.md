# Test Checklist

Use this checklist before publishing a release.

## UI

- [ ] Form opens without script errors.
- [ ] Component designator field is editable.
- [ ] Analyze button finds a valid component.
- [ ] Part name and visible-pin count are displayed.
- [ ] Grid is populated.
- [ ] Function selector updates with row selection.
- [ ] Custom function text is accepted.
- [ ] Prefix enable/disable updates preview.
- [ ] Custom prefix updates preview.
- [ ] `Use` column toggles YES / NO.
- [ ] Selected-row Generate checkbox remains synchronized.

## Parser

Test representative formats:

```text
(PCINT6/XTAL1/TOSC1)_PB6
PB5(SCK/PCINT5)
PC4_(ADC4/SDA/PCINT12)
GPIO13/HSPI_MOSI
PA9/USART1_TX/TIM1_CH2
SCL/SCK
\R\E\S\E\T
```

## Generation

- [ ] Pins marked NO are skipped.
- [ ] 15 generated entries are placed per column.
- [ ] Row pitch is 200 mil.
- [ ] Column progression is correct.
- [ ] Before margin is applied.
- [ ] After margin contributes to common line length.
- [ ] All generated wires have equal length.
- [ ] Net Label text matches preview.
- [ ] Existing conflicting label behavior is predictable.
- [ ] Undo / version-control recovery is available during testing.

## Regression

- [ ] No direct UI event-handler invocation was introduced.
- [ ] No private project data or credentials are present in source or docs.
