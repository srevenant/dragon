defmodule Dragon.Process.Data do
  use Dragon.Context
  import Dragon.Tools.File
  import Dragon.Tools

  def clean_data(data),
    do: Transmogrify.transmogrify(data, key_convert: :atom, deep: true, key_case: :snake)

  ##############################################################################
  def load_data(%Dragon{data: data} = dragon) when is_list(data),
    do: load_data(%Dragon{dragon | data: %{}}, data)

  def load_data(x) do
    IO.inspect(x, label: "Load data error")
    abort("Unexpected error: invalid data config?")
  end

  def get_into(dragon, %{into: into}), do: data_path(dragon.root, into)
  def get_into(_, _), do: nil

  ##############################################################################
  def data_path(root, path) do
    Dragon.Tools.File.drop_root(root, path)
    |> Path.rootname()
    |> Path.split()
    |> Enum.reduce([], &(&2 ++ String.split(Dragon.Tools.File.export_fname(&1), ".")))
    |> Transmogrify.transmogrify(%{value_convert: :atom, value_case: :snake})
  end

  ##############################################################################
  def load_data(%Dragon{} = dragon, [%{type: "file", path: path} = args | rest]) do
    notify([:green, "Loading data", :reset, " from ", :bright, path])
    prefix = get_into(dragon, args)

    walk_tree(dragon, path,
      types: %{".yml" => &load_data_file/3, ".yaml" => &load_data_file/3},
      follow_meta: true,
      prefix: prefix
    )
    |> case do
      %Dragon{} = dragon -> load_data(dragon, rest)
      {:error, msg} -> abort(msg)
    end
  end

  def load_data(%Dragon{root: root} = dragon, [%{type: "collection", path: path} = args | rest]) do
    fullpath = Path.join(root, path)
    into = get_into(dragon, args)

    case File.stat(fullpath) do
      {:ok, %{type: :directory}} ->
        notify([:green, "Indexing collection: ", :reset, :bright, path])

        data =
          File.ls!(fullpath)
          |> Enum.reduce([], fn file, acc ->
            target = Path.join(fullpath, file)
            [file_details(target) |> Map.put(:file, target) | acc]
          end)
          |> Enum.sort_by(& &1.date_t)

        # todo:
        #   - enrich filename to target
        #   - add prev/next
        #

        put_into(dragon, [:data] ++ into, data)
        |> load_data(rest)

      _ ->
        abort("Cannot load data collection #{path}")
    end
  end

  def load_data(%Dragon{} = dragon, []),
    do: {:ok, %Dragon{dragon | data: Transmogrify.transmogrify(dragon.data)}}

  def load_data(%Dragon{}, [nope | _]) do
    IO.inspect(nope, label: "Invalid config data specification")
    abort("Cannot continue")
  end

  ##############################################################################
  def file_details(path) do
    case Dragon.Template.Read.read_template_header(path) do
      {:error, reason} ->
        abort("Unable to load file header (#{path}): #{reason}")

      {:ok, header, _, _} ->
        with {:ok, meta} <- Dragon.Template.Env.get_file_metadata(path, header) do
          # image data?
          Map.take(meta, [:title, :date, :date_t, :date_modified])
        end
    end
  end

  ##############################################################################
  def load_data_file(dragon, path, opts) do
    # strip off the first parts of the name... meh?
    datapath =
      case {Map.get(opts, :prefix), data_path(dragon.root, path)} do
        {nil, [_ | path]} -> path
        {prefix, path} when is_list(prefix) -> prefix ++ path
      end

    notify([
      :green,
      "Loading ",
      :reset,
      :bright,
      path,
      :reset,
      :light_black,
      " into data path: ",
      :light_blue,
      Enum.join(datapath, ".")
    ])

    case YamlElixir.read_all_from_file(path) do
      # single map
      {:ok, [data]} ->
        put_into(dragon, [:data | datapath], data)

      # its a list not a map
      {:ok, [_ | _] = list} ->
        put_into(dragon, [:data | datapath], list)

      error ->
        IO.inspect(error, label: "Error parsing YAML")
        abort("Cannot continue")
    end
  end
end
