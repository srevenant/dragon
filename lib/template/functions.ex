defmodule Dragon.Template.Functions do
  @moduledoc """
  Helper functions for Dragon Templates.
  """
  import Dragon.Tools.File, only: [drop_root: 3, find_file: 2]
  use Dragon.Context
  import Rivet.Utils.Cli.Print
  import Dragon.Template.Evaluate, only: [evaluate_template: 4]

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

  # Note: eex doesn't run plugins, by design, because plugins can run this
  def eex(content) do
    with {:ok, d} <- Dragon.get(),
         {:ok, output} <- evaluate_template(d, "evaleex", content, d.data),
         do: String.trim(output)
  end

  ##############################################################################
  @doc """
  TODO FOR path and canonical_path:

  * figure out how to handle markdown suffix conversion intelligently
  * peek into target file and see if it has layout/folder in @spec and
    drop index.html respectively
  """
  def canonical_path() do
    with {:ok, root} <- Dragon.get(:root),
         %{origin: origin} = head <- Dragon.frame_head() do
      path = drop_root(root, origin, absolute: true)

      path =
        if String.ends_with?(path, ".md"), do: String.slice(path, 0..-4) <> ".html", else: path

      if String.ends_with?(path, "index.html") do
        String.slice(path, 0..-11) <> "/"
      else
        path
      end
      |> file_is_folder(head)
    end
    |> one_slash()
  end

  defp file_is_folder(path, %{page: %{"@spec": %{output: "folder/index"}}}) do
    if String.ends_with?(path, ".html") do
      String.slice(path, 0..-6) <> "/"
    else
      path
    end
  end

  defp file_is_folder(path, _head), do: path

  ##############################################################################
  def is_url(path), do: Regex.match?(~r/^([a-z]+):\/\//, path)

  def path("#" <> _id = fragment), do: fragment

  def path(dest) do
    # don't change URLs, only paths
    if is_url(dest) do
      dest
    else
      with {:ok, path, root} <- fix_path(dest),
           {:ok, build} <- Dragon.get(:build) do
        build_target =
          (Path.split(build) ++ (drop_root(root, path, absolute: false) |> Path.split()))
          |> Path.join()

        ## TODO: create a post-process work queue of lambdas, and put this check there
        if not path_exists?(build_target),
          do: warn("<path check> #{path} (#{build_target}) is not valid")

        path = "/#{Path.split(path) |> Enum.join("/")}" |> one_slash()

        case Path.extname(path) do
          "" -> path <> "/"
          _ -> path
        end
      end
    end
  end

  def canonical_url(url, dest) do
    if is_url(dest),
      do: dest,
      else: url <> dest
  end

  # try directories and files; not very precise, but :shrug:
  defp path_exists?(target),
    do: exists_as_file?(target) or exists_as_indexed_folder?(target) or exists_as_folder?(target)

  defp exists_as_file?(target), do: File.exists?(target)

  defp exists_as_indexed_folder?(target),
    do: String.ends_with?(target, "index.html") and File.dir?(String.slice(target, 0..-11))

  # technically we should peek into the file's headers to see if it has folder/index, but for now just guess
  defp exists_as_folder?(target),
    do: String.ends_with?(target, ".html") and File.dir?(String.slice(target, 0..-6))

  defp one_slash(str), do: Regex.replace(~r|//+|, str, "/")

  ##############################################################################
  def get_header(path) do
    with {:ok, path, root} <- fix_path(path),
         {:ok, path} <- find_file(root, path),
         {:ok, header, _, _, _} <- Dragon.Template.Read.read_template_header(path),
         do: Dragon.Data.clean_data(header)
  end

  ##############################################################################
  def get_data(path, opts \\ []) do
    with {:ok, path, _root} <- fix_path(path),
         {:ok, dragon} <- Dragon.get(),
         %Dragon{} = d <-
           Dragon.Data.File.load(%Dragon{dragon | data: %{}}, %{type: "file", path: path}) do
      data = Transmogrify.transmogrify(d.data)

      if opts[:pop] do
        Enum.reduce_while(1..opts[:pop], data, fn _, data ->
          case Map.keys(data) do
            [key] -> {:cont, data[key]}
            _ -> {:halt, data}
          end
        end)
      else
        data
      end
    end
  end

  def get_with_key(a, b) do
    case Map.get(a, Transmogrify.As.as_key(b)) do
      nil -> raise Dragon.AbortError, "Key '#{b}' not found in: #{inspect(a)}"
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
  # note: Calendar.strftime %z doesn't work for ISO time, because %z returns
  # [+-]HHMM, and ISO time wants [+-]HH:MM. Unfortunately Calendar.strftime
  # has no option for the latter, and looks to be a dead projects, with stale
  # PRs untouched for years.
  # this assumes your times are always coming in as UTC, which may not be true.
  @isotime "%Y-%m-%dT%H:%M:%SZ"
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
