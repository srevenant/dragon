defmodule Dragon.MixProject do
  use Mix.Project

  def project do
    [
      app: :dragon,
      version: "1.0.0",
      elixir: "~> 1.14",
      description: "Content Management System",
      source_url: "https://github.com/srevenant/dragon",
      docs: [main: "Dragon", source_ref: "master"],
      package: package(),
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
      {:rivet_utils, "~> 1.1.5"},
      {:transmogrify, "~> 1.1.1"},
      {:yaml_elixir, "~> 2.8.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/srevenant/dragon"},
      source_url: "https://github.com/srevenant/dragon"
    ]
  end
end
