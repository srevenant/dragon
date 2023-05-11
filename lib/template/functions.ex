defmodule Dragon.Template.Functions do
  @moduledoc """
  Helper functions for Dragon Templates.
  """
  import Dragon.Tools.File, only: [drop_root: 3, find_file: 2]
  use Dragon.Context

  ##############################################################################
  def include(path, args \\ []) do
    with {:ok, path, _} <- fix_path(path) do
      case Dragon.Template.Evaluate.include_file(path, Dragon.get!(), :inline, args) do
        {:error, error} -> abort(error)
        {:ok, _, _, content} -> content
      end
    end
  end

  ##############################################################################
  def markdownify(nil), do: ""
  def markdownify(x) when is_number(x), do: x

  def markdownify(content) do
    case Earmark.as_html(content) do
      {:ok, content, _} -> content
      {:error, msg, deets} -> raise Dragon.AbortError, "markdownify: #{msg}; #{inspect(deets)}"
    end
  end

  ##############################################################################
  def jsonify(content), do: Jason.encode!(content)

  ##############################################################################
  def canonical_path() do
    with {:ok, root} <- Dragon.get(:root),
         %{origin: origin} <- Dragon.frame_head() do
      path = drop_root(root, origin, absolute: true)
      if String.ends_with?(path, "index.html") do
        String.slice(path, 0..-11) <> "/"
      else
        path
      end
    end
  end

  ##############################################################################
  def path("#" <> _id = fragment), do: fragment

  def path(dest) do
    with {:ok, path, root} <- fix_path(dest),
         {:ok, build} <- Dragon.get(:build) do
      build_target =
        (Path.split(build) ++ (drop_root(root, path, absolute: false) |> Path.split()))
        |> Path.join()

      ## TODO: create a post-process work queue of lambdas, and put this check there
      if not File.exists?(build_target) do
        warn("<path check> #{path} (#{build_target}) is not valid")
      end

      path = "/#{Path.split(path) |> Enum.join("/")}" |> one_slash()

      case Path.extname(path) do
        "" -> path <> "/"
        _ -> path
      end
    end
  end

  defp one_slash(str), do: Regex.replace(~r|//+|, str, "/")

  ##############################################################################
  def get_header(path) do
    with {:ok, path, root} <- fix_path(path),
         {:ok, path} <- find_file(root, path),
         {:ok, header, _, _, _} <- Dragon.Template.Read.read_template_header(path),
         do: Dragon.Data.clean_data(header)
  end

  ##############################################################################
  def get_data(path) do
    with {:ok, path, _root} <- fix_path(path),
         # future: update find_file so it can optionally handle folders, and add it
         {:ok, dragon} <- Dragon.get(),
         %Dragon{} = d <-
           Dragon.Data.File.load(%Dragon{dragon | data: %{}}, %{type: "file", path: path}) do
      Transmogrify.transmogrify(d.data)
    end
  end

  def get_with_key(a, b) do
    case Map.get(a, Transmogrify.As.as_key(b)) do
      nil -> raise Dragon.AbortError, "Key '#{b}' not found"
      result -> result
    end
  end

  ##############################################################################
  # move to Tools.File
  defp fix_path(path) do
    path = Path.join(Path.split(path))

    with {:ok, root} <- Dragon.get(:root),
         {:ok, p} <- drop_root(root, path, absolute: true) |> fix_relative_path(root) do
      {:ok, p, root}
    end
  end

  defp fix_relative_path("/" <> path, _), do: {:ok, path}

  defp fix_relative_path(path, root) do
    with %{this: parent} <- Dragon.frame_head() do
      {:ok, drop_root(root, parent, absolute: false) |> Path.dirname() |> Path.join(path)}
    end
  end

  ##############################################################################
  @isotime "%Y-%m-%dT%H:%M:%S.%f%z"
  def date(d, fmt \\ @isotime)

  def date(d, fmt) when is_binary(d) do
    case DateTime.from_iso8601(d) do
      {:ok, d, _} ->
        date(d, fmt)

      {:error, what} ->
        raise Dragon.AbortError, message: "Unrecognized date string (not ISO 8601) #{d}: #{what}"
    end
  end

  def date(d, fmt) do
    with {:ok, date} <- Calendar.strftime(d, fmt) do
      date
    end
  end

  ##############################################################################
  def datefrom(f, fmt \\ @isotime)

  def datefrom(file, fmt) when is_binary(file), do: datefrom([file], fmt)

  def datefrom(files, fmt) when is_list(files) do
    files
    |> Enum.map(fn p ->
      with {:ok, path, root} <- fix_path(p),
           {:ok, stat} <- File.stat(Path.join(root, path), time: :posix) do
        stat.mtime
      else
        {:error, :enoent} ->
          raise Dragon.AbortError, message: "File not found: #{p}"

        {:error, err} ->
          raise Dragon.AbortError, message: to_string(err)
      end
    end)
    |> Enum.max()
    |> DateTime.from_unix!(:second)
    |> date(fmt)
  end
end
