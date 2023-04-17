defmodule Dragon.Template.Functions do
  import Dragon.Tools.File, only: [drop_root: 2]
  use Dragon.Context

  def include(path, args \\ []) do
    with {:ok, path} <- fix_relative_path(path) do
      case Dragon.Template.Evaluate.include_file(path, Dragon.get!(), :inline, args) do
        {:error, error} -> abort(error)
        {:ok, _, content} -> content
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
    with {:ok, path} <- fix_relative_path(dest), {:ok, root} <- Dragon.get(:root) do
      localized_path = Path.join(Path.split(Path.join(root, path)))
      case File.regular?(localized_path) do
        # reformat as std URL, no wonky dos things
        true -> "/#{Path.split(path) |> Enum.join("/")}"
        false -> abort("#{path} (#{dest}) is not a file")
      end
    end
  end

  def peek(path) do
    with {:ok, root} <- Dragon.get(:root),
         {:ok, header, _, _} <-
           Dragon.Template.Read.read_template_header(Path.join(root, path)),
         do: Dragon.Process.Data.clean_data(header)
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
