use Mix.Config

config :ex_rabbit,
  name: "local",
  host: "localhost",
  port: 5672,
  user: "guest",
  pass: "guest",
  backoff: 1000,
  heartbeat: 10,
  pool_size: 5,
  prefetch_count: 1,
  modules: []

config :logger, level: :debug
