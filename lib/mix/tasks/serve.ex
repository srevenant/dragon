defmodule Mix.Tasks.Dragon.Serve do
  @moduledoc false
  @shortdoc "Run a development server for a Dragon Project"
  import Rivet.Utils.Cli.Print
  import Rivet.Utils.Cli
  use Mix.Task

  # if only we had a decent argparser... (python's is decent)
  @opts [
    switches: [watch: [:keep, :string], port: [:integer]],
    aliases: [w: :watch, p: :port],
    commands: [],
    command: "dragon"
  ]

  defp invalid_errs(out, []), do: out

  defp invalid_errs(out, opts),
    do: [
      "Invalid option(s): " <> (Enum.map(opts, fn {x, y} -> "#{x}=#{y}" end) |> Enum.join(" "))
      | out
    ]

  defp invalid_args(out, []), do: out

  defp invalid_args(out, args),
    do: ["Invalid arguments (only one target allowed): " <> Enum.join(args, " ") | out]

  @impl true
  def run(args) do
    case parse_options(args, @opts) do
      {opts, [target], []} ->
        watch = Enum.reduce(opts, [], fn {:watch, path}, acc -> [path | acc] end)
        Dragon.Serve.start(target, Map.new(opts) |> Map.put(:watch, watch))

      {_, args, errs} ->
        invalid_errs([], errs) |> invalid_args(args) |> syntax()
    end
  end

  @dialyzer {:nowarn_function, [syntax: 1]}
  defp syntax(msg),
    do:
      die(
        ["Syntax: mix dragon.serve {target} [--port=port] [--watch=file,folder,...]\n"] ++
          if(msg, do: ["\n#{msg}\n"], else: [])
      )
end
