defmodule Dragon.Cli do
  @opts [
    switches: [],
    aliases: [],
    commands: [
      {"b?uild", Dragon.CLI.Build},
      {"s?erve", Dragon.CLI.Serve},
      {"n?ew", Dragon.CLI.New},
      {"con?vert", Dragon.CLI.Convert}
    ],
    command: "dragon"
  ]

  def main(args), do: Rivet.Cli.run_command(args, @opts)
end
