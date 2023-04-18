defmodule Dragon.Template.Functions do
  import Dragon.Tools.File, only: [drop_root: 2, find_file: 2]
  use Dragon.Context

  def include(path, args \\ []) do
    with {:ok, path} <- fix_relative_path(path) do
      case Dragon.Template.Evaluate.include_file(path, Dragon.get!(), :inline, args) do
        {:error, error} -> abort(error)
        {:ok, _, _, content} -> content
      end
    end
  end

  def markdownify(markdown) do
    with {:ok, content, _} <- Earmark.as_html(markdown) do
      content
    end
  end

  def path("#" <> _id = fragment), do: fragment

  def path(dest) do
    with {:ok, path} <- fix_relative_path(dest),
         {:ok, root} <- Dragon.get(:root),
         {:ok, build} <- Dragon.get(:build) do
      build_target = (Path.split(build) ++ (drop_root(root, path) |> Path.split())) |> Path.join()

      ## TODO: create a post-process work queue of lambdas, and put this check there
      if not File.regular?(build_target) do
        warn("<path check> #{path} (#{build_target}) is not a file")
      end

      "/#{Path.split(path) |> Enum.join("/")}" |> one_slash()
    end
  end

  defp one_slash(str), do: Regex.replace(~r|//+|, str, "/")

  def peek(path) do
    with {:ok, root} <- Dragon.get(:root),
         {:ok, path} <- fix_relative_path(drop_root(root, path)),
         {:ok, path} <- find_file(root, path),
         {:ok, header, _, _} <-
           Dragon.Template.Read.read_template_header(path),
         do: Dragon.Data.clean_data(header)
  end

  def say(content) do
    IO.inspect(content, label: "SAY")
  end

  defp fix_relative_path("./" <> path) do
    with %{this: parent} <- Dragon.frame_head(), {:ok, root} <- Dragon.get(:root) do
      {:ok, drop_root(root, parent) |> Path.dirname() |> Path.join(path)}
    end
  end

  defp fix_relative_path(path), do: {:ok, path}
end
