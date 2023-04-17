defmodule Dragon.MixProject do
  use Mix.Project

  def project do
    [
      app: :dragon,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      aliases: aliases()
    ]
  end

  def aliases() do
    [
      c: ["compile"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def escript() do
    [main_module: Dragon.Cli]
  end

  defp deps do
    [
      {:earmark, "1.4.34"},
      {:jason, "~> 1.0"},
      {:sass, "~> 3.6.4"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:rivet, "~> 1.0.3"},
      {:timex, "~> 3.0"},
      {:transmogrify, "~> 1.1.1"},
      {:yaml_elixir, "~> 2.8.0"}
    ]
  end
end
