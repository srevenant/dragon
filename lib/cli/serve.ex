defmodule Dragon.Cli.Serve do
  @moduledoc "Run a development server for a Dragon Project"

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: serve(target)
  def run(optcfg, opts, _), do: syntax(optcfg, "serve {target} — No target specified")

  def serve(target) do
    stdout(["Coming soon: #{@moduledoc}"])
    :ok
  end
end
