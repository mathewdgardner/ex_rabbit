defmodule ExRabbit.Consumer.WorkerSupervisor do
  use Supervisor
  require Logger

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(ExRabbit.Consumer.Worker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def handle_message(payload, meta, consumer_pid) do
    Logger.debug("[#{__MODULE__}] Handling message.")

    {:ok, pid} = Supervisor.start_child(__MODULE__, [payload, meta, consumer_pid])
    GenServer.cast(pid, :handle_message)
  end
end
