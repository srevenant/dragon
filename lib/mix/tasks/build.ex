defmodule Mix.Tasks.Dragon.Build do
  @moduledoc false
  @shortdoc "Build from templates"

  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Cli.Build.build(target)
  def run(_), do: IO.puts("Syntax: mix build {target}")
end
