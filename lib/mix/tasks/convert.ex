defmodule Mix.Tasks.Dragon.Convert do
  @moduledoc false
  @shortdoc "Convert a Jekyll Project to a Dragon Project"
  use Mix.Task

  @impl true
  def run([_target]), do: IO.puts("Coming soon")
  def run(_), do: IO.puts("Syntax: mix dragon.convert {target}")
end
