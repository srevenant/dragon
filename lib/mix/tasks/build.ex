defmodule Mix.Tasks.Build do
  use Mix.Task

  @moduledoc """
  Build from templates
  """

  @shortdoc "build from templates"

  @impl true
  def run([target]) do
    IO.puts(IO.ANSI.format([:light_blue, :bright, "Starting Dragon CMS"]))

    with {:ok, _} <- Dragon.startup(target),
         {:ok, dragon} <- Dragon.get(),
         {:ok, dragon} <- Dragon.Process.Prepare.prepare_build(dragon) do
      Dragon.Template.evaluate_all(dragon)
      Dragon.Scss.evaluate_all(dragon)
    else
      err ->
        IO.inspect(err)
    end
  end

  def run(_) do
    IO.puts("Syntax: mix build {target}")
  end
end
