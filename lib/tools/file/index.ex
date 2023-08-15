defmodule Dragon.Tools.File do
  @moduledoc """
  File handling tools.
  """
  use Dragon.Context
  import Dragon.Tools.Dict

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
    Dragon.Tools.File.makedirs_for_file(dest)

    case File.write(dest, content) do
      :ok -> :ok
      {:error, err} -> abort("Cannot write file '#{dest}': #{err}")
    end
  end

  def drop_root(x, y, z \\ [absolute: false])
  def drop_root("", path, _), do: path

  def drop_root(root, path, opts) do
    if String.slice(path, 0..(String.length(root) - 1)) == root do
      start = String.length(root)
      start = if opts[:absolute], do: start, else: start + 1
      String.slice(path, start..-1)
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
  @doc """
  Within walk_tree, investigate a file to determine what its type is and store
  accordingly. If it begins with the dragon header, consider it a dragon
  template. Otherwise look at the file extension.
  """
  def scan_file(dragon, path, _) do
    with {:ok, type, rel_path} <- file_type(dragon.root, path) do
      put_into(dragon, [:files, type, rel_path], [])
    end
  end

  def file_type(root, path) do
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

    {:ok, type, drop_root(root, path)}
  end

  # need an os-agnostic way to do this
  def get_true_path(path) do
    with {p, 0} <- System.cmd("sh", ["-c", "cd #{path} && /bin/pwd -P"]),
         do: {:ok, String.trim(p)}
  end
end
