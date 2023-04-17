defmodule Dragon.MixProject do
  use Mix.Project

  def project do
    [
      app: :dragon,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: "Content Management System",
      # source_url
      # docs
      # package: package()
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      # test_coverage
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      escript: escript()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def aliases() do
    [
      c: ["compile"]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :mix, :eex],
      mod: {Dragon.Application, []}
    ]
  end

  def escript() do
    [main_module: Dragon.Cli]
  end

  defp deps do
    [
      {:earmark, "~> 1.4.34"},
      {:jason, "~> 1.0"},
      {:sass, "~> 3.6.4"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:rivet_utils, "~> 1.1.5", git: "https://github.com/srevenant/rivet-utils", branch: "master"},
      {:transmogrify, "~> 1.1.1"},
      {:yaml_elixir, "~> 2.8.0"}
    ]
  end
end
