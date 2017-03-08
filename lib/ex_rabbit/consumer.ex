defmodule ExRabbit.Consumer do
  @moduledoc """
  `Supervisor` that manages each consumer.

  Supervises `ExRabbit.Consumer.Consumer` for each given module.
  """

  use Supervisor
  require Logger

  def start_link(modules) do
    Supervisor.start_link(__MODULE__, modules, name: __MODULE__)
  end

  def init(modules) do
    children = Enum.map(modules, fn(module) -> worker(ExRabbit.Consumer.Consumer, [module], id: module) end)

    supervise(children, strategy: :one_for_one)
  end
end
