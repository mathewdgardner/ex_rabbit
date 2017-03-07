defmodule Helpers.Amqp do
  @vhost  "%2f"

  def setup! do
    body = %{
      exchanges: [],
      bindings: [],
      queues: []
    }
    |> Poison.encode!

    HTTPoison.post!("#{url()}/api/definitions", body)
  end

  def get_messages!(queue, count \\ 10) do
    body = %{count: count, requeue: true, encoding: "auto", truncate: 50000}
      |> Poison.encode!

    HTTPoison.post!("#{url()}/api/queues/#{@vhost}/#{queue}/get", body).body
      |> Poison.decode!
  end

  def purge!(queue), do: HTTPoison.delete!("#{url()}/api/queues/#{@vhost}/#{queue}/contents")

  def purge_all!, do: HTTPoison.get!("#{url()}/api/queues").body
    |> Poison.decode!
    |> Enum.map(fn(queue) -> queue["name"] end)
    |> Enum.map(fn(queue) -> purge!(queue) end)

  def get_exchange!(exchange), do: HTTPoison.get!("#{url()}/api/exchanges/#{@vhost}/#{exchange}").body
    |> Poison.decode!

  def get_queue!(queue), do: HTTPoison.get!("#{url()}/api/queues/#{@vhost}/#{queue}").body
    |> Poison.decode!

  def get_bindings!(exchange), do: HTTPoison.get!("#{url()}/api/exchanges/#{@vhost}/#{exchange}/bindings/source").body
    |> Poison.decode!

  def publish!(exchange, routing_key, message) do
    payload = %{
      properties: %{},
      routing_key: routing_key,
      payload: Poison.encode!(message),
      payload_encoding: "string"
    }
    |> Poison.encode!

    HTTPoison.post!("#{url()}/api/exchanges/#{@vhost}/#{exchange}/publish", payload)
  end

  defp url() do
    host = Application.get_env(:ex_rabbit, :host)
    port = Application.get_env(:ex_rabbit, :port)
    user = Application.get_env(:ex_rabbit, :user)
    pass = Application.get_env(:ex_rabbit, :pass)

    "http://#{user}:#{pass}@#{host}:1#{port}"
  end
end
