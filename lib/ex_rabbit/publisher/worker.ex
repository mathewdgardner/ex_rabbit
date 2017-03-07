defmodule ExRabbit.Publisher.Worker do
  use GenServer
  require Logger

  def start_link(num) do
    GenServer.start_link(__MODULE__, [], name: :"#{__MODULE__}_#{num}")
  end

  def init([]) do
    open_channel()
  end

  # Callbacks

  def handle_call(:get, _from, channel) do
    {:reply, channel, channel}
  end

  # Private

  defp open_channel() do
    connection = GenServer.call(ExRabbit.Connection, :get)

    case AMQP.Channel.open(connection) do
      {:ok, channel} ->
        {:ok, channel}
      {:error, reason} ->
        Logger.error("[#{__MODULE__}] Error opening a channel: #{reason}. Waiting to try again...")

        :timer.sleep(Application.get_env(:ex_rabbit, :backoff))
        open_channel()
    end
  end
end
