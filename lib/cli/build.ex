defmodule Dragon.Cli.Build do
  @moduledoc "Build a Dragon Project's content"

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: build(target)

  def run(optcfg, _, _), do: syntax(optcfg, "build {target} — No target specified")

  def build(target) do
    start = :os.system_time(:millisecond)

    stdout([:light_blue, :bright, "Starting Dragon CMS"])

    with {:ok, _} <- Dragon.startup(target),
         {:ok, dragon} <- Dragon.get(),
         {:ok, dragon} <- Dragon.Process.Prepare.prepare_build(dragon) do
      Dragon.Scss.Evaluate.all(dragon)
      # do Dragon Template last so prior things can be generated, allowing the
      # 'path' function to properly find things
      Dragon.Template.Evaluate.all(dragon)
    else
      err ->
        IO.inspect(err, label: "Error running dragon")
    end

    info("\n#{(:os.system_time(:millisecond) - start) / 1000} seconds runtime\n")

    :ok
  end
end
