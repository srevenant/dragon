defmodule Mix.Tasks.Dragon.Convert do
  @shortdoc "Convert a Jekyll Project to a Dragon Project"
  @moduledoc @shortdoc
  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Cli.Convert.convert(target)
  def run(_), do: IO.puts("Syntax: mix dragon.convert {target}")
end
