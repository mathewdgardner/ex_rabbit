use Mix.Config

config :ex_rabbit,
  name: "local",
  host: "localhost",
  port: 5672,
  user: "guest",
  pass: "guest",
  backoff: 10,
  heartbeat: 10,
  pool_size: 5,
  prefetch_count: 1,
  modules: [Examples.Topic, Examples.Error]

config :logger, level: :debug, backends: [] # Remove the empty `backends` parameter to see log messages during testing
