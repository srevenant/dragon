defmodule Mix.Tasks.Dragon.Build do
  @shortdoc "Build from templates"
  @moduledoc @shortdoc

  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Cli.Build.build(target)
  def run(_), do: IO.puts("Syntax: mix build {target}")
end
