defmodule Dragon.Context do
  defmacro __using__(_) do
    quote location: :keep do
      @config_file "_dragon.yml"
      import Dragon.Tools.IO
    end
  end
end
