defmodule Dragon.Data.Collection do
  use Dragon.Context
  import Dragon.Data, only: [get_into: 2]
  import Dragon.Tools.File, only: [drop_root: 2]
  import Dragon.Tools

  def load(%Dragon{root: root} = dragon, %{type: "collection", path: path} = args) do
    fullpath = Path.join(root, path)
    into = get_into(dragon, args)

    case File.stat(fullpath) do
      {:ok, %{type: :directory}} ->
        notify([:green, "Indexing collection: ", :reset, :bright, path])
        noroot = drop_root(root, fullpath)

        data =
          File.ls!(fullpath)
          |> Enum.reduce([], &reduce_collection_files(fullpath, noroot, &1, &2))
          |> Enum.sort_by(& &1.date_t)
          |> Enum.reduce({nil, []}, fn
            elem, {nil, acc} -> {elem, [elem | acc]}
            elem, {prev, acc} -> {elem, [%{elem | prev: prev.file} | acc]}
          end)
          |> then(fn {p, list} -> list end)
          |> Enum.reduce({nil, []}, fn
            elem, {nil, acc} -> {elem, [elem | acc]}
            elem, {prev, acc} -> {elem, [%{elem | next: prev.file} | acc]}
          end)
          |> then(fn {p, list} -> list end)

        put_into(dragon, [:data] ++ into, data)

      _ ->
        abort("Cannot load data collection #{path}")
    end
  end

  ##############################################################################
  def file_details(path) do
    case Dragon.Template.Read.read_template_header(path) do
      {:error, reason} ->
        abort("Unable to load file header (#{path}): #{reason}")

      {:ok, header, _, _} ->
        with {:ok, meta} <- Dragon.Template.Env.get_file_metadata(path, header) do
          # struct? Image data?
          Map.merge(%{prev: nil, next: nil}, Map.take(meta, [:title, :date, :date_t, :date_modified]))
        end
    end
  end

  ##############################################################################
  defp reduce_collection_files(_, _, "index.html", acc), do: acc
  defp reduce_collection_files(full, base, file, acc) do
    target = Path.join(full, file)
    localized = "/#{Path.join(base, file) |> Path.rootname()}/"
    if File.regular?(target) do
      [file_details(target) |> Map.put(:file, localized) | acc]
    else
      acc
    end
  end
end
