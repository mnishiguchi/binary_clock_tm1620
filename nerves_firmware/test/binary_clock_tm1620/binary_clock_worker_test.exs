defmodule BinaryClockTm1620.BinaryClockWorkerTest do
  use ExUnit.Case, async: true

  alias BinaryClockTm1620.BinaryClockWorker

  @spi_bus "spidev0.0"
  @spi_opts [mode: 3, lsb_first: true]

  setup do
    FakeSPI.inject(FakeSPI.Success)
    :ok
  end

  describe "init/1" do
    test "opens the SPI bus and schedules the first tick" do
      {:ok, :fake_bus} = BinaryClockWorker.init(nil)
      assert_received {:fake_open, @spi_bus, @spi_opts}
      assert_received :tick
    end
  end

  describe "handle_info/2" do
    test "on :tick drives the display and returns {:noreply, state}" do
      {:ok, spi_handle} = BinaryClockWorker.init(nil)
      assert_received :tick

      {:noreply, ^spi_handle} = BinaryClockWorker.handle_info(:tick, spi_handle)
      assert_received {:fake_transfer, <<0b00000010>>}
    end
  end
end
