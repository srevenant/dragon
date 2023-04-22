defmodule Dragon.Cli.Serve do
  @moduledoc false

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: serve(target)
  def run(optcfg, _opts, _), do: syntax(optcfg, "serve {target} — No target specified")

  @doc "Run a development server for a Dragon Project"
  def serve(_target) do
    stdout(["Coming soon: #{@doc}"])
    :ok
  end
end
