defmodule Mix.Tasks.Dragon.Serve do
  @shortdoc "Run a development server for a Dragon Project"
  @moduledoc @shortdoc
  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Cli.Serve.serve(target)
  def run(_), do: IO.puts("Syntax: mix dragon.serve {target}")
end
