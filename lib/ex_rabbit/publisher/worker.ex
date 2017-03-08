defmodule ExRabbit.Publisher.Worker do
  @moduledoc """
  `GenServer` used to hold a channel.

  If the `AMQP.Channel` is borked or the supervision tree fails, a new channel will be obtained.
  """

  use GenServer
  require Logger

  def start_link(num) do
    GenServer.start_link(__MODULE__, [], name: ExRabbit.Application.via({__MODULE__, num}))
  end

  def init([]) do
    open_channel()
  end

  # Callbacks

  def handle_call(:get, _from, channel) do
    {:reply, channel, channel}
  end

  # Private

  # Calls for a connection to RabbitMQ, then opens a channel on the connection. If a channel fails to open, it will
  # retry.
  @spec open_channel() :: {:ok, AMQP.Channel.t}
  defp open_channel() do
    connection = GenServer.call(ExRabbit.Connection, :get)

    case AMQP.Channel.open(connection) do
      {:ok, channel} ->
        {:ok, channel}
      {:error, reason} ->
        Logger.error("[#{__MODULE__}] Error opening a channel: #{inspect reason}. Waiting to try again...")

        :timer.sleep(Application.get_env(:ex_rabbit, :backoff))
        open_channel()
    end
  end
end
