defmodule ExRabbit.Connection do
  @moduledoc """
  `GenServer` for keeping a `AMQP.Connection` to RabbitMQ.

  If the `AMQP.Connection` is lost or the supervision tree goes down, a new connection will be obtained.
  """

  require Logger
  use AMQP
  use GenServer

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

  @doc """
  Build the URL to RabbitMQ from the application's configuration.
  """
  @spec url() :: String.t
  def url() do
    host = Application.get_env(:ex_rabbit, :host)
    port = Application.get_env(:ex_rabbit, :port)
    user = Application.get_env(:ex_rabbit, :user)
    pass = Application.get_env(:ex_rabbit, :pass)
    heartbeat = Application.get_env(:ex_rabbit, :heartbeat)

    "amqp://#{user}:#{pass}@#{host}:#{port}?heartbeat=#{heartbeat}"
  end

  # Private

  # Opens a connection to RabbitMQ. If the connection is lost or the supervision tree fails it will reconnect. If it
  # cannot obtain a connection, it will retry.
  @spec connect() :: {:ok, Connection.t}
  defp connect() do
    case Connection.open(url()) do
      {:ok, conn} ->
        Process.link(conn.pid)
        {:ok, conn}

      {:error, reason} ->
        Logger.error("[#{__MODULE__}] Error attempting to connect to AMQP: #{inspect reason}. Waiting to reconnect...")

        Application.get_env(:ex_rabbit, :backoff)
          |> :timer.sleep

        connect()
    end
  end
end
