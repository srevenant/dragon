defmodule Dragon.MixProject do
  use Mix.Project

  def project do
    [
      app: :dragon,
      version: "1.3.0",
      elixir: "~> 1.14",
      description:
        "Content Management System for static sites, like Jekyll but with elixir/eex rather than liquid templates",
      source_url: "https://github.com/srevenant/dragon",
      docs: [main: "Dragon", source_ref: "master"],
      package: package(),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      # test_coverage
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
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

  defp deps do
    [
      {:bandit, "~> 1.5.7"},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4.47"},
      {:ex_doc, ">= 0.34.0", only: :dev, runtime: false},
      {:file_system, "~> 1.0.1"},
      {:httpoison, "~> 2.2.1"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.16.1"},
      {:rivet_utils, "~> 2.0.4"},
      {:sass, "~> 3.6.4"},
      # not pretty but required until sass adjusts its dependency
      {:elixir_make, "~> 0.8.0", override: true},
      {:transmogrify, "~> 2.0.2"},
      {:yaml_elixir, "~> 2.11.0"}
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
