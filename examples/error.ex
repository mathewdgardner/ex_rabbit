defmodule Examples.Error do
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
        name: "error_topic_queue",
        options: [
          durable: true,
          arguments: [
            {"x-dead-letter-exchange", "dead-letter"},
          ]
        ]
      ],
      binding_options: [
        routing_key: "error_topic"
      ],
      consume_options: [],
      qos_options: []
    ]
  end

  def handler(_msg, _meta) do
    {:error, "Made up reason"}
  end
end
