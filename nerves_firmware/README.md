# binary_clock_tm1620

A Nerves firmware app that drives a TM1620-based BCD clock display over SPI
(6 digits, 8 segments).

## Prerequisites

- [Nerves](https://hexdocs.pm/nerves/getting-started.html)
- TM1620 LED module on your board’s SPI bus
- SSH key in `config/target.exs` for firmware updates

## Build & Deploy

```bash
mix deps.get
export MIX_TARGET=<your_target>  # e.g. rpi3
mix firmware       # builds
mix firmware.burn  # or mix upload
```

## Usage

The built‐in GenServer (`BinaryClockWorker`) opens SPI at boot and updates every second.  
To drive it manually in IEx:

```elixir
alias BinaryClockTm1620.BinaryClock

{:ok, spi} = BinaryClock.open()
:ok = BinaryClock.show(spi, 12, 34, 56, 3)      # hh:mm:ss at brightness 3
payload = BinaryClock.encode_time(7,8,9)
bright  = BinaryClock.brightness_cmd(5)
```

## Tests

All SPI calls are faked for host tests:

```bash
MIX_TARGET=host mix test
```
