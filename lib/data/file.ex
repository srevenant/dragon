defmodule Dragon.Data.File do
  @moduledoc """
  Tools for loading data files (yml)
  """
  use Dragon.Context
  import Dragon.Tools.File.WalkTree
  import Dragon.Tools.Dict
  import Dragon.Data, only: [get_into: 2, data_path: 2]

  # def load(dragon, args, rest, forward) do
  def load(%Dragon{} = dragon, %{type: "file", path: path} = args) do
    stdout([:green, "Loading data", :reset, " from ", :bright, path])
    prefix = get_into(dragon, args)

    %Dragon{dragon | data_paths: Map.put(dragon.data_paths, Path.join(dragon.root, path), [])}
    |> walk_tree(path,
      match: %{~r/\.(ya?ml|json)$/ => &load_data_file/3},
      follow_meta: true,
      prefix: prefix
    )
  end

  ##############################################################################
  def load_data_file(dragon, path, opts) do
    # strip off the first parts of the name... meh?
    datapath =
      case {Map.get(opts, :prefix), data_path(dragon.root, path)} do
        {nil, [_ | path]} -> path
        {prefix, path} when is_list(prefix) -> prefix ++ path
      end

    stdout([
      :green,
      "Loading ",
      :reset,
      :bright,
      path,
      :reset,
      :light_black,
      " into data path: ",
      :light_blue,
      "@",
      Enum.join(datapath, ".")
    ])

    case Path.extname(path) do
      ".json" -> File.read!(path) |> Jason.decode()
      ".yml" -> YamlElixir.read_all_from_file(path)
      ".yaml" -> YamlElixir.read_all_from_file(path)
    end
    |> case do
      # single map
      {:ok, [data]} ->
        put_into(dragon, [:data | datapath], data)

      # its a list not a map
      {:ok, [_ | _] = list} ->
        put_into(dragon, [:data | datapath], list)

      {:ok, data} when is_map(data) ->
        put_into(dragon, [:data | datapath], data)

      error ->
        IO.inspect(error, label: "Error parsing Data")
        abort("Cannot continue")
    end
  end
end
