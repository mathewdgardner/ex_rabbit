defmodule Examples.FullOptions do
  @behaviour ExRabbit

  def config() do
    [
      consumer_name: "my_name",
      parse_json: true,
      exchange: [
        type: :topic,
        name: "my_exchange",
        options: [
          passive: false,
          durable: false,
          auto_delete: false,
          internal: false,
          nowait: false,
          arguments: [
            {"alternate-exchange", "my_alt_exchange"}
          ]
        ]
      ],
      queue: [
        name: "my_queue",
        options: [
          passive: false,
          durable: false,
          exclusive: false,
          auto_delete: false,
          nowait: false,
          arguments: [
            {"x-dead-letter-exchange", "exchange"},
            {"x-dead-letter-routing-key", "key"},
            {"x-expires", "expires"},
            {"x-max-length", "length"},
            {"x-max-length-bytes", "bytes"},
            {"x-max-priority", "priority"},
            {"x-message-ttl", "ttl"}
          ]
        ]
      ],
      binding_options: [
        routing_key: "my_topic",
        arguments: []
      ],
      consume_options: [
        consumer_tag: "my_tag",
        no_local: false,
        no_ack: false,
        exclusive: false,
        nowait: false,
        arguments: []
      ],
      qos_options: [
        prefetch_size: 0,
        prefetch_count: 0,
        global: false
      ]
    ]
  end

  def handler(_msg, _meta) do
    {:ok, []}
  end
end
