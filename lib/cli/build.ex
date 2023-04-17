defmodule Dragon.Cli.Build do
  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print
  @shortdoc "Build a Dragon Project's content"

  def run(_optcfg, _opts, [target]), do: build(target)

  def run(optcfg, _, _), do: syntax(optcfg, "build {target} — No target specified")

  def build(target) do
    start = :os.system_time(:millisecond)

    stdout([:light_blue, :bright, "Starting Dragon CMS"])

    with {:ok, _} <- Dragon.startup(target),
         {:ok, dragon} <- Dragon.get(),
         {:ok, dragon} <- Dragon.Process.Prepare.prepare_build(dragon) do
      Dragon.Template.evaluate_all(dragon)
      Dragon.Scss.evaluate_all(dragon)
    else
      err ->
        IO.inspect(err)
    end

    info("\n#{(:os.system_time(:millisecond) - start) / 1000} seconds runtime\n")

    :ok
  end
end
