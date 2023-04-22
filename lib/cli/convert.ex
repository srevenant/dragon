defmodule Dragon.Cli.Convert do
  @moduledoc false

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: convert(target)
  def run(optcfg, _opts, _), do: syntax(optcfg, "convert {target} — No target specified")

  @doc "Convert a Jekyll Project to a Dragon Project"
  def convert(_target) do
    stdout(["Coming soon: #{@doc}"])
    :ok
  end
end
