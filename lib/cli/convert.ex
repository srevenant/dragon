defmodule Dragon.Cli.Convert do
  @moduledoc "Convert a Jekyll Project to a Dragon Project"

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: convert(target)
  def run(optcfg, opts, _), do: syntax(optcfg, "convert {target} — No target specified")

  def convert(target) do
    stdout(["Coming soon: #{@moduledoc}"])
    :ok
  end
end
