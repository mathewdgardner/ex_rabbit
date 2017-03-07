defmodule ExRabbit.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_rabbit,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     deps: deps()]
  end

  def application() do
    [
      applications: apps(),
      mod: {ExRabbit.Application, []}
    ]
  end

  defp apps() do
    apps = [
      :logger,
      :amqp,
      :poison
    ]

    cond do
      Mix.env === :test -> apps ++ [:httpoison]
      true              -> apps
    end
  end

  defp deps() do
    [
      {:amqp, "~> 0.2.0-pre.2"},
      {:poison, "~> 2.2"},

      # Development
      {:espec, "~> 1.3.0", only: :test},
      {:httpoison, "~> 0.10.0", only: :test},
      {:mock, "~> 0.2.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "examples", "spec/helpers"]
  defp elixirc_paths(_), do: ["lib"]
end