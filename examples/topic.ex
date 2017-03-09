defmodule Examples.Topic do
  @behaviour ExRabbit

  def config() do
    [
      consumer_name: "topic_name",
      parse_json: true,
      exchange: [
        type: :topic,
        name: "topic_exchange",
        options: [
          durable: true,
          arguments: []
        ]
      ],
      queue: [
        name: "topic_queue",
        options: [
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", "dead-letter"},
          ]
        ]
      ],
      binding_options: [
        routing_key: "the_topic"
      ],
      consume_options: [],
      qos_options: []
    ]
  end

  def handler(_msg, _meta) do
    {:ok, []}
  end
end
