defmodule FakeSPI do
  @moduledoc """
  Test helper that swaps out `Circuits.SPI` for fake implementations.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc "Override `Circuits.SPI` with `variant` for the duration of the test."
  def inject(variant) do
    Resolve.inject(Circuits.SPI, variant)
    on_exit(fn -> Resolve.revert(Circuits.SPI) end)
    :ok
  end

  defmodule Success do
    @moduledoc "SPI stub: always opens, echoes back transfers."

    @doc "Simulate `SPI.open/2`."
    def open(bus, opts) do
      send(self(), {:fake_open, bus, opts})
      {:ok, :fake_bus}
    end

    @doc "Simulate `SPI.transfer/2` by echoing the payload."
    def transfer(:fake_bus, data) do
      bin = :erlang.iolist_to_binary(data)
      send(self(), {:fake_transfer, bin})
      {:ok, bin}
    end
  end

  defmodule OpenFailure do
    @moduledoc "SPI stub: always errors on open."

    @doc "Simulate `SPI.open/2` error."
    def open(_bus, _opts), do: {:error, :busy}

    @doc "Simulate `SPI.transfer/2` error."
    def transfer(_, _), do: {:error, :busy}
  end

  defmodule TransferFailure do
    @moduledoc "SPI stub: only the first transfer succeeds, then fails."

    @doc "Open via the Success stub."
    def open(bus, opts), do: Success.open(bus, opts)

    @doc "Let the display‐mode command pass; error on others."
    def transfer(:fake_bus, <<0b00000010>> = cmd), do: Success.transfer(:fake_bus, cmd)
    def transfer(_, _), do: {:error, :hw}
  end
end
