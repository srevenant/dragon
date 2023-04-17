defmodule Mix.Tasks.Build do
  use Mix.Task

  @moduledoc """
  Build from templates
  """

  @shortdoc "build from templates"

  @impl true
  def run([target]), do: Dragon.Cli.Build.build(target)
  def run(_), do: IO.puts("Syntax: mix build {target}")
end
