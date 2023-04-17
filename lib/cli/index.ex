defmodule Dragon.Cli do
  @opts [
    switches: [],
    aliases: [],
    commands: [
      {"b?uild", Dragon.Cli.Build},
      {"s?erve", Dragon.Cli.Serve},
      {"n?ew", Dragon.Cli.New},
      {"con?vert", Dragon.Cli.Convert}
    ],
    command: "dragon"
  ]

  def main(args) do
    Rivet.Utils.Cli.run_command(args, @opts)
  end
end
