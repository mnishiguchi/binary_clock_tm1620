defmodule BinaryClockTm1620.BinaryClock do
  @moduledoc """
  Control a TM1620‐based BCD clock over SPI in “6 digits, 8 segments” mode.

  Provides:

    1. Opening the SPI bus
    2. Encoding hours, minutes, and seconds into a single BCD payload
    3. Sending the four‐step SPI sequence:
       - display mode
       - write‐data mode
       - time payload
       - brightness setting
    4. Adjusting brightness (0 = dimmest through 7 = brightest)

  ## Examples

      iex> {:ok, spi} = BinaryClockTm1620.BinaryClock.open()
      iex> BinaryClockTm1620.BinaryClock.encode_time(12, 34, 56)
      <<0xC0,1,0,2,0,3,0,4,0,5,0,6,0>>
      iex> BinaryClockTm1620.BinaryClock.brightness_cmd(3)
      <<0x8B>>
      iex> BinaryClockTm1620.BinaryClock.show(spi, 12, 34, 56, 3)
      :ok
  """

  @spi_bus "spidev0.0"
  @spi_opts [mode: 3, lsb_first: true]
  @display_cmd <<0b0000_0010>>
  @write_cmd <<0x40>>
  @base_addr 0xC0
  @brightness_base 0x88

  use Resolve
  @spi_mod Circuits.SPI
  defp determine_spi_mod, do: Resolve.resolve(@spi_mod)

  @doc """
  Opens the SPI bus.

  Returns `{:ok, spi_handle}` on success, or `{:error, reason}` otherwise.
  """
  @spec open() :: {:ok, term()} | {:error, term()}
  def open do
    spi_mod = determine_spi_mod()
    spi_mod.open(@spi_bus, @spi_opts)
  end

  @doc """
  Displays `hours:minutes:seconds` on the LED grid.

  - `hours` is 0–23, `minutes` and `seconds` are 0–59.
  - `brightness` is 0 (dimmest) through 7 (brightest).

  Returns `:ok`, or `{:error, reason}` if any transfer fails.
  """
  @spec show(term(), 0..23, 0..59, 0..59, 0..7) :: :ok | {:error, term()}
  def show(spi_handle, hours, mins, secs, brightness \\ 0)
      when hours in 0..23 and mins in 0..59 and secs in 0..59 and brightness in 0..7 do
    spi_mod = determine_spi_mod()

    with {:ok, _} <- spi_mod.transfer(spi_handle, @display_cmd),
         {:ok, _} <- spi_mod.transfer(spi_handle, @write_cmd),
         {:ok, _} <- spi_mod.transfer(spi_handle, encode_time(hours, mins, secs)),
         {:ok, _} <- spi_mod.transfer(spi_handle, brightness_cmd(brightness)) do
      :ok
    end
  end

  @doc """
  Builds the 13-byte BCD payload for hours, minutes and seconds:

    1. `0xC0`           – base address (digit 0)
    2. `H_tens`,  0     – hour’s tens digit
    3. `H_units`, 0     – hour’s units digit
    4. `M_tens`,  0     – minute’s tens digit
    5. `M_units`, 0     – minute’s units digit
    6. `S_tens`,  0     – second’s tens digit
    7. `S_units`, 0     – second’s units digit

  ## Example

      iex> BinaryClockTm1620.BinaryClock.encode_time(12, 34, 56)
      <<0xC0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0>>
  """
  @spec encode_time(0..23, 0..59, 0..59) :: binary()
  def encode_time(h, m, s) do
    <<@base_addr, div(h, 10)::8, 0::8, rem(h, 10)::8, 0::8, div(m, 10)::8, 0::8, rem(m, 10)::8,
      0::8, div(s, 10)::8, 0::8, rem(s, 10)::8, 0::8>>
  end

  defp brightness_cmd(level) when level in 0..7 do
    <<@brightness_base + level>>
  end
end
