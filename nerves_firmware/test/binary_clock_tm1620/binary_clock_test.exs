defmodule BinaryClockTm1620.BinaryClockTest do
  use ExUnit.Case, async: true
  alias BinaryClockTm1620.BinaryClock

  @spi_bus "spidev0.0"
  @spi_opts [mode: 3, lsb_first: true]
  @brightness_base 0x88

  describe "encode_time/3" do
    for {h, m, s, expected} <- [
          {12, 34, 56, <<0xC0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0>>},
          {0, 0, 0, <<0xC0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>},
          {23, 59, 59, <<0xC0, 2, 0, 3, 0, 5, 0, 9, 0, 5, 0, 9, 0>>}
        ] do
      test "encode_time(#{h},#{m},#{s}) → #{inspect(expected)}" do
        assert BinaryClock.encode_time(unquote(h), unquote(m), unquote(s)) ==
                 unquote(expected)
      end
    end
  end

  describe "open/0" do
    test "success path" do
      FakeSPI.inject(FakeSPI.Success)

      assert {:ok, spi_handle} = BinaryClock.open()
      assert_received {:fake_open, @spi_bus, @spi_opts}
      refute_received {:fake_transfer, _}

      assert spi_handle == :fake_bus
    end

    test "error path" do
      FakeSPI.inject(FakeSPI.OpenFailure)

      assert {:error, :busy} = BinaryClock.open()
      refute_received {:fake_open, _, _}
    end
  end

  describe "show/5" do
    test "sends exactly four transfers on the happy path" do
      FakeSPI.inject(FakeSPI.Success)

      {:ok, spi_handle} = BinaryClock.open()
      assert_received {:fake_open, @spi_bus, @spi_opts}

      assert :ok = BinaryClock.show(spi_handle, 1, 2, 3)

      display_mode = <<0b00000010>>
      write_cmd = <<0x40>>
      payload = BinaryClock.encode_time(1, 2, 3)
      bright_cmd = <<@brightness_base>>

      assert_received {:fake_transfer, ^display_mode}
      assert_received {:fake_transfer, ^write_cmd}
      assert_received {:fake_transfer, ^payload}
      assert_received {:fake_transfer, ^bright_cmd}
      refute_received {:fake_transfer, _}
    end

    test "respects custom brightness level" do
      FakeSPI.inject(FakeSPI.Success)

      {:ok, spi_handle} = BinaryClock.open()
      assert_received {:fake_open, @spi_bus, @spi_opts}

      assert :ok = BinaryClock.show(spi_handle, 4, 5, 6, 7)
      expected_brightness = <<@brightness_base + 7>>
      assert_received {:fake_transfer, ^expected_brightness}
    end

    test "bails out on transfer failure after the first command" do
      FakeSPI.inject(FakeSPI.TransferFailure)

      {:ok, spi_handle} = BinaryClock.open()
      assert_received {:fake_open, @spi_bus, @spi_opts}

      assert {:error, :hw} = BinaryClock.show(spi_handle, 7, 8, 9)
      assert_received {:fake_transfer, <<0b00000010>>}
      refute_received {:fake_transfer, _}
    end
  end
end
