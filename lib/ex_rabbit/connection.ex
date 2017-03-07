defmodule ExRabbit.Connection do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    connect()
  end

  # Callbacks

  def handle_call(:get, _from, connection) do
    {:reply, connection, connection}
  end

  def url() do
    host = Application.get_env(:ex_rabbit, :host)
    port = Application.get_env(:ex_rabbit, :port)
    user = Application.get_env(:ex_rabbit, :user)
    pass = Application.get_env(:ex_rabbit, :pass)
    heartbeat = Application.get_env(:ex_rabbit, :heartbeat)

    "amqp://#{user}:#{pass}@#{host}:#{port}?heartbeat=#{heartbeat}"
  end

  # Private

  defp connect() do
    case AMQP.Connection.open(url()) do
      {:ok, conn} ->
        Process.link(conn.pid)
        {:ok, conn}

      {:error, reason} ->
        Logger.error("[ExRabbit.Connection] Error attepmting to connect to AMQP: #{reason}. Waiting to reconnect...")

        Application.get_env(:ex_rabbit, :backoff)
          |> :timer.sleep

        connect()
    end
  end
end
