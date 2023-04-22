defmodule Dragon.Data.Collection do
  @moduledoc """
  Tools for loading data collections
  """

  use Dragon.Context
  import Dragon.Data, only: [get_into: 2]
  import Dragon.Tools, only: [drop_root: 2]
  import Dragon.Tools

  defstruct src: nil,
            dst: nil,
            prev: nil,
            next: nil,
            title: nil,
            date: nil,
            date_t: 0,
            date_modified: nil

  @type t :: %__MODULE__{
          src: nil | String.t(),
          dst: nil | String.t(),
          prev: nil | String.t(),
          next: nil | String.t(),
          title: nil | String.t(),
          date: nil | DateTime.t(),
          date_t: integer(),
          date_modified: DateTime.t()
        }

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
            elem, {prev, acc} -> {elem, [%{elem | prev: prev.dst} | acc]}
          end)
          |> then(fn {_, list} -> list end)
          |> Enum.reduce({nil, []}, fn
            elem, {nil, acc} -> {elem, [elem | acc]}
            elem, {prev, acc} -> {elem, [%{elem | next: prev.dst} | acc]}
          end)
          |> then(fn {_, list} -> list end)
          |> Enum.reverse()

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
          struct(__MODULE__, Map.take(meta, [:title, :date, :date_t, :date_modified]))
        end
    end
  end

  ##############################################################################
  defp reduce_collection_files(_, _, "index.html", acc), do: acc

  defp reduce_collection_files(full, base, file, acc) do
    target = Path.join(full, file)
    localized = "/#{Path.join(base, file) |> Path.rootname()}"

    if File.regular?(target) do
      [file_details(target) |> Map.merge(%{src: target, dst: localized}) | acc]
    else
      acc
    end
  end
end
