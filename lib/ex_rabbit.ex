defmodule ExRabbit do
  @callback config() :: {:ok, list()} | {:error, String.t}
  @callback handler(Map, Map) :: {:ok, list()} | {:error, String.t}

  @spec publish(String.t, String.t, map() | String.t, keyword()) :: :ok
  def publish(exchange, routing_key, payload, options \\ [])
  def publish(exchange, routing_key, payload, options), do: ExRabbit.Publisher.publish(exchange, routing_key, payload, options)
end
