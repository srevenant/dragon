defmodule Dragon.Template.Functions do
  @moduledoc """
  Helper functions for Dragon Templates.
  """
  import Dragon.Tools.File, only: [drop_root: 3, find_file: 2]
  use Dragon.Context

  def include(path, args \\ []) do
    with {:ok, path, _} <- fix_path(path) do
      case Dragon.Template.Evaluate.include_file(path, Dragon.get!(), :inline, args) do
        {:error, error} -> abort(error)
        {:ok, _, _, content} -> content
      end
    end
  end

  def markdownify(content) do
    with {:ok, content, _} <- Earmark.as_html(content) do
      content
    end
  end

  def jsonify(content), do: Jason.encode!(content)

  def path("#" <> _id = fragment), do: fragment

  def path(dest) do
    with {:ok, path, root} <- fix_path(dest),
         {:ok, build} <- Dragon.get(:build) do
      build_target =
        (Path.split(build) ++ (drop_root(root, path, absolute: false) |> Path.split()))
        |> Path.join()

      ## TODO: create a post-process work queue of lambdas, and put this check there
      if not File.regular?(build_target) do
        warn("<path check> #{path} (#{build_target}) is not a file")
      end

      "/#{Path.split(path) |> Enum.join("/")}" |> one_slash()
    end
  end

  # todo: move to Transmogrify
  def as_key(key) when is_binary(key), do: Transmogrify.snakecase(key) |> String.to_atom()
  def as_key(key) when is_atom(key), do: key

  defp one_slash(str), do: Regex.replace(~r|//+|, str, "/")

  def peek(path) do
    with {:ok, path, root} <- fix_path(path),
         {:ok, path} <- find_file(root, path),
         {:ok, header, _, _, _} <- Dragon.Template.Read.read_template_header(path),
         do: Dragon.Data.clean_data(header)
  end

  def date(d, fmt) do
    with {:ok, date} <- Calendar.strftime(d, fmt) do
      date
    end
  end

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
end
