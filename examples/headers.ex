defmodule Examples.Headers do
  @behaviour ExRabbit

  def config() do
    []
  end

  def handler(_msg, _meta) do
    {:ok, []}
  end
end
