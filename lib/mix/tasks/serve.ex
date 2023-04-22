defmodule Mix.Tasks.Dragon.Serve do
  @moduledoc false
  @shortdoc "Run a development server for a Dragon Project"
  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Serve.start(target)
  def run(_), do: IO.puts("Syntax: mix dragon.serve {target}")
end
