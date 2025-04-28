# lib/binary_clock_tm1620/binary_clock_worker.ex
defmodule BinaryClockTm1620.BinaryClockWorker do
  @moduledoc """
  A GenServer that ticks every second and pushes the current time to the display.
  """

  use GenServer
  alias BinaryClockTm1620.BinaryClock

  @tick_interval_ms 1_000

  # Public API

  @doc """
  Starts the clock worker. The worker opens the SPI bus once,
  then sends itself a `:tick` every second.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init(_) do
    # Open SPI once at startup
    {:ok, spi_handle} = BinaryClock.open()

    # Schedule the first tick immediately
    send(self(), :tick)

    {:ok, spi_handle}
  end

  @impl true
  def handle_info(:tick, spi_handle) do
    # Fetch the current local time
    {_, {hour, min, sec}} = :calendar.local_time()

    # Push to display (ignore errors here)
    _ = BinaryClock.show(spi_handle, hour, min, sec)

    # Schedule next tick
    Process.send_after(self(), :tick, @tick_interval_ms)

    {:noreply, spi_handle}
  end
end
