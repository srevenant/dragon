defmodule Mix.Tasks.Dragon.Serve do
  @moduledoc false
  @shortdoc "Run a development server for a Dragon Project"
  import Rivet.Utils.Cli.Print
  import Rivet.Utils.Cli
  use Mix.Task
  @default_port 4040

  # if only we had a decent argparser... (python's is decent)
  @opts [
    switches: [watch: [:keep, :string], port: [:integer]],
    aliases: [w: :watch, p: :port],
    commands: [],
    command: "dragon"
  ]

  @impl true
  def run(args) do
    case parse_options(args, @opts) do
      {opts, [target], []} ->
        watch = Enum.reduce(opts, [], fn {:watch, path}, acc -> [path | acc] end)
        Dragon.Serve.start(target, Map.new(opts) |> Map.put(:watch, watch))

      {_, _, errs} ->
        syntax(
          "Invalid option(s): #{Enum.map(errs, fn {x, y} -> "#{x}=#{y}" end) |> Enum.join(" ")}"
        )
    end
  end

  defp syntax(msg \\ ""),
    do:
      die(
        ["Syntax: mix dragon.serve {target} [--port=port] [--watch=file,folder,...]\n"] ++
          if(msg, do: ["\n#{msg}\n"], else: [])
      )
end
