defmodule Dragon.MixProject do
  use Mix.Project

  def project do
    [
      app: :dragon,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def aliases() do
    [
      build: ["dragon.build"],
      copy: ["dragon.copy"],
      render: ["dragon.render"],
      plugins: ["dragon.plugins"],
      debug: ["dragon.debug"],
      c: ["compile"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.0"},
      {:sass, "~> 3.6.4"},
      {:earmark, "1.4.34"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:transmogrify, "~> 1.1.1"},
      {:yaml_elixir, "~> 2.8.0"},
      {:jason, "~> 1.0"}
    ]
  end
end
