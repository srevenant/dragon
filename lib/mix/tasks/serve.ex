defmodule Mix.Tasks.Dragon.Serve do
  @moduledoc false
  @shortdoc "Run a development server for a Dragon Project"
  import Rivet.Utils.Cli.Print
  use Mix.Task
  @default_port 4040

  @impl true
  def run([target, port]) do
    case Rivet.Utils.Types.as_int(port) do
      {:ok, port} -> Dragon.Serve.start(target, port: port)
      {:error, why} -> syntax(why)
    end
  end

  def run([target]), do: Dragon.Serve.start(target, port: @default_port)
  def run(_), do: syntax()

  defp syntax(msg \\ ""),
    do:
      die(["Syntax: mix dragon.serve {target} [port]\n"] ++ if(msg, do: ["\n#{msg}\n"], else: []))
end
