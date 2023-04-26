defmodule Dragon.Context do
  @moduledoc false
  defmacro __using__(_) do
    quote location: :keep do
      @config_file "_dragon.yml"
      import Rivet.Utils.Cli.Print
      import Dragon.Abort
    end
  end
end
