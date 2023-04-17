defmodule Dragon.Template.Helpers do
  alias Dragon.Utils
  use Dragon.Context

  def generate_context(state) do
    [relative_include: fn x, y -> relative_include(x, y, state) end]
  end

  defp relative_include(path, args, %{parent: parent}) do
    root = Dragon.get!(:root)

    path =
      case path do
        "./" <> rest -> rest
        pass -> pass
      end

    path = Path.join(Dragon.Tools.File.drop_root(root, parent) |> Path.dirname(), path)

    include(path, args)
  end

  def include(path, args \\ []) do
    case Dragon.Template.include_file(path, Dragon.get!(), :inline, args) do
      {:error, error} -> abort(error)
      {:ok, _, content} -> content
    end
  end

  def markdownify(markdown) do
    with {:ok, content, _} <- Earmark.as_html(markdown) do
      content
    end
  end

  def path("#" <> _id = fragment), do: fragment

  def path(dest) do
    with {:ok, root} <- Dragon.get(:root) do
      dest_path = Path.join(root, dest)

      case File.regular?(dest_path) do
        true ->
          Path.join("/", Utils.transform_suffix(dest))
          |> String.replace_suffix("/index.html", "/")

        false ->
          {:error, "#{dest_path} is not a file"}
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
end
