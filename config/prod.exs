use Mix.Config

config :ex_rabbit,
  name: "local",
  host: "localhost",
  port: 5672,
  user: "guest",
  pass: "guest",
  heartbeat: 10,
  backoff: 1000,
  prefetch_count: 4,
  rabbits: []

config :logger, level: :error
