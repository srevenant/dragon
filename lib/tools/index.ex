defmodule Dragon.Tools do
  @moduledoc """
  File handling tools.
  """
  use Dragon.Context

  def put_into(dict, [key], value), do: Map.put(dict, key, value)

  def put_into(dict, [key | keys], value) do
    case Map.get(dict, key) do
      nil -> Map.put(dict, key, put_into(%{}, keys, value))
      d when is_map(d) -> Map.replace(dict, key, put_into(d, keys, value))
      _ -> raise ArgumentError
    end
  end

  def seek!(fd, offset) do
    with {:ok, _} <- :file.position(fd, offset), do: fd
  end

  def open_file(path) do
    case File.open(path, [:utf8, :read]) do
      {:ok, fd} ->
        {:ok, fd}

      {:error, :enoent} ->
        abort("Cannot open file '#{path}', cannot continue")

      {:error, :eisdir} ->
        raise "narf"
        abort("Cannot open file '#{path}', it is a folder. Cannot continue")

      err ->
        IO.inspect(err, label: "File open error")
        abort("Cannot open file, cannot continue")
    end
  end

  def with_open_file(path, func) do
    with {:ok, fd} <- open_file(path) do
      try do
        func.(fd)
      after
        :ok = File.close(fd)
      end
    end
  end

  def write_file(dest, content) do
    Dragon.Tools.makedirs_for_file(dest)

    case File.write(dest, content) do
      :ok -> :ok
      {:error, err} -> abort("Cannot write file '#{dest}': #{err}")
    end
  end

  def drop_root(root, path) do
    if String.slice(path, 0..(String.length(root) - 1)) == root do
      String.slice(path, (String.length(root) + 1)..-1)
    else
      path
    end
  end

  def find_index_file(root, index) do
    case {index, File.stat(root)} do
      {index, {:ok, %File.Stat{type: :directory}}} when not is_nil(index) ->
        find_index_file(Path.join(root, index), nil)

      {_, {:ok, %File.Stat{type: :regular}}} ->
        {:ok, root}

      {_, err} ->
        err
    end
  end

  def find_file(root, path) do
    with :error <- find_file_variant(root, Path.split(path)),
         do: {:error, "File not found (#{Path.join(root, path)})"}
  end

  ## TODO: make "directory ok" flag
  def try_variant(root, part, rest, on_error \\ nil) do
    case {valid_part(root, part), rest} do
      {{:directory, _}, []} ->
        :error

      {{:directory, path}, more} ->
        find_file_variant(path, more)

      {{:file, path}, []} ->
        {:ok, path}

      {{:file, _}, _} ->
        :error

      _ ->
        if on_error do
          on_error.()
        else
          :error
        end
    end
  end

  def find_file_variant(root, [part | rest]) do
    try_variant(root, part, rest, fn ->
      case part do
        "_" <> part -> try_variant(root, part, rest)
        part -> try_variant(root, "_" <> part, rest)
      end
    end)
  end

  def find_file_variant(_, []), do: :error

  def valid_part(root, part) do
    path = Path.join(root, part)

    case File.stat(path) do
      {:ok, %{type: :directory}} -> {:directory, path}
      {:ok, %{type: :regular}} -> {:file, path}
      _ -> :error
    end
  end

  def export_fname(fname) do
    if String.at(fname, 0) == "_" do
      String.slice(fname, 1..-1)
    else
      fname
    end
    |> String.downcase()
  end

  def makedirs_for_file(dest) do
    folder = Path.dirname(dest)

    case File.mkdir_p(folder) do
      :ok -> :ok
      err -> abort("Cannot mkdir '#{folder}': #{inspect(err)}")
    end
  end

  ##############################################################################
  defp no_match(dragon, path, _) do
    notify("Ignoring file '#{path}'")
    dragon
  end

  def walk_tree(dragon, path, cfg) when is_list(cfg),
    do:
      walk_tree(
        dragon,
        path,
        Map.merge(%{types: %{}, follow_meta: false, no_match: &no_match/3}, Map.new(cfg))
      )

  def walk_tree(%{root: root} = dragon, path, opts) when is_binary(path) and is_map(opts) do
    fname = Path.basename(path)
    first = String.at(fname, 0)

    cond do
      first == "_" and opts.follow_meta != true ->
        dragon

      ## instead, create an "ignore" pattern configuration/mask
      first == "." ->
        dragon

      true ->
        fullpath = Path.join(root, path)

        case File.stat(fullpath) do
          {:ok, %File.Stat{type: :directory}} ->
            File.ls!(fullpath)
            |> Enum.reduce(dragon, &walk_tree(&2, Path.join(path, &1), opts))

          {:ok, %File.Stat{type: :regular}} ->
            case opts.types[Path.extname(fname)] do
              nil -> opts.no_match.(dragon, fullpath, opts)
              handler -> handler.(dragon, fullpath, opts)
            end

          {:error, reason} ->
            abort("Unable to process file '#{fullpath}': #{reason}")
        end
    end
  end


  @doc """
  Within walk_tree, investigate a file to determin what its type is and store
  accordingly. If it begins with the dragon header, consider it a dragon
  template. Otherwise look at the file extension.
  """
  def scan_file(dragon, path, _args) do
    type =
      with_open_file(path, fn fd ->
        case IO.binread(fd, 10) do
          "--- dragon" ->
            :dragon

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
