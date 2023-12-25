defmodule Dragon.Data.Collection do
  @moduledoc """
  Tools for loading data collections
  """

  use Dragon.Context
  import Dragon.Data, only: [get_into: 2]
  import Dragon.Tools.File, only: [drop_root: 2]
  import Dragon.Tools.Dict

  defstruct src: nil,
            "@spec": nil,
            dst: nil,
            prev: nil,
            next: nil,
            title: nil,
            date: nil,
            date_t: 0,
            date_modified: nil

  @type t :: %__MODULE__{
          src: nil | String.t(),
          "@spec": nil | map(),
          dst: nil | String.t(),
          prev: nil | String.t(),
          next: nil | String.t(),
          title: nil | String.t(),
          date: nil | DateTime.t(),
          date_t: integer(),
          date_modified: DateTime.t()
        }

  def load(%Dragon{root: root} = dragon, %{type: "collection", path: path} = args) do
    only =
      case Map.get(args, :only) do
        nil -> false
        rx -> Regex.compile!(rx)
      end

    fullpath = Path.join(root, path)
    into = get_into(dragon, args)
    last = List.last(into)

    case File.stat(fullpath) do
      {:ok, %{type: :directory}} ->
        stdout([:green, "Indexing collection: ", :reset, :bright, path])
        noroot = drop_root(root, fullpath)

        data = File.ls!(fullpath)

        data =
          if only != false do
            Enum.filter(data, fn f -> Regex.match?(only, f) end)
          else
            data
          end

        data =
          Enum.reduce(data, [], &reduce_collection_files(fullpath, noroot, &1, &2))
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

        into_index = String.to_atom("#{last}_index")

        index = Map.new(data, &{collection_key(&1.src), &1})

        dragon
        |> put_into([:data] ++ into, data)
        |> put_into([:data] ++ [into_index], index)

      _ ->
        abort("Cannot load data collection #{path}")
    end
  end

  ##############################################################################
  def collection_key(name),
    do: Path.basename(name) |> String.replace(~r/[^a-z0-9]+/, "") |> String.to_atom()

  ##############################################################################
  def file_details(path) do
    case Dragon.Template.Read.read_template_header(path) do
      {:error, reason} ->
        abort("Unable to load file header (#{path}): #{reason}")

      {:ok, header, _, _, _} ->
        with {:ok, meta} <- Dragon.Template.Env.get_file_metadata("", path, header, %{}) do
          # Map.take(meta, [:title, :date, :date_t, :date_modified, :"@spec"]))
          struct(__MODULE__, meta)
        end
    end
  end

  ##############################################################################
  defp reduce_collection_files(_, _, "index.html", acc), do: acc
  defp reduce_collection_files(_, _, "_" <> _template, acc), do: acc

  defp reduce_collection_files(full, base, file, acc) do
    target = Path.join(full, file)

    if File.regular?(target) do
      details = file_details(target)

      # there are reasons. Just let it go :)
      localized =
        if Map.get(details, :"@spec")[:output] == "folder/index" do
          "/#{Path.join(base, file) |> Path.rootname()}/"
        else
          # md ... blah
          "/#{Path.join(base, Regex.replace(~r/\.md$/, file, ".html"))}"
        end

      [Map.merge(details, %{src: target, dst: localized}) | acc]
    else
      acc
    end
  end
end
