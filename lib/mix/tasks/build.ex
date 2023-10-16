defmodule Mix.Tasks.Dragon.Build do
  @moduledoc false
  @shortdoc "Build from templates"

  use Mix.Task
  use Dragon.Context

  @impl true
  def run([target]), do: build(target)
  def run(_), do: IO.puts("Syntax: mix build {target}")

  def build(target) do
    start = :os.system_time(:millisecond)

    {:ok, _} = Application.ensure_all_started(:dragon)

    with {:ok, _} <- Dragon.Slayer.build(:all, target) do
      info("\n#{(:os.system_time(:millisecond) - start) / 1000} seconds runtime\n")
    else
      {:error, reason} ->
        die(reason)
    end
  end
end
