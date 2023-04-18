defmodule Mix.Tasks.Dragon.New do
  @shortdoc "Create a new Dragon Project"
  @moduledoc @shortdoc
  use Mix.Task

  @impl true
  def run([target]), do: Dragon.Cli.New.new(target)
  def run(_), do: IO.puts("Syntax: mix new {target}")
end
