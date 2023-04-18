defmodule Dragon.Cli.Serve do
  @moduledoc "Run a development server for a Dragon Project"

  import Rivet.Utils.Cli
  import Rivet.Utils.Cli.Print

  def run(_optcfg, _opts, [target]), do: serve(target)
  def run(optcfg, _opts, _), do: syntax(optcfg, "serve {target} — No target specified")

  def serve(_target) do
    stdout(["Coming soon: #{@moduledoc}"])
    :ok
  end
end
