defmodule ExRabbit.Application do
  use Application
  use Supervisor
  require Logger

  def start(_type, _args) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    children = [
      worker(ExRabbit.Connection, []),
      worker(ExRabbit.Consumer.WorkerSupervisor, []),
      supervisor(Registry, [:unique, :ex_rabbit_registry]),
      supervisor(ExRabbit.Consumer, [Application.get_env(:ex_rabbit, :modules)]),
      supervisor(ExRabbit.Publisher, [Application.get_env(:ex_rabbit, :pool_size)])
    ]

    supervise(children, strategy: :one_for_all)
  end

  def via(name), do: {:via, Registry, {:ex_rabbit_registry, name}}
end
