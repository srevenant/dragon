defmodule Dragon do
  @moduledoc """
  Dragon is meant to be run standalone. See [README](https://github.com/srevenant/dragon) in root of project for full
  details on how it works.
  """
  use GenServer
  use Dragon.Context
  import Dragon.Tools.File.WalkTree
  import Dragon.Tools.File, only: [scan_file: 3]

  @always_imports [
    "Dragon.Template.Functions",
    "Dragon.English",
    "Transmogrify",
    "Transmogrify.As"
  ]

  @always_plugins [
    %{when: "posteval", module: "Dragon.Plugin.Markdown"}
  ]

  defstruct root: ".",
            build: "_build",
            layouts: "_lib/layout",
            data_paths: %{},
            data: nil,
            imports: @always_imports,
            plugins: @always_plugins,
            files: %{},
            opts: %{},
            # execution frames
            frames: []

  @type t :: %Dragon{
          root: String.t(),
          build: String.t(),
          layouts: String.t(),
          data_paths: map(),
          data: list(map) | map() | nil,
          imports: list(String.t()) | String.t(),
          plugins: list(map()) | map(),
          files: %{(path :: String.t()) => atom()},
          opts: %{atom() => any()},
          frames: list()
        }

  def start_link(init), do: GenServer.start_link(__MODULE__, init, name: __MODULE__)

  ##############################################################################
  # @spec init(target :: String.t()) :: Dragon.t()
  def init(args) do
    stdout([:light_blue, :bright, "Starting Dragon CMS"])
    {:ok, struct(__MODULE__, args)}
  end

  ##############################################################################
  def configure(root) when is_binary(root),
    do: GenServer.call(__MODULE__, {:configure, root})

  def get(), do: GenServer.call(__MODULE__, :get)
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  def get!() do
    with {:ok, value} <- get(), do: value
  end

  def get!(key) do
    with {:ok, value} <- get(key), do: value
  end

  # frame / execution stack management
  def frame_push(value), do: GenServer.call(__MODULE__, {:frame_push, value})
  def frame_pop(), do: GenServer.call(__MODULE__, :frame_pop)
  def frame_head(), do: GenServer.call(__MODULE__, :frame_head)

  ##############################################################################
  # note: Dragon state is immutable after being initialized. It's only a
  # standalone server/process for easy reference when processes lose context

  @doc false
  def handle_call({:configure, root}, _, state) do
    Application.put_env(:dragon, :from, root)

    case Dragon.Tools.File.find_index_file(root, @config_file) do
      {:ok, path} ->
        case YamlElixir.read_all_from_file(path) do
          {:ok, [%{"version" => 1.0} = config]} ->
            root = Path.dirname(path)

            dragon =
              struct(__MODULE__, Transmogrify.transmogrify(config))
              |> update_paths(root)
              |> update_imports()
              |> update_plugins()

            try do
              Dragon.Data.load_data(dragon)
            rescue
              error in Dragon.AbortError ->
                {:error, error.message}
            end
            |> case do
              {:error, msg} -> {:reply, {:error, msg}, state}
              {:ok, %Dragon{} = dragon} -> {:reply, {:ok, dragon}, dragon}
            end

          {:error, %{message: msg}} ->
            {:reply, {:error, "Error reading Dragon Config (#{path}): #{msg}"}, state}

          err ->
            IO.inspect(err, label: "Error")
            {:reply, {:error, "Unable to find valid Dragon config in #{path}"}, state}
        end

      {:error, reason} ->
        {:reply, {:error, "Unable to find target site/config file '#{root}': #{reason}"}, state}
    end
  end

  def handle_call(:get, _, state), do: {:reply, {:ok, state}, state}
  def handle_call({:get, key}, _, state), do: {:reply, {:ok, Map.get(state, key)}, state}

  # keep it in the dragon struct, but if this gets too big we can move it to
  # a separate process
  def handle_call({:frame_push, value}, _, state),
    do: {:reply, value, %Dragon{state | frames: [value | state.frames]}}

  def handle_call(:frame_pop, _, state) do
    {:reply, :ok,
     %Dragon{
       state
       | frames:
           case state.frames do
             [] -> []
             [_ | frames] -> frames
           end
     }}
  end

  def handle_call(:frame_head, _, %{frames: [head | _]} = state),
    do: {:reply, head, state}

  def handle_call(:frame_head, _, %{frames: []} = state),
    do: {:reply, nil, state}

  ##############################################################################
  defp update_paths(%Dragon{build: build} = d, root),
    do: %Dragon{d | root: root, build: Path.join(root, build)}

  defp update_imports(%Dragon{imports: imports} = d) when is_list(imports) do
    imports =
      MapSet.new(@always_imports ++ imports)
      |> MapSet.to_list()
      |> Enum.map(&"import #{&1}")
      |> Enum.join(";")

    %Dragon{d | imports: "<% #{imports} %>"}
  end

  defp update_plugins(%Dragon{plugins: plugs} = d) when is_list(plugs),
    do: %Dragon{d | plugins: prepare_plugins(plugs, %{posteval: []})}

  defp prepare_plugins(
         [%{when: "posteval", module: name} | rest],
         %{posteval: list} = plugs
       ) do
    # TODO: check plugin module exists; put into struct
    prepare_plugins(rest, %{plugs | posteval: [String.to_atom("Elixir.#{name}") | list]})
  end

  defp prepare_plugins([nope | _], _) do
    error("Invalid plugin detected")
    IO.inspect(nope, label: "PLUGIN")
    abort("Cannot continue")
  end

  defp prepare_plugins([], out), do: Map.new(out, fn {k, v} -> {k, Enum.reverse(v)} end)

  ##############################################################################
  def prepare_build(%Dragon{} = dragon) do
    stdout([:green, "Creating build folder: ", :reset, :bright, dragon.build])

    case File.mkdir_p(dragon.build) do
      {:error, reason} ->
        abort("Unable to make build folder '#{dragon.build}': #{reason}")

      :ok ->
        nil
    end

    with %Dragon{} = dragon <- walk_tree(dragon, "", no_match: &scan_file/3),
         do: Dragon.Tools.File.Synchronize.synchronize(dragon)
  end
end
