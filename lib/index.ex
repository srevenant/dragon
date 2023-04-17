defmodule Dragon do
  use GenServer
  use Dragon.Context

  @always_imports [
    "Dragon.Template.Helpers",
    "Transmogrify",
    "Transmogrify.As"
  ]

  defstruct root: ".",
            build: "_build",
            layouts: "_lib/layout",
            data: nil,
            # layouts: "user/.dragon/layouts",
            # includes: "user/.dragon/includes",
            # copy: [],
            imports: @always_imports,
            files: %{},
            opts: %{},
            state: %{}

  @type t :: %Dragon{
          root: String.t(),
          build: String.t(),
          layouts: String.t(),
          data: list(map) | map() | nil,
          imports: list(String.t()) | String.t(),
          # layouts: String.t(),
          # includes: String.t(),
          # scss: String.t(),
          # plugins: String.t(),
          # copy: list(String.t()),
          files: %{(path :: String.t()) => atom()},
          opts: %{atom() => any()},
          state: map()
        }

  def startup(target), do: GenServer.start_link(__MODULE__, target, name: __MODULE__)

  ##############################################################################
  @spec init(target :: String.t()) :: Dragon.t()
  def init(root) when is_binary(root) do
    case Dragon.Tools.File.find_index_file(root, @config_file) do
      {:ok, path} ->
        case YamlElixir.read_all_from_file(path) do
          {:ok, [%{"version" => 1.0} = config]} ->
            root = Path.dirname(path)

            struct(__MODULE__, Transmogrify.transmogrify(config))
            |> update_paths(root)
            |> update_imports()
            |> Dragon.Process.Data.load_data()

          {:error, %{message: msg}} ->
            abort("Error reading Dragon Config (#{path}): #{msg}")

          err ->
            IO.inspect(err, label: "Error")
            abort("Unable to find valid Dragon config in #{path}")
        end

      {:error, reason} ->
        raise "oops"
        abort("Unable to find target site/config file '#{root}': #{reason}")
    end
  end

  def get(), do: GenServer.call(__MODULE__, :get)
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  def get!() do
    with {:ok, value} <- get(), do: value
  end

  def get!(key) do
    with {:ok, value} <- get(key), do: value
  end

  def update_state(key, value), do: GenServer.call(__MODULE__, {:update_state, key, value})

  ##############################################################################
  # note: Dragon state is immutable after being initialized. It's only a
  # standalone server/process for easy reference when processes lose context

  @doc false
  def handle_call(:get, _, state), do: {:reply, {:ok, state}, state}
  def handle_call({:get, key}, _, state), do: {:reply, {:ok, Map.get(state, key)}, state}

  def handle_call({:update_state, key, value}, _, state),
    do: {:reply, :ok, %Dragon{state: Map.put(state.state, key, value)}}

  ##############################################################################
  defp update_paths(%Dragon{build: build} = d, root),
    do: %Dragon{d | root: root, build: Path.join(root, build)}

  defp update_imports(%Dragon{imports: imports} = d) when is_list(imports) do
    ## todo: Make this a reduce and remove dups
    imports = Enum.map(imports, &"import #{&1}") |> Enum.join(";")

    %Dragon{d | imports: "<% #{imports} %>\n"}
  end
end