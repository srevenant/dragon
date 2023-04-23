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

    walk_tree(dragon, path,
      match: %{~r/\.(ya?ml|json)$/ => &load_data_file/3},
      follow_meta: true,
      prefix: prefix
    )
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
