defmodule ExRabbit.Consumer.Worker do
  @moduledoc """
    `GenServer` that is spawned for message consumption.

    It will call its given consumer module's callbacks `config/0` and
    `handler/2`. `config/0` is called on initializaion when a new message is being consumed and `handler/2` is called to
    handle the message. If an `{:ok, result}` tuple is returned, the message will be acknowledged. Otherwise, it will be
    rejected and placed back into the queue (unless the option to not requeue is set).
  """

  use GenServer
  require Logger

  def start_link(payload, meta, consumer_pid) do
    module = Process.info(consumer_pid) |> Keyword.get(:registered_name)
    state = %{
      module: module,
      payload: payload,
      meta: meta,
      consumer_pid: consumer_pid
    }
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(%{consumer_pid: pid} = state) do
    Process.link(pid)
    {:ok, state}
  end

  # Callbacks

  def handle_cast(:handle_message, %{module: module, payload: payload, meta: meta} = state) do
    Logger.debug("[#{__MODULE__}] Received payload for module [#{module}].")

    config = module.config()

    {:ok, msg} = case Keyword.get(config, :parse_json, true) do
      true -> Poison.decode(payload)
      false -> {:ok, payload}
    end

    case module.handler(msg, meta) do
      {:ok, result}    -> {:stop, :normal, Map.merge(state, %{result: result})}
      {:error, reason} -> {:stop, :normal, Map.merge(state, %{error: reason})}
    end
  end

  def terminate(:normal, %{consumer_pid: pid, result: _result} = state) do
    Logger.debug("[#{__MODULE__}] Terminating with message acknowledgement.")

    GenServer.cast(pid, {:ack, state})
  end

  def terminate(:normal, %{consumer_pid: pid, error: _reason} = state) do
    Logger.debug("[#{__MODULE__}] Terminating with message rejection.")

    GenServer.cast(pid, {:reject, state})
  end
end
