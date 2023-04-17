defmodule Dragon.Process.Prepare do
  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Tools

  ##############################################################################
  def prepare_build(%Dragon{} = dragon) do
    notify([:green, "Creating build folder: ", :reset, :bright, dragon.build])

    case File.mkdir_p(dragon.build) do
      {:error, reason} ->
        abort("Unable to make build folder '#{dragon.build}': #{reason}")

      :ok ->
        nil
    end

    with %Dragon{} = dragon <- walk_tree(dragon, "", no_match: &scan_file/3),
         do: Dragon.Process.Synchronize.synchronize(dragon)
  end

  def scan_file(dragon, path, _args) do
    type =
      with_open_file(path, fn fd ->
        case IO.binread(fd, 10) do
          "--- dragon" -> :dragon
          _ ->
            case Path.extname(path) do
              ".scss" -> :scss
              _ -> :file
            end
        end
      end)

    [_ | rel_path] = Path.split(path)
    rel_path = Path.join(rel_path)

    put_into(dragon, [:files, type, rel_path], [])
  end
end
